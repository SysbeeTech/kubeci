FROM debian:12.2-slim AS builder
MAINTAINER "branko@sysbee.net"

ARG TARGETARCH TARGETPLATFORM

# Install required utils
RUN apt-get update \
    && apt-get install -y curl git

# Install Cosign for verifying other packages
# renovate: datasource=github-release-attachments depName=sigstore/cosign versioning=semver
ARG COSIGN_VERSION=2.2.1
RUN curl -O -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${COSIGN_VERSION}_${TARGETARCH}.deb" \
    && dpkg -i cosign_${COSIGN_VERSION}_${TARGETARCH}.deb

RUN mkdir -p /tmp/binaries

# Install kubectl
# renovate: datasource=github-release-attachments depName=kubernetes/kubernetes versioning=semver
ARG KUBECTL_VERSION=v1.27.5

RUN set -x \
    && curl -LO https://cdn.dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl
RUN set -x \
    && echo "Verifying kubectl..." \
    && curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256" \
    && echo "$(cat kubectl.sha256) kubectl" | sha256sum -c
RUN set -x \
    && chmod +x kubectl \
    && mv -v kubectl /tmp/binaries/

# Install SOPS
# renovate: datasource=github-release-attachments depName=getsops/sops versioning=semver
ARG SOPS_VERSION=v3.8.1
ARG SOPS_FILENAME="sops-${SOPS_VERSION}.linux.${TARGETARCH}"

RUN set -x \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/${SOPS_FILENAME}
RUN set -x \
    && echo "Verifying SOPS checksums file signatures..." \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.txt \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.pem \
    && curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.checksums.sig \
    && cosign verify-blob "sops-${SOPS_VERSION}.checksums.txt" \
        --certificate "sops-${SOPS_VERSION}.checksums.pem" \
        --signature "sops-${SOPS_VERSION}.checksums.sig" \
        --certificate-identity-regexp=https://github.com/getsops \
        --certificate-oidc-issuer=https://token.actions.githubusercontent.com
RUN set -x \
    && echo "Verifying SOPS file integrity..." \
    && sha256sum -c sops-${SOPS_VERSION}.checksums.txt --ignore-missing
RUN set -x \
    && mv -v ${SOPS_FILENAME} /tmp/binaries/sops \
    && chmod +x /tmp/binaries/sops

# Install Helm
# renovate: datasource=github-release-attachments depName=helm/helm versioning=semver
ARG HELM_VERSION=v3.13.2
ARG HELM_FILENAME="helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz"

RUN set -x \
    && curl -LO https://get.helm.sh/${HELM_FILENAME}
RUN set -x \
    && echo Verifying Helm... \
    && curl -LO "https://get.helm.sh/${HELM_FILENAME}.sha256sum" \
    && sha256sum -c ${HELM_FILENAME}.sha256sum --ignore-missing
RUN set -x \
    && echo Extracting Helm... \
    && tar zxvf ${HELM_FILENAME} \
    && mv -v linux-${TARGETARCH}/helm /tmp/binaries/

# Install helmfile
# renovate: datasource=github-release-attachments depName=helmfile/helmfile versioning=semver
ARG HELMFILE_VERSION=v0.158.1

RUN set -x \
    && curl -LO  https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION#v}_linux_${TARGETARCH}.tar.gz
RUN set -x \
    && echo Verifying Helmfile file integrity... \
    && curl -LO https://github.com/helmfile/helmfile/releases/download/${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION#v}_checksums.txt \
    && sha256sum -c helmfile_${HELMFILE_VERSION#v}_checksums.txt --ignore-missing
RUN set -x \
    && echo Extracting Helmfile... \
    && tar zxvf helmfile_${HELMFILE_VERSION#v}_linux_${TARGETARCH}.tar.gz \
    && chmod +x helmfile \
    && mv -v helmfile /tmp/binaries/

# Install vals
# renovate: datasource=github-release-attachments depName=helmfile/vals versioning=semver
ARG HELMFILE_VALS_VERSION=v0.29.0

RUN set -x \
    && curl -LO https://github.com/helmfile/vals/releases/download/${HELMFILE_VALS_VERSION}/vals_${HELMFILE_VALS_VERSION#v}_linux_${TARGETARCH}.tar.gz
RUN set -x \
    && echo Verifying Helmfile Vals... \
    && curl -LO https://github.com/helmfile/vals/releases/download/${HELMFILE_VALS_VERSION}/vals_${HELMFILE_VALS_VERSION#v}_checksums.txt \
    && sha256sum -c vals_${HELMFILE_VALS_VERSION#v}_checksums.txt --ignore-missing
RUN set -x \
    && echo Extracting Helmfile Vals... \
    && tar zxvf vals_${HELMFILE_VALS_VERSION#v}_linux_${TARGETARCH}.tar.gz \
    && mv -v vals /tmp/binaries/

# Install Helm plugins

# renovate: datasource=github-release-attachments depName=databus23/helm-diff versioning=semver
ARG HELM_DIFF_VERSION=v3.8.1
# renovate: datasource=github-release-attachments depName=jkroepke/helm-secrets versioning=semver
ARG HELM_SECRETS_VERSION=v4.5.1
# renovate: datasource=github-release-attachments depName=aslafy-z/helm-git versioning=semver
ARG HELM_GIT_VERSION=v0.15.1

RUN set -x \
    && export PATH=$PATH:/tmp/binaries \
    && helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} \
    && helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} \
    && helm plugin install https://github.com/aslafy-z/helm-git.git --version ${HELM_GIT_VERSION}

FROM debian:12.2-slim
MAINTAINER "branko@sysbee.net"
LABEL org.opencontainers.image.source https://github.com/sysbeetech/kubeci
COPY --from=builder /tmp/binaries/ /usr/local/bin/
COPY --from=builder /root/.local/ /root/.local/
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y awscli yamllint git curl ca-certificates openssl \
    && apt-get autoremove -y \
    && apt-get clean autoclean\
    && rm -rf /var/lib/apt/lists/*
