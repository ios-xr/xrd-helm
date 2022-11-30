# XRd Helm charts

This repository contains [Helm charts](https://helm.sh/) for running XRd
using Kubernetes.

There are two application charts provided in this repository:
 - xrd-control-plane, for running XRd Control Plane containers.
 - xrd-vrouter, for running XRd vRouter containers.

There is also a library chart provided, xrd-common, that is used by both
of the application charts.

## Usage

[Helm](https://helm.sh) must be installed to use the charts. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```
helm repo add <alias> https://github.com/pages/ios-xr/xrd-helm
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the <chart-name> chart:

```
helm install my-<chart-name> <alias>/<chart-name>
```

To uninstall the chart:

```
helm delete my-<chart-name>
```
