#!/usr/bin/env bats

load "../utils.bash"

export TEMPLATE_UNDER_TEST="templates/statefulset.yaml"

setup_file () {
    cd "$(vrouter_chart_dir)" || exit
    helm dependency update .
}

@test "vRouter StatefulSet: Name consists of the release name and chart name" {
    template
    assert_query_equal '.metadata.name' "release-name-xrd-vrouter"
}

@test "vRouter StatefulSet: Name can be overridden with fullnameOverride" {
    template --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test"
}

@test "vRouter StatefulSet: Name can be overridden with nameOverride" {
    template --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test"
}

@test "vRouter StatefulSet: Namespace is default" {
    template
    assert_query_equal '.metadata.namespace' "default"
}

@test "vRouter StatefulSet: No annotations are set by default" {
    template
    assert_query '.metadata.annotations | not'
}

@test "vRouter StatefulSet: Global annotations and commonAnnotations can be set" {
    template --set 'global.annotations.foo=bar' --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "vRouter StatefulSet: Annotations, global annotations and commonAnnotations can be set" {
    template \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa' \
        --set 'annotations.qux=quux'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
    assert_query_equal '.metadata.annotations.qux' "quux"
}

@test "vRouter StatefulSet: Recommended labels are set" {
    template
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter StatefulSet: Global labels and commonLabels can be set" {
    template --set 'global.labels.foo=bar' --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "vRouter StatefulSet: Labels can be added" {
    template --set 'labels.foo=bar'
    assert_query_equal '.metadata.labels.foo' "bar"
}

@test "vRouter StatefulSet: Replicas is one" {
    template
    assert_query_equal '.spec.replicas' "1"
}

@test "vRouter StatefulSet: serviceName is the name of the StatefulSet" {
    template
    assert_fields_equal '.spec.serviceName' '.metadata.name'
}

@test "vRouter StatefulSet: No serviceAccountName by default" {
    template
    assert_query '.spec.serviceAccountName | not'
}

@test "vRouter StatefulSet: serviceAccountName can be set" {
    template --set 'serviceAccountName=foo'
    assert_query_equal '.spec.template.spec.serviceAccountName' "foo"
}

@test "vRouter StatefulSet: Selector labels are set" {
    template
    assert_query_equal '.spec.selector.matchLabels' \
        "app.kubernetes.io/name: xrd-vrouter\napp.kubernetes.io/instance: release-name"
}

@test "vRouter StatefulSet: No .spec.template annotations are set by default" {
    template
    assert_query '.spec.template.metadata.annotations | not'
}

@test "vRouter StatefulSet: .spec.template global annotations and commonAnnotations can be set" {
    template --set 'global.annotations.foo=bar' --set 'commonAnnotations.baz=baa'
    assert_query_equal '.spec.template.metadata.annotations.foo' "bar"
    assert_query_equal '.spec.template.metadata.annotations.baz' "baa"
}

@test "vRouter StatefulSet: .spec.template annotations are added for multus interfaces" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.spec.template.metadata.annotations."k8s.v1.cni.cncf.io/networks"' \
        "[\n  {\n    \"name\": \"release-name-xrd-vrouter-0\"\n  }\n]"
}

@test "vRouter StatefulSet: .spec.template podAnnotations can be set" {
    template --set 'podAnnotations.foo=bar'
    assert_query_equal '.spec.template.metadata.annotations.foo' "bar"
}

@test "vRouter StatefulSet: podNetworkAnnotations contain the desired information" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "attachmentConfig": {"foo": "bar"}}]' \
        --set-json 'interfaces=[{"type": "sriov", "resource": "baz"}]'
    assert_query_equal '.spec.template.metadata.annotations."k8s.v1.cni.cncf.io/networks"' \
        "[\n  {\n    \"name\": \"release-name-xrd-vrouter-0\"\n  },\n  {\n    \"foo\": \"bar\",\n    \"name\": \"release-name-xrd-vrouter-1\"\n  }\n]"
}

@test "vRouter StatefulSet: .spec.template recommended labels are set" {
    template
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.spec.template.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.spec.template.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter StatefulSet: Global and common labels can be set for .spec.template" {
    template --set 'global.labels.foo=bar' --set 'commonLabels.baz=baa'
    assert_query_equal '.spec.template.metadata.labels.foo' "bar"
    assert_query_equal '.spec.template.metadata.labels.baz' "baa"
}

@test "vRouter StatefulSet: podLabels can be added for .spec.template" {
    template --set 'podLabels.foo=bar'
    assert_query_equal '.spec.template.metadata.labels.foo' "bar"
}

@test "vRouter StatefulSet: No hostNetwork by default" {
    template
    assert_query_equal '.spec.template.spec.hostNetwork' "null"
}

@test "vRouter StatefulSet: hostNetwork can be set to true" {
    template --set 'hostNetwork=true'
    assert_query_equal '.spec.template.spec.hostNetwork' "true"
}

@test "vRouter StatefulSet: no volumes by default" {
    template
    assert_query '.spec.template.spec.volumes | not'
}

@test "vRouter StatefulSet: Startup config is added to volumes" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.spec.template.spec.volumes[0].name' "config"
}

@test "vRouter StatefulSet: Startup config can be set using username and password" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-vrouter-config"
    assert_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.cfg\n  path: startup.cfg"
}

@test "vRouter StatefulSet: Startup config can be set using ascii" {
    template --set 'config.ascii=foo'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-vrouter-config"
    assert_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.cfg\n  path: startup.cfg"
}

@test "vRouter StatefulSet: Startup script can be set" {
    template --set 'config.script=foo'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-vrouter-config"
    assert_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.sh\n  path: startup.sh\n  mode: 0744"
}

@test "vRouter StatefulSet: ztpIni can't be set without being enabled" {
    template_failure --set 'config.ztpIni=foo'
    assert_error_message_contains "ztpIni can only be specified if ztpEnable is set to true"
}

@test "vRouter StatefulSet: ztpIni can be set if it is enabled" {
    template --set 'config.ztpIni=foo' --set 'config.ztpEnable=true'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-vrouter-config"
    assert_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: ztp.ini\n  path: ztp.ini"
}

@test "vRouter StatefulSet: persistentVolumeClaim can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.existingClaim=foo'
    assert_query_equal '.spec.template.spec.volumes[0].name' "xr-storage"
    assert_query_equal '.spec.template.spec.volumes[0].persistentVolumeClaim.claimName' "foo"
}

@test "vRouter StatefulSet: Extra host path mounts can be set" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-vrouter-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "Directory"
}

@test "vRouter StatefulSet: Extra host path mounts can be set with create=true" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar", "create": "true"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-vrouter-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "DirectoryOrCreate"
}

@test "vRouter StatefulSet: Two extra host path mounts can be set" {
    template \
        --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar"}' \
        --set-json 'extraHostPathMounts[1]={"name": "baz", "hostPath": "baa"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-vrouter-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "Directory"
    assert_query_equal '.spec.template.spec.volumes[1].name' \
        "release-name-xrd-vrouter-hostmount-baz"
    assert_query_equal '.spec.template.spec.volumes[1].hostPath.path' "baa"
    assert_query_equal '.spec.template.spec.volumes[1].hostPath.type' "Directory"
}

@test "vRouter StatefulSet: extraVolumes can be set" {
    template --set 'extraVolumes[0].name=foo'
    assert_query_equal '.spec.template.spec.volumes[0].name' "foo"
}

@test "vRouter StatefulSet: downwardAPI volume is set if sriov network" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo"}]'
    assert_query_equal '.spec.template.spec.volumes[0].name' "network-status-annotation"
    assert_query_equal '.spec.template.spec.volumes[0].downwardAPI.items[0].fieldRef.fieldPath' "metadata.annotations['k8s.v1.cni.cncf.io/network-status']"
    assert_query_equal '.spec.template.spec.volumes[0].downwardAPI.items[0].path' "network-status-annotation"
}


@test "vRouter: Image repository must be specified" {
    template_failure_no_set --set 'image.tag=latest'
    assert_error_message_contains "image: repository is required"
}

@test "vRouter: Image tag must be specified" {
    template_failure_no_set --set 'image.repository=local'
    assert_error_message_contains "image: tag is required"
}

@test "vRouter StatefulSet: container image is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].image' "local:latest"
}

@test "vRouter StatefulSet: default container resources are set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].resources.limits.hugepages-1Gi' "3Gi"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "5Gi"
}

@test "vRouter StatefulSet: container image resources can be set" {
    template --set 'resources.requests.foo=bar' --set 'resources.limits.baz=baa'
    assert_query_equal '.spec.template.spec.containers[0].resources.limits.hugepages-1Gi' "3Gi"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "5Gi"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.foo' "bar"
    assert_query_equal '.spec.template.spec.containers[0].resources.limits.baz' "baa"
}

@test "vRouter StatefulSet: default memory resource request can be overridden" {
    template --set 'resources.requests.memory=4Gi' --set 'resources.limits.hugepages-1Gi=6Gi'
    assert_query_equal '.spec.template.spec.containers[0].resources.limits.hugepages-1Gi' "6Gi"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "4Gi"
}

@test "vRouter StatefulSet: container name is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].name' "main"
}

@test "vRouter StatefulSet: default container securityContext is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].securityContext.privileged' "true"
}

@test "vRouter StatefulSet: container securityContext can be set" {
    template --set 'securityContext.privileged=false'
    assert_query_equal '.spec.template.spec.containers[0].securityContext.privileged' "false"
}

@test "vRouter StatefulSet: default container imagePullPolicy is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "Always"
}

@test "vRouter StatefulSet: container imagePullPolicy can be set" {
    template --set 'image.pullPolicy=IfNotPresent'
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "IfNotPresent"
}

@test "vRouter StatefulSet: illegal container imagePullPolicy are rejected" {
    template_failure --set 'image.pullPolicy=foo'
    assert_error_message_contains \
        "image.pullPolicy must be one of the following: \"Always\", \"IfNotPresent\", \"Never\""
}

@test "vRouter StatefulSet: container tty is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].tty' "true"
}

@test "vRouter StatefulSet: container stdin is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].stdin' "true"
}

@test "vRouter StatefulSet: container env vars version is set" {
    template
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_ENV_VARS_VERSION"))][0][0].value' "1"
}

@test "vRouter StatefulSet: empty container interface env vars are set by default" {
    template
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_INTERFACES"))][0][0].value' ""
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' ""
}

@test "vRouter StatefulSet: default hugepage size container env var is set" {
    template
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_DP_HUGEPAGE_MB"))][0][0].value' "3072"
}

@test "vRouter StatefulSet: non-default hugepage size container env var has correct size" {
    template --set 'resources.limits.hugepages-1Gi=6Gi'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_DP_HUGEPAGE_MB"))][0][0].value' "6144"
}

@test "vRouter StatefulSet: cpu set container env var can be set" {
    template --set 'cpu.cpuset=foo'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_CPUSET"))][0][0].value' "foo"
}

@test "vRouter StatefulSet: control plane cpu count container env var can be set" {
    template --set 'cpu.controlPlaneCpuCount=10'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_CP_NUM_CPUS"))][0][0].value' "10"
}

@test "vRouter StatefulSet: hyperthreading mode container env var can be set" {
    template --set 'cpu.hyperThreadingMode=off'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_HT_MODE"))][0][0].value' "off"
}

@test "vRouter StatefulSet: PCI driver container env var can be set" {
    template --set 'pciDriver=vfio-pci'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_VROUTER_PCI_DRIVER"))][0][0].value' "vfio-pci"
}

@test "vRouter StatefulSet: XR_INTERFACES container env vars is correctly set" {
    template --set-json 'interfaces=[{"type": "pci", "config": {"device": "00:00.0"}}, {"type": "sriov", "resource": "foo/bar"}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_INTERFACES"))][0][0].value' "pci:00:00.0;net-attach-def:default/release-name-xrd-vrouter-1"
}

@test "vRouter StatefulSet: XR_INTERFACES container env vars is correctly set (sriov)" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo/bar"}]' \
       --set 'fullnameOverride=xrd-test'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_INTERFACES"))][0][0].value' "net-attach-def:default/xrd-test-0"
}

@test "vRouter StatefulSet: pci XR_INTERFACES don't support any flags currently" {
    template_failure --set-json 'interfaces=[{"type": "pci", "config": {"device": "00:00.0"}, "chksum": true}]'
    assert_error_message_contains "Additional property chksum is not allowed"
}

@test "vRouter StatefulSet: sriov XR_INTERFACES don't support any flags currently" {
    template_failure --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "chksum": true}]'
    assert_error_message_contains "Additional property chksum is not allowed"
}

@test "vRouter StatefulSet: XR_MGMT_INTERFACES container env vars is correctly set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1"
}

@test "vRouter StatefulSet: set snoopIpv4Address flag in XR_MGMT_INTERFACES" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "snoopIpv4Address": true}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1,snoop_v4"
}

@test "vRouter StatefulSet: set snoopIpv4DefaultRoot flag in XR_MGMT_INTERFACES" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "snoopIpv4DefaultRoute": true}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1,snoop_v4_default_route"
}

@test "vRouter StatefulSet: set snoopIpv6Address flag in XR_MGMT_INTERFACES" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "snoopIpv6Address": true}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1,snoop_v6"
}

@test "vRouter StatefulSet: set snoopIpv6DefaultRoot flag in XR_MGMT_INTERFACES" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "snoopIpv6DefaultRoute": true}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1,snoop_v6_default_route"
}

@test "vRouter StatefulSet: set chksum flag in XR_MGMT_INTERFACES" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "chksum": true}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_MGMT_INTERFACES"))][0][0].value' "linux:net1,chksum"
}

@test "vRouter StatefulSet: xrName flag  is not allowed for vRouter" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "multus", "xrName": "foo"}]'
    assert_error_message_contains "xrName may not be specified for interfaces on XRd vRouter"
}

@test "vRouter StatefulSet: don't set unsupported flags XR_MGMT_INTERFACES" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "multus", "foo": "bar"}]'
    assert_error_message_contains "Additional property foo is not allowed"
}

@test "vRouter StatefulSet: XR_NETWORK_STATUS_ANNOTATION_PATH is not set by default" {
    template
    assert_query '[.spec.template.spec.containers[0].env | map(select(.name == "XR_NETWORK_STATUS_ANNOTATION_PATH"))][0][0] | not'
}

@test "vRouter StatefulSet: XR_NETWORK_STATUS_ANNOTATION_PATH is set when there is an sriov network" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo"}]'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_NETWORK_STATUS_ANNOTATION_PATH"))][0][0].value' "/etc/xrd/network-status/network-status-annotation"
}

@test "vRouter StatefulSet: XR_DISK_USAGE_LIMIT is set if persistence is enabled with default value" {
    template --set 'persistence.enabled=true'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_DISK_USAGE_LIMIT"))][0][0].value' "6G"
}

@test "vRouter StatefulSet: value of XR_DISK_USAGE_LIMIT can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.size=123kb'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_DISK_USAGE_LIMIT"))][0][0].value' "123K"
}

@test "vRouter StatefulSet: XR_FIRST_BOOT_CONFIG is set if config is to be applied on first boot" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_FIRST_BOOT_CONFIG"))][0][0].value' "/etc/xrd/startup.cfg"
}

@test "vRouter StatefulSet: XR_EVERY_BOOT_CONFIG is set if ascii config is to be applied on every boot" {
    template --set 'config.ascii=foo' --set 'config.asciiEveryBoot=true'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_EVERY_BOOT_CONFIG"))][0][0].value' "/etc/xrd/startup.cfg"
}

@test "vRouter StatefulSet: XR_ZTP_ENABLE can be set" {
    template --set 'config.ztpEnable=true'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_ZTP_ENABLE"))][0][0].value' "1"
}

@test "vRouter StatefulSet: XR_ZTP_INI can be set" {
    template --set 'config.ztpEnable=true' --set 'config.ztpIni=foo'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_ZTP_ENABLE"))][0][0].value' "1"
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_ZTP_ENABLE_WITH_INI"))][0][0].value' "/etc/xrd/ztp.ini"
}

@test "vRouter StatefulSet: advanced settings can be used to add env vars" {
    template --set 'advancedSettings.FOO=bar'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "FOO"))][0][0].value' "bar"
}

@test "vRouter StatefulSet: advanced settings can be used to override default settings" {
    template \
        --set 'config.ascii=foo' \
        --set 'advancedSettings.XR_FIRST_BOOT_CONFIG=foo'
    assert_query_equal '[.spec.template.spec.containers[0].env | map(select(.name == "XR_FIRST_BOOT_CONFIG"))][0][0].value' "foo"
}

@test "vRouter StatefulSet: no container volumeMounts by default" {
    template
    assert_query '.spec.template.spec.containers[0].volumeMounts[0] | not'
}

@test "vRouter StatefulSet: container volumeMounts is set if there is config" {
    template --set 'config.ascii=foo'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/etc/xrd"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "config"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].readOnly' "true"
}

@test "vRouter StatefulSet: container volumeMounts for persistence is set if persistence is enabled" {
    template --set 'persistence.enabled=true'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/xr-storage"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "xr-storage"
}

@test "vRouter StatefulSet: container volumeMounts for extra host path mounts can be set with default mountPath" {
    template \
        --set 'extraHostPathMounts[0].name=foo' \
        --set 'extraHostPathMounts[0].hostPath=bar'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "bar"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' \
        "release-name-xrd-vrouter-hostmount-foo"
}

@test "vRouter StatefulSet: container volumeMounts for extra host path mounts can be set with specified mountPath" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar", "mountPath": "baz"}'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "baz"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' \
        "release-name-xrd-vrouter-hostmount-foo"
}

@test "vRouter StatefulSet: extra container volumeMounts can be set" {
    template --set-json 'extraVolumeMounts[0]={"mountPath": "foo", "name": "bar"}'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "foo"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "bar"
}

@test "vRouter StatefulSet: network-status annotation is mounted if there is sriov network" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo"}]'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/etc/xrd/network-status"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "network-status-annotation"
}

@test "vRouter StatefulSet: container imagePullSecrets can be set" {
    template --set 'image.pullSecrets[0].name=foo'
    assert_query_equal '.spec.template.spec.imagePullSecrets[0].name' "foo"
}

@test "vRouter StatefulSet: container nodeSelector can be set" {
    template --set 'nodeSelector.foo=bar'
    assert_query_equal '.spec.template.spec.nodeSelector.foo' "bar"
}

@test "vRouter StatefulSet: container affinity can be set" {
    template \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=foo' \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=bar'
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key' \
        "foo"
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator' \
        "bar"
}

@test "vRouter StatefulSet: container tolerations can be set" {
    template --set 'tolerations[0].key=foo'
    assert_query_equal '.spec.template.spec.tolerations[0].key' "foo"
}

@test "vRouter StatefulSet: default container volumeClaimTemplates is set when persistence is enabled" {
    template --set 'persistence.enabled=true'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.name' "xr-storage"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.accessModes[0]' "ReadWriteOnce"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.resources.requests.storage' "6Gi"
}

@test "vRouter StatefulSet: volumeClaimTemplates contains set annotations" {
    template --set 'persistence.enabled=true' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa' \
        --set 'persistence.annotations.qux=quux'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.foo' "bar"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.baz' "baa"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.qux' "quux"
}

@test "vRouter StatefulSet: volumeClaimTemplates contains set labels" {
    template --set 'persistence.enabled=true' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels.foo' "bar"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels.baz' "baa"
}

@test "vRouter StatefulSet: volumeClaimTemplates accessModes can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.accessModes[0]=ReadOnly'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.accessModes[0]' "ReadOnly"
}

@test "vRouter StatefulSet: volumeClaimTemplates selector can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.selector.matchLabels.release=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.selector.matchLabels.release' "foo"
}

@test "vRouter StatefulSet: volumeClaimTemplates contains the set storage size" {
    template --set 'persistence.enabled=true' --set 'persistence.size=123kb'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.resources.requests.storage' "123kb"
}

@test "vRouter StatefulSet: volumeClaimTemplates existing volume can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.existingVolume=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.volumeName' "foo"
}

@test "vRouter StatefulSet: volumeClaimTemplates storage class can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.storageClass=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.storageClassName' "foo"
}

@test "vRouter StatefulSet: volumeClaimTemplates data source can be set" {
    template --set 'persistence.enabled=true' \
        --set-json 'persistence.dataSource={"name": "foo", "kind": "bar"}'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.dataSource.name' "foo"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.dataSource.kind' "bar"
}