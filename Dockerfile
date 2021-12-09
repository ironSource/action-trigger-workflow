# https://hub.docker.com/_/alpine
FROM alpine:3.15


RUN apk update
RUN apk --no-cache add curl
RUN apk add jq

COPY validate_args.sh /validate_args.sh
COPY trigger_workflow.sh /trigger_workflow.sh
COPY wait_for_workflow_to_finish.sh /wait_for_workflow_to_finish.sh
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
