#!/usr/bin/env bash
#
##
# This script provides various options for invoking AWS Lambda functions with flexible filtering and date range support
#
# Usage:
#   ./scripts/invoke-lambda.sh [options]
#
# Options:
#   --function-name <name>     Lambda function name/ARN (default: terraform output lambda_function_name, else nuke-test)
#   --task-name <name>         Event task_name (default: dry-run)
#   --secret-arn <arn>         Event secret_arn (default: terraform output secret_arns[task_name], if available)
#   --sns-topic-arn <arn>      Event sns_topic_arn (default: empty)
#   --dry-run <true|false>     Event dry_run (default: true)
#   --region <region>          AWS region for invoke API (default: AWS_REGION/AWS_DEFAULT_REGION/eu-west-2)
#   --profile <profile>        AWS profile (default: AWS_PROFILE if set)
#   --output-file <path>       Write Lambda response payload here (default: ./lambda-invoke-response.json)
#   --invocation-type <type>   AWS invocation type (default: RequestResponse)
#   --log-type <type>          AWS log type (default: Tail)
#   -h, --help                 Show this help message
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

FUNCTION_NAME=""
TASK_NAME="dry-run"
SECRET_ARN=""
SNS_TOPIC_ARN=""
DRY_RUN="true"
REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-eu-west-2}}"
PROFILE="${AWS_PROFILE:-}"
INVOCATION_TYPE="RequestResponse"
LOG_TYPE="Tail"
OUTPUT_FILE="/tmp/lambda-invoke-response.json"

usage() {
  cat << 'EOF'
Invoke the aws-nuke Lambda handler with a JSON event payload.

Usage:
  ./scripts/invoke-lambda.sh [options]

Options:
  --function-name <name>     Lambda function name/ARN (default: terraform output lambda_function_name, else nuke-test)
  --task-name <name>         Event task_name (default: dry-run)
  --secret-arn <arn>         Event secret_arn (default: terraform output secret_arns[task_name], if available)
  --sns-topic-arn <arn>      Event sns_topic_arn (default: empty)
  --dry-run <true|false>     Event dry_run (default: true)
  --region <region>          AWS region for invoke API (default: AWS_REGION/AWS_DEFAULT_REGION/eu-west-2)
  --profile <profile>        AWS profile (default: AWS_PROFILE if set)
  --output-file <path>       Write Lambda response payload here (default: ./lambda-invoke-response.json)
  --invocation-type <type>   AWS invocation type (default: RequestResponse)
  --log-type <type>          AWS log type (default: Tail)
  -h, --help                 Show this help message
EOF
}

resolve_tf_output() {
  local output_name="$1"
  terraform -chdir="${REPO_ROOT}/examples/lambda" output -raw "${output_name}" 2> /dev/null || true
}

resolve_secret_arn_for_task() {
  local task_name="$1"
  local secrets_json

  secrets_json="$(terraform -chdir="${REPO_ROOT}/examples/lambda" output -json secret_arns 2> /dev/null || true)"
  if [[ -z ${secrets_json}   ]]; then
    return 0
  fi

  python3 - "${task_name}" "${secrets_json}" << 'PY'
import json
import sys

task_name = sys.argv[1]
raw_json = sys.argv[2]

try:
    data = json.loads(raw_json)
except json.JSONDecodeError:
    print("")
    raise SystemExit(0)

print(data.get(task_name, ""))
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --function-name)
      FUNCTION_NAME="${2:-}"
      shift 2
      ;;
    --task-name)
      TASK_NAME="${2:-}"
      shift 2
      ;;
    --secret-arn)
      SECRET_ARN="${2:-}"
      shift 2
      ;;
    --sns-topic-arn)
      SNS_TOPIC_ARN="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN="${2:-}"
      shift 2
      ;;
    --region)
      REGION="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --output-file)
      OUTPUT_FILE="${2:-}"
      shift 2
      ;;
    --invocation-type)
      INVOCATION_TYPE="${2:-}"
      shift 2
      ;;
    --log-type)
      LOG_TYPE="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ ${DRY_RUN} != "true" && ${DRY_RUN} != "false"     ]]; then
  echo "Error: --dry-run must be 'true' or 'false'" >&2
  exit 1
fi

if [[ -z ${FUNCTION_NAME}   ]]; then
  FUNCTION_NAME="$(resolve_tf_output "lambda_function_name")"
fi
if [[ -z ${FUNCTION_NAME}   ]]; then
  FUNCTION_NAME="nuke-test"
fi

if [[ -z ${SECRET_ARN}   ]]; then
  SECRET_ARN="$(resolve_secret_arn_for_task "${TASK_NAME}")"
fi

if [[ -z ${SECRET_ARN}   ]]; then
  echo "Error: secret ARN is required. Pass --secret-arn or ensure terraform output secret_arns is available." >&2
  exit 1
fi

PAYLOAD_FILE="$(mktemp)"
cleanup() {
  rm -f "${PAYLOAD_FILE}"
}
trap cleanup EXIT

python3 - "${TASK_NAME}" "${SECRET_ARN}" "${SNS_TOPIC_ARN}" "${DRY_RUN}" "${PAYLOAD_FILE}" << 'PY'
import json
import sys

task_name = sys.argv[1]
secret_arn = sys.argv[2]
sns_topic_arn = sys.argv[3]
dry_run = sys.argv[4].lower() == "true"
payload_file = sys.argv[5]

payload = {
    "dry_run": dry_run,
    "secret_arn": secret_arn,
    "task_name": task_name,
}

if sns_topic_arn:
    payload["sns_topic_arn"] = sns_topic_arn

with open(payload_file, "w", encoding="utf-8") as fp:
    json.dump(payload, fp)
PY

invoke_cmd=(
  aws lambda invoke
  --function-name "${FUNCTION_NAME}"
  --region "${REGION}"
  --cli-binary-format raw-in-base64-out
  --invocation-type "${INVOCATION_TYPE}"
  --log-type "${LOG_TYPE}"
  --payload "fileb://${PAYLOAD_FILE}"
  "${OUTPUT_FILE}"
)

if [[ -n ${PROFILE}   ]]; then
  invoke_cmd+=(--profile "${PROFILE}")
fi

echo "Invoking Lambda function: ${FUNCTION_NAME}"
echo "Task: ${TASK_NAME} | Dry run: ${DRY_RUN} | Region: ${REGION}"
"${invoke_cmd[@]}"
echo "Lambda response written to: ${OUTPUT_FILE}"
