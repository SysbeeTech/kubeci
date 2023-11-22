# KubeCI

KubeCI is Debian based container image packed with toolset for deploying Helm charts via Helmfile into Kubernetes clusters.

## Image availability

Current image is available on Dockerhub via:

```
docker pull sysbee/kubeci
```

or Github container registry:

```
docker pull ghcr.io/sysbeetech/kubeci
```

## Versioning

KubeCI uses semver for tagging container images tracking major and minor with kubectl.

* `main` - tag will track current main branch
* `latest` - tag will always point to latest release
* `1.27.x` - tag will track major, minor version of kubectl in the image, while patch version will increment based on other toolset version updates
* `1.27` - tag will track latest `1.27.x`

## Installed tools:

- **kubectl** - https://kubernetes.io/docs/reference/kubectl/
- **SOPS** - https://github.com/getsops/sops
- **Helm** - https://github.com/helm/helm
- **Helmfile** - https://github.com/helmfile/helmfile
- **vals** - https://github.com/helmfile/vals
- **awscli** - https://github.com/aws/aws-cli
- **yamllint** - https://github.com/adrienverge/yamllint
- **git** - https://git-scm.com/
- **curl** - https://curl.se/

### Helm plugins

- **helm-diff** - https://github.com/databus23/helm-diff
- **helm-secrets** - https://github.com/jkroepke/helm-secrets
- **helm-git** - https://github.com/aslafy-z/helm-git
