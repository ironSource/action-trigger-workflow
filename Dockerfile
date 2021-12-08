# https://hub.docker.com/_/alpine
FROM alpine:3.15


RUN apk update
RUN apk --no-cache add curl
RUN apk add jq

COPY entrypoint.sh /entrypoint.sh
COPY inputs_validation.sh /inputs_validation.sh
COPY trigger_workflow.sh /trigger_workflow.sh
COPY get_running_workflow_id.sh /get_running_workflow_id.sh
COPY wait_for_workflow_to_finish.sh /wait_for_workflow_to_finish.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
