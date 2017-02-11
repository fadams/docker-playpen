FROM alpine

RUN apk update && apk upgrade \
    && apk add nodejs \
    && npm uninstall -g npm \
    && rm -rf /var/cache/apk/*

# docker build --no-cache -t fadams/node .
