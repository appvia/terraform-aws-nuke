# The image to use for the aws-nuke container
ARG NUKE_IMAGE=ghcr.io/ekristen/aws-nuke
# The tag of the aws-nuke image to use
ARG NUKE_TAG=v3.64.0-4-gadaabe0-arm64

FROM ${NUKE_IMAGE}:${NUKE_TAG} AS nuke
# Pull the Python 3.12 Lambda image
FROM public.ecr.aws/lambda/python:3.14
# Copy the aws-nuke binary from the container image
COPY --from=nuke /usr/local/bin/aws-nuke /usr/local/bin/aws-nuke
# Copy the Lambda handler
COPY handler.py ${LAMBDA_TASK_ROOT}/handler.py
# Execute the Lambda handler
CMD ["handler.lambda_handler"]
