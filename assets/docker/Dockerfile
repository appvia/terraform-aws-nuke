# The image to use for the aws-nuke container
ARG NUKE_IMAGE=ghcr.io/ekristen/aws-nuke
# The tag of the aws-nuke image to use
ARG NUKE_TAG=v3.65.0

FROM ${NUKE_IMAGE}:${NUKE_TAG} AS nuke
# Pull the Python 3.14 Lambda image
FROM public.ecr.aws/lambda/python:3.14

# Copy the aws-nuke binary from the nuke container image
COPY --from=nuke /usr/local/bin/aws-nuke /usr/local/bin/aws-nuke

# Copy runtime dependencies from nuke image (if any libraries are needed)
COPY --from=nuke /usr/lib /usr/lib
COPY --from=nuke /usr/share /usr/share

# Ensure aws-nuke is executable
RUN chmod +x /usr/local/bin/aws-nuke

# Copy the Lambda handler
COPY handler.py ${LAMBDA_TASK_ROOT}/handler.py

# Execute the Lambda handler
CMD ["handler.lambda_handler"]
