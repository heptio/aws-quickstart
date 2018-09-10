FROM alpine:3.7

RUN apk update && apk add --no-cache curl

# curl kubectl instead of ADD'ing it, since we want to cache the layer
RUN curl -sfL \
    -o /usr/local/bin/kubectl \
    https://storage.googleapis.com/kubernetes-release/release/v1.11.2/bin/linux/amd64/kubectl && \
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

RUN SONOBUOY_VERSION=$(curl -s https://api.github.com/repos/heptio/sonobuoy/releases/latest | jq -r '.tag_name | sub("^v"; "")') && \
    curl -sfL -o sonobuoy.tar.gz https://github.com/heptio/sonobuoy/releases/download/v${SONOBUOY_VERSION}/sonobuoy_${SONOBUOY_VERSION}_linux_amd64.tar.gz && \
    tar -xzf sonobuoy.tar.gz && \
    chown root:root sonobuoy && \
    chmod 0755 sonobuoy && \
    mv sonobuoy /usr/local/bin/sonobuoy && \
    rm sonobuoy.tar.gz

VOLUME /src
WORKDIR /src
