# XRd Helm chart tests

## Prerequisites

The following dependencies are required for unit tests:

- [Bats](https://github.com/bats-core/bats-core)
- [Bats support](https://github.com/bats-core/bats-support)
- [Bats assert](https://github.com/bats-core/bats-assert)
- [Helm](https://helm.sh)
- [yq](https://github.com/mikefarah/yq)
- [yamllint](https://github.com/adrienverge/yamllint)
- [kubeconform](https://github.com/yannh/kubeconform)

## Running the tests in a container

A [Dockerfile](Dockerfile) is provided which defines a container image which includes all test dependencies.

The unit tests can be run using any container manager.  For example, using Docker:

```
docker build . -t helm-tests
docker run --rm -v "$PWD/../:/charts" helm-tests bats tests/ut/[host-check, xrd-control-plane or xrd-vrouter]
```
