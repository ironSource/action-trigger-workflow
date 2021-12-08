# https://hub.docker.com/_/alpine
FROM alpine:3.15


RUN apk update
RUN apk --no-cache add curl
RUN apk add jq

COPY *.sh /*.sh

ENTRYPOINT ["sh", "/entrypoint.sh"]
