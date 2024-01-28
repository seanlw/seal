FROM alpine/k8s:1.28.1

# Install Kubeconform
RUN curl -sL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz | tar xz -C /tmp && \
    mv /tmp/kubeconform /usr/local/bin && \
    chmod +x /usr/local/bin/kubeconform

# Install Kubeseal
RUN KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-) && \
  curl -sL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"  | tar xz -C /tmp && \
  mv /tmp/kubeseal /usr/local/bin && \
  chmod +x /usr/local/bin/kubeseal

COPY seal.sh /usr/local/bin
RUN chmod +x /usr/local/bin/seal.sh

RUN mkdir /secrets && \
    mkdir /certs
WORKDIR /secrets

ENTRYPOINT ["/usr/local/bin/seal.sh"]