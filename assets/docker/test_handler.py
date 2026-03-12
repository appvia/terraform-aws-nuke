import sys
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

# Allow tests to run even when boto3 is not installed locally.
sys.modules.setdefault("boto3", MagicMock())

import handler


class TestLambdaHandler(unittest.TestCase):
    def _base_event(self):
        return {
            "dry_run": True,
            "secret_name": "/lz/services/nuke/weekly-nuke",
            "sns_topic": None,
            "task_name": "weekly-nuke",
        }

    @patch("handler.subprocess.run")
    @patch("handler.boto3.client")
    def test_success_dry_run_returns_success(
        self, mock_boto3_client, mock_subprocess_run
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        mock_subprocess_run.return_value = SimpleNamespace(
            stdout="would remove ec2-instance",
            stderr="",
            returncode=0,
        )

        result = handler.lambda_handler(self._base_event(), None)

        self.assertEqual(
            result,
            {
                "action": "lambda_handler",
                "task_name": "weekly-nuke",
                "dry_run": True,
                "status": "success",
            },
        )
        secrets_client.get_secret_value.assert_called_once_with(
            SecretId="/lz/services/nuke/weekly-nuke"
        )
        called_cmd = mock_subprocess_run.call_args.args[0]
        self.assertIn("/usr/local/bin/aws-nuke", called_cmd)
        self.assertNotIn("--no-dry-run", called_cmd)

    @patch("handler.subprocess.run")
    @patch("handler.boto3.client")
    def test_non_dry_run_adds_no_dry_run_flag(
        self, mock_boto3_client, mock_subprocess_run
    ):
        event = self._base_event()
        event["dry_run"] = False

        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        mock_subprocess_run.return_value = SimpleNamespace(
            stdout="", stderr="", returncode=0
        )

        result = handler.lambda_handler(event, None)

        self.assertEqual(result["dry_run"], False)
        called_cmd = mock_subprocess_run.call_args.args[0]
        self.assertIn("--no-dry-run", called_cmd)

    @patch("handler.subprocess.run")
    @patch("handler.boto3.client")
    def test_sns_publish_happens_when_would_remove_lines_exist(
        self, mock_boto3_client, mock_subprocess_run
    ):
        event = self._base_event()
        event["sns_topic_arn"] = "arn:aws:sns:eu-west-2:111111111111:nuke-topic"

        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        sns_client = MagicMock()

        def boto3_client_side_effect(service):
            if service == "secretsmanager":
                return secrets_client
            if service == "sns":
                return sns_client
            return MagicMock()

        mock_boto3_client.side_effect = boto3_client_side_effect
        mock_subprocess_run.return_value = SimpleNamespace(
            stdout="line one\nwould remove ec2\nline two\nwould remove s3-bucket",
            stderr="",
            returncode=0,
        )

        handler.lambda_handler(event, None)

        sns_client.publish.assert_called_once()
        kwargs = sns_client.publish.call_args.kwargs
        self.assertEqual(kwargs["TopicArn"], event["sns_topic_arn"])
        self.assertEqual(kwargs["Subject"], "AWS Nuke - weekly-nuke")
        self.assertIn("would remove ec2", kwargs["Message"])
        self.assertIn("would remove s3-bucket", kwargs["Message"])

    def test_raises_value_error_when_secret_name_missing(self):
        """Lambda must raise ValueError immediately when no secret identifier is supplied."""
        event = {
            "dry_run": True,
            "task_name": "dry-run",
            # Deliberately omit 'secret_name' and 'secret_arn'
        }
        with self.assertRaises(ValueError) as exc:
            handler.lambda_handler(event, None)
        self.assertIn("secret_name", str(exc.exception))

    def test_raises_value_error_when_secret_name_is_none(self):
        """Lambda must raise ValueError when secret_name is explicitly None."""
        event = {
            "dry_run": True,
            "secret_name": None,
            "task_name": "dry-run",
        }
        with self.assertRaises(ValueError):
            handler.lambda_handler(event, None)

    def test_raises_value_error_when_secret_arn_is_none(self):
        """Lambda must raise ValueError when both secret_name and secret_arn are None."""
        event = {
            "dry_run": True,
            "secret_arn": None,
            "task_name": "dry-run",
        }
        with self.assertRaises(ValueError):
            handler.lambda_handler(event, None)

    @patch("handler.subprocess.run")
    @patch("handler.boto3.client")
    def test_raises_runtime_error_when_nuke_fails(
        self, mock_boto3_client, mock_subprocess_run
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        mock_subprocess_run.return_value = SimpleNamespace(
            stdout="boom", stderr="error", returncode=2
        )

        with self.assertRaises(RuntimeError) as exc:
            handler.lambda_handler(self._base_event(), None)

        self.assertIn("aws-nuke exited with code 2", str(exc.exception))
