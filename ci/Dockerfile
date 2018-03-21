FROM alpine:3.5

RUN apk update && apk add --no-cache curl

# curl kubectl instead of ADD'ing it, since we want to cache the layer
RUN curl -sfL \
      -o /usr/local/bin/kubectl \
      https://storage.googleapis.com/kubernetes-release/release/v1.9.5/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

RUN apk add --no-cache \
        bash \
        git \
        ca-certificates \
        groff \
        less \
        python3 \
        py3-pip \
        py3-yaml \
        openssh-client \
        jq \
        bind-tools \
        tar \
    && pip3 install awscli boto3

VOLUME /src
WORKDIR /src
