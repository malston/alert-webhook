FROM alpine:3.10

RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/*

WORKDIR /amhook
ADD alert-webhook_unix alert-webhook
# ADD gmail-token .

CMD ["./alert-webhook"]