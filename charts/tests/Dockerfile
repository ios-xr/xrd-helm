FROM bats/bats:1.9.0

WORKDIR /chart

RUN echo "@community https://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories

RUN apk update && \
    apk upgrade && \
    apk add curl docker helm@community yamllint yq

RUN curl -LO "https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64"
RUN curl -L "https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64.sha256sum" | sha256sum -c
RUN mv kind-linux-amd64 /usr/local/bin/kind && chmod +x /usr/local/bin/kind

RUN curl -LO "https://github.com/yannh/kubeconform/releases/download/v0.6.4/kubeconform-linux-amd64.tar.gz"
RUN echo "2b4ebeaa4d5ac4843cf8f7b7e66a8874252b6b71bc7cbfc4ef1cbf85acec7c07  kubeconform-linux-amd64.tar.gz" | sha256sum -c
RUN tar -xz -C /usr/local/bin -f kubeconform-linux-amd64.tar.gz kubeconform && rm kubeconform-linux-amd64.tar.gz

RUN curl -LO "https://dl.k8s.io/release/v1.29.1/bin/linux/amd64/kubectl"
RUN echo "$(curl -L https://dl.k8s.io/release/v1.29.1/bin/linux/amd64/kubectl.sha256)  kubectl" | sha256sum -c
RUN mv kubectl /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

ENTRYPOINT ["bash"]
