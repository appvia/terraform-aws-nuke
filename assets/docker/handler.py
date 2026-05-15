"""
Lambda handler for the aws-nuke Lambda function.
"""

import boto3
import subprocess
import tempfile
import os
import logging
import json
from typing import Any

# Default logger for all log messages in this module, configured to emit JSON-formatted logs to stdout.
logger = logging.getLogger(__name__)
# Set the log level from the environment variable (set by Terraform) or default to INFO.
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())

"""
Custom JSON formatter for structured logging.
"""


class _JSONFormatter(logging.Formatter):
    """Emit each log record as a single JSON object."""

    # Standard Python logging record fields to exclude from output
    _EXCLUDE_FIELDS = {
        "name",
        "msg",
        "args",
        "created",
        "filename",
        "funcName",
        "levelname",
        "levelno",
        "module",
        "msecs",
        "pathname",
        "process",
        "processName",
        "relativeCreated",
        "stack_info",
        "thread",
        "threadName",
        "exc_info",
        "exc_text",
        "taskName",
    }

    def format(self, record: logging.LogRecord) -> str:
        log_entry: dict[str, Any] = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        # Include only extra fields (exclude standard logging record attributes)
        for key, value in record.__dict__.items():
            if key not in self._EXCLUDE_FIELDS:
                log_entry[key] = value

        if record.exc_info and record.exc_info[0] is not None:
            log_entry["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_entry, default=str)


_handler = logging.StreamHandler()
_handler.setFormatter(_JSONFormatter())
logger.handlers = [_handler]
logger.propagate = False


def lambda_handler(event, context):
    dry_run = event.get("dry_run")
    secret_name = event.get("secret_name") or event.get("secret_arn")
    sns_topic = event.get("sns_topic_arn") or None
    task_name = event.get("task_name")
    log_level = ("DEBUG" if event.get("debug") else os.environ.get("LOG_LEVEL", "DEBUG")).upper()

    # Set the log level for this module to the value of the LOG_LEVEL
    # environment variable
    logger.setLevel(log_level)

    if not secret_name:
        raise ValueError(
            "Event must include a non-empty 'secret_name' or 'secret_arn' key "
            "containing the Secrets Manager secret ID or ARN for the aws-nuke config."
        )

    logger.info(
        "Starting execution of aws-nuke",
        extra={
            "action": "lambda_handler",
            "dry_run": dry_run,
            "secret_name": secret_name,
            "sns_topic": sns_topic,
            "task_name": task_name,
        },
    )

    # Fetch nuke config from SecretsManager
    sm = boto3.client("secretsmanager")
    config_yaml = sm.get_secret_value(SecretId=secret_name)["SecretString"]

    with tempfile.NamedTemporaryFile(suffix=".yml", mode="w", delete=False) as f:
        f.write(config_yaml)
        config_path = f.name

    logger.debug(
        "aws-nuke command",
        extra={
            "action": "lambda_handler",
            "config_path": config_path,
            "config_yaml": config_yaml,
        },
    )

    cmd = [
        "/usr/local/bin/aws-nuke",
        "run",
        "--config",
        config_path,
        "--no-alias-check",
        "--force",
    ]
    if not dry_run:
        cmd.append("--no-dry-run")

    logger.info(
        "Executing aws-nuke command",
        extra={
            "action": "lambda_handler",
            "command": " ".join(cmd),
            "command_args": cmd,
        },
    )

    stdout_output = []
    stderr_output = []

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=3600,
        )

        stdout_output = result.stdout.splitlines() if result.stdout else []
        stderr_output = result.stderr.splitlines() if result.stderr else []

        for line in stdout_output:
            logger.info(
                "aws-nuke stdout",
                extra={
                    "action": "lambda_handler",
                    "output": line,
                },
            )

        if stderr_output:
            for line in stderr_output:
                logger.warning(
                    "aws-nuke stderr",
                    extra={
                        "action": "lambda_handler",
                        "output": line,
                    },
                )

        # Determine if process was killed by signal (negative return code)
        signal_num = -result.returncode if result.returncode < 0 else None

        logger.info(
            "aws-nuke command completed",
            extra={
                "action": "lambda_handler",
                "task_name": task_name,
                "return_code": result.returncode,
                "signal_number": signal_num,
                "stdout_lines": len(stdout_output),
                "stderr_lines": len(stderr_output),
            },
        )

    except subprocess.TimeoutExpired:
        logger.error(
            "aws-nuke command timed out",
            extra={
                "action": "lambda_handler",
                "task_name": task_name,
                "timeout_seconds": 3600,
            },
        )
        raise RuntimeError("aws-nuke command timed out after 3600 seconds")
    except Exception as e:
        logger.error(
            "aws-nuke command execution error",
            extra={
                "action": "lambda_handler",
                "task_name": task_name,
                "error": str(e),
            },
            exc_info=True,
        )
        raise

    if sns_topic and result.returncode == 0:
        would_remove = [line for line in stdout_output if "would remove" in line]
        if would_remove:
            boto3.client("sns").publish(
                TopicArn=sns_topic,
                Subject=f"AWS Nuke - {task_name}",
                Message="\n".join(would_remove),
            )

    if result.returncode != 0:
        signal_info = ""
        if result.returncode < 0:
            signal_info = f" (killed by signal {-result.returncode})"
        
        logger.error(
            "aws-nuke command failed",
            extra={
                "action": "lambda_handler",
                "task_name": task_name,
                "return_code": result.returncode,
                "signal_number": -result.returncode if result.returncode < 0 else None,
                "full_stdout": (
                    "\n".join(stdout_output) if stdout_output else "No output"
                ),
                "full_stderr": (
                    "\n".join(stderr_output) if stderr_output else "No errors"
                ),
            },
        )
        raise RuntimeError(
            f"aws-nuke exited with code {result.returncode}{signal_info}\n"
            f"stderr: {chr(10).join(stderr_output) if stderr_output else 'No errors'}"
        )

    return {
        "action": "lambda_handler",
        "dry_run": dry_run,
        "status": "success",
        "task_name": task_name,
    }
