import sys
import unittest
import subprocess
import io
import threading
from types import SimpleNamespace
from unittest.mock import MagicMock, patch, Mock, call

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

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_success_dry_run_returns_success(
        self, mock_boto3_client, mock_popen
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("would remove ec2-instance")
        mock_process.stderr = io.StringIO("")
        mock_process.returncode = 0
        mock_process.wait.return_value = 0
        mock_popen.return_value = mock_process

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
        called_cmd = mock_popen.call_args.args[0]
        self.assertIn("/usr/local/bin/aws-nuke", called_cmd)
        self.assertNotIn("--no-dry-run", called_cmd)

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_non_dry_run_adds_no_dry_run_flag(
        self, mock_boto3_client, mock_popen
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
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("")
        mock_process.stderr = io.StringIO("")
        mock_process.returncode = 0
        mock_process.wait.return_value = 0
        mock_popen.return_value = mock_process

        result = handler.lambda_handler(event, None)

        self.assertEqual(result["dry_run"], False)
        called_cmd = mock_popen.call_args.args[0]
        self.assertIn("--no-dry-run", called_cmd)

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_sns_publish_happens_when_would_remove_lines_exist(
        self, mock_boto3_client, mock_popen
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
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("line one\nwould remove ec2\nline two\nwould remove s3-bucket")
        mock_process.stderr = io.StringIO("")
        mock_process.returncode = 0
        mock_process.wait.return_value = 0
        mock_popen.return_value = mock_process

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

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_raises_runtime_error_when_nuke_fails(
        self, mock_boto3_client, mock_popen
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("boom")
        mock_process.stderr = io.StringIO("error")
        mock_process.returncode = 2
        mock_process.wait.return_value = 2
        mock_popen.return_value = mock_process

        with self.assertRaises(RuntimeError) as exc:
            handler.lambda_handler(self._base_event(), None)

        self.assertIn("aws-nuke exited with code 2", str(exc.exception))

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_timeout_expired_raises_runtime_error(
        self, mock_boto3_client, mock_popen
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("")
        mock_process.stderr = io.StringIO("")
        mock_process.wait.side_effect = subprocess.TimeoutExpired("cmd", 3600)
        mock_process.kill.return_value = None
        mock_popen.return_value = mock_process

        with self.assertRaises(RuntimeError) as exc:
            handler.lambda_handler(self._base_event(), None)

        self.assertIn("timed out after 3600 seconds", str(exc.exception))
        mock_process.kill.assert_called_once()

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_streams_output_line_by_line(
        self, mock_boto3_client, mock_popen
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        
        mock_process = MagicMock()
        mock_process.returncode = 0
        
        stdout_lines = ["line 1", "line 2", "line 3"]
        stderr_lines = ["warning 1", "warning 2"]
        
        stdout_io = io.StringIO("\n".join(stdout_lines))
        stderr_io = io.StringIO("\n".join(stderr_lines))
        
        mock_process.stdout = stdout_io
        mock_process.stderr = stderr_io
        mock_process.wait.return_value = 0
        mock_popen.return_value = mock_process

        with patch("handler.logger") as mock_logger:
            handler.lambda_handler(self._base_event(), None)
            
            info_calls = [call for call in mock_logger.info.call_args_list 
                         if len(call.args) > 0 and "aws-nuke stdout" in str(call.args[0])]
            warning_calls = [call for call in mock_logger.warning.call_args_list 
                            if len(call.args) > 0 and "aws-nuke stderr" in str(call.args[0])]
            
            self.assertEqual(len(info_calls), 3, f"Expected 3 stdout logs, got {len(info_calls)}")
            self.assertEqual(len(warning_calls), 2, f"Expected 2 stderr logs, got {len(warning_calls)}")
            
            info_messages = [c.kwargs.get("extra", {}).get("output") for c in info_calls]
            warning_messages = [c.kwargs.get("extra", {}).get("output") for c in warning_calls]
            
            self.assertIn("line 1", info_messages)
            self.assertIn("line 2", info_messages)
            self.assertIn("line 3", info_messages)
            self.assertIn("warning 1", warning_messages)
            self.assertIn("warning 2", warning_messages)

    @patch("handler.subprocess.Popen")
    @patch("handler.boto3.client")
    def test_process_killed_by_signal(
        self, mock_boto3_client, mock_popen
    ):
        secrets_client = MagicMock()
        secrets_client.get_secret_value.return_value = {
            "SecretString": "regions: [eu-west-2]"
        }
        mock_boto3_client.side_effect = lambda service: (
            secrets_client if service == "secretsmanager" else MagicMock()
        )
        
        mock_process = MagicMock()
        mock_process.stdout = io.StringIO("output")
        mock_process.stderr = io.StringIO("error")
        mock_process.returncode = -15
        mock_process.wait.return_value = -15
        mock_popen.return_value = mock_process

        with self.assertRaises(RuntimeError) as exc:
            handler.lambda_handler(self._base_event(), None)

        self.assertIn("killed by signal 15", str(exc.exception))
