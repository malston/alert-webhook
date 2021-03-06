FROM alpine:3.10

RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

WORKDIR /amhook
ADD alert-webhook-linux-amd64 alert-webhook

CMD ["./alert-webhook"]