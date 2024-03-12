#!/usr/bin/env bats

load "utils.bash"

export TEMPLATE_UNDER_TEST="templates/statefulset.yaml"

setup_file () {
    cd "$(cp_chart_dir)" || exit
    helm dependency update .
}

@test "Control Plane StatefulSet: Name consists of the release name, template name and index" {
    template
    assert_query_equal '.metadata.name' "release-name-xrd-control-plane"
}

@test "Control Plane StatefulSet: Name can be overridden with fullnameOverride" {
    template --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test"
}

@test "Control Plane StatefulSet: Name can be overridden with nameOverride" {
    template --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test"
}

@test "Control Plane StatefulSet: Namespace is default" {
    template
    assert_query_equal '.metadata.namespace' "default"
}

@test "Control Plane StatefulSet: No annotations are set by default" {
    template
    assert_query '.metadata.annotations | not'
}

@test "Control Plane StatefulSet: Global annotations and commonAnnotations can be set" {
    template --set 'global.annotations.foo=bar' --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "Control Plane StatefulSet: Annotations, global annotations and commonAnnotations can be set" {
    template \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa' \
        --set 'annotations.qux=quux'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
    assert_query_equal '.metadata.annotations.qux' "quux"
}

@test "Control Plane StatefulSet: Recommended labels are set" {
    template
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-control-plane"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "Control Plane StatefulSet: Global labels and commonLabels can be set" {
    template --set 'global.labels.foo=bar' --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "Control Plane StatefulSet: Labels can be added" {
    template --set 'labels.foo=bar'
    assert_query_equal '.metadata.labels.foo' "bar"
}

@test "Control Plane StatefulSet: Replicas is one" {
    template
    assert_query_equal '.spec.replicas' "1"
}

@test "Control Plane StatefulSet: serviceName is the name of the StatefulSet" {
    template
    assert_fields_equal '.spec.serviceName' '.metadata.name'
}

@test "Control Plane StatefulSet: Selector labels are set" {
    template
    assert_multiline_query_equal '.spec.selector.matchLabels' \
        "app.kubernetes.io/name: xrd-control-plane\napp.kubernetes.io/instance: release-name"
}

@test "Control Plane StatefulSet: No .spec.template annotations are set by default" {
    template
    assert_query '.spec.template.metadata.annotations | not'
}

@test "Control Plane StatefulSet: .spec.template global annotations and commonAnnotations can be set" {
    template --set 'global.annotations.foo=bar' --set 'commonAnnotations.baz=baa'
    assert_query_equal '.spec.template.metadata.annotations.foo' "bar"
    assert_query_equal '.spec.template.metadata.annotations.baz' "baa"
}

@test "Control Plane StatefulSet: .spec.template annotations are added for multus interfaces" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_multiline_query_equal '.spec.template.metadata.annotations."k8s.v1.cni.cncf.io/networks"' \
        "[\n  {\n    \"name\": \"release-name-xrd-control-plane-0\"\n  }\n]"
}

@test "Control Plane StatefulSet: .spec.template podAnnotations can be set" {
    template --set 'podAnnotations.foo=bar'
    assert_query_equal '.spec.template.metadata.annotations.foo' "bar"
}

@test "Control Plane StatefulSet: podNetworkAnnotations contain the desired information" {
    template --set-json 'interfaces=[{"type": "multus", "attachmentConfig": {"foo": "bar"}, "config": {"baz": "baa"}}]'
    assert_multiline_query_equal '.spec.template.metadata.annotations."k8s.v1.cni.cncf.io/networks"' \
        "[\n  {\n    \"foo\": \"bar\",\n    \"name\": \"release-name-xrd-control-plane-0\"\n  }\n]"
}

@test "Control Plane StatefulSet: .spec.template recommended labels are set" {
    template
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/name"' "xrd-control-plane"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.spec.template.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.spec.template.metadata.labels | has("helm.sh/chart")'
}

@test "Control Plane StatefulSet: Global and common labels can be set for .spec.template" {
    template --set 'global.labels.foo=bar' --set 'commonLabels.baz=baa'
    assert_query_equal '.spec.template.metadata.labels.foo' "bar"
    assert_query_equal '.spec.template.metadata.labels.baz' "baa"
}

@test "Control Plane StatefulSet: podLabels can be added for .spec.template" {
    template --set 'podLabels.foo=bar'
    assert_query_equal '.spec.template.metadata.labels.foo' "bar"
}

@test "Control Plane StatefulSet: No hostNetwork by default" {
    template
    assert_query_equal '.spec.template.spec.hostNetwork' "null"
}

@test "Control Plane StatefulSet: hostNetwork can be set to true" {
    template --set 'hostNetwork=true'
    assert_query_equal '.spec.template.spec.hostNetwork' "true"
}

@test "Control Plane StatefulSet: no volumes by default" {
    template
    assert_query '.spec.template.spec.volumes | not'
}

@test "Control Plane StatefulSet: Startup config is added to volumes" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.spec.template.spec.volumes[0].name' "config"
}

@test "Control Plane StatefulSet: Startup config can be set using username and password" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-control-plane-config"
    assert_multiline_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.cfg\n  path: startup.cfg"
}

@test "Control Plane StatefulSet: Startup config can be set using ascii" {
    template --set 'config.ascii=foo'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-control-plane-config"
    assert_multiline_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.cfg\n  path: startup.cfg"
}

@test "Control Plane StatefulSet: Startup script can be set" {
    template --set 'config.script=foo'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-control-plane-config"
    assert_multiline_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: startup.sh\n  path: startup.sh\n  mode: 0744"
}

@test "Control Plane StatefulSet: ztpIni can't be set without being enabled" {
    template_failure --set 'config.ztpIni=foo'
    assert_error_message_contains "ztpIni can only be specified if ztpEnable is set to true"
}

@test "Control Plane StatefulSet: ztpIni can be set if it is enabled" {
    template --set 'config.ztpIni=foo' --set 'config.ztpEnable=true'
    assert_query_equal '.spec.template.spec.volumes[0].configMap.name' \
        "release-name-xrd-control-plane-config"
    assert_multiline_query_equal '.spec.template.spec.volumes[0].configMap.items' \
        "- key: ztp.ini\n  path: ztp.ini"
}

@test "Control Plane StatefulSet: persistentVolumeClaim can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.existingClaim=foo'
    assert_query_equal '.spec.template.spec.volumes[0].name' "xr-storage"
    assert_query_equal '.spec.template.spec.volumes[0].persistentVolumeClaim.claimName' "foo"
}

@test "Control Plane StatefulSet: Extra host path mounts can be set" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-control-plane-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "Directory"
}

@test "Control Plane StatefulSet: Extra host path mounts can be set with create=true" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar", "create": "true"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-control-plane-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "DirectoryOrCreate"
}

@test "Control Plane StatefulSet: Two extra host path mounts can be set" {
    template \
        --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar"}' \
        --set-json 'extraHostPathMounts[1]={"name": "baz", "hostPath": "baa"}'
    assert_query_equal '.spec.template.spec.volumes[0].name' \
        "release-name-xrd-control-plane-hostmount-foo"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "bar"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "Directory"
    assert_query_equal '.spec.template.spec.volumes[1].name' \
        "release-name-xrd-control-plane-hostmount-baz"
    assert_query_equal '.spec.template.spec.volumes[1].hostPath.path' "baa"
    assert_query_equal '.spec.template.spec.volumes[1].hostPath.type' "Directory"
}

@test "Control Plane StatefulSet: extraVolumes can be set" {
    template --set 'extraVolumes[0].name=foo'
    assert_query_equal '.spec.template.spec.volumes[0].name' "foo"
}

@test "Control Plane: Image repository must be specified" {
    template_failure_no_set --set 'image.tag=latest'
    assert_error_message_contains "image: repository is required"
}

@test "Control Plane: Image tag must be specified" {
    template_failure_no_set --set 'image.repository=local'
    assert_error_message_contains "image: tag is required"
}

@test "Control Plane StatefulSet: container image is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].image' "local:latest"
}

@test "Control Plane StatefulSet: default container resources are set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].resources.limits' "{}"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "2Gi"
}

@test "Control Plane StatefulSet: container image resources can be set" {
    template --set 'resources.requests.foo=bar' --set 'resources.limits.baz=baa'
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "2Gi"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.foo' "bar"
    assert_query_equal '.spec.template.spec.containers[0].resources.limits.baz' "baa"
}

@test "Control Plane StatefulSet: default memory resource request can be overridden" {
    template --set 'resources.requests.memory=4Gi'
    assert_query_equal '.spec.template.spec.containers[0].resources.limits' "{}"
    assert_query_equal '.spec.template.spec.containers[0].resources.requests.memory' "4Gi"
}

@test "Control Plane StatefulSet: container name is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].name' "main"
}

@test "Control Plane StatefulSet: default container securityContext is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].securityContext.privileged' "true"
}

@test "Control Plane StatefulSet: container securityContext can be set" {
    template --set 'securityContext.privileged=false'
    assert_query_equal '.spec.template.spec.containers[0].securityContext.privileged' "false"
}

@test "Control Plane StatefulSet: default container imagePullPolicy is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "Always"
}

@test "Control Plane StatefulSet: container imagePullPolicy can be set" {
    template --set 'image.pullPolicy=IfNotPresent'
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "IfNotPresent"
}

@test "Control Plane StatefulSet: illegal container imagePullPolicy are rejected" {
    template_failure --set 'image.pullPolicy=foo'
    assert_error_message_contains \
        "image.pullPolicy must be one of the following: \"Always\", \"IfNotPresent\", \"Never\""
}

@test "Control Plane StatefulSet: container tty is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].tty' "true"
}

@test "Control Plane StatefulSet: container stdin is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].stdin' "true"
}

@test "Control Plane StatefulSet: container env vars version is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].env[0].name' "XR_ENV_VARS_VERSION"
    assert_query_equal '.spec.template.spec.containers[0].env[0].value' "1"
}

@test "Control Plane StatefulSet: empty container interface env vars are set by default" {
    template
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' ""
    assert_query_equal '.spec.template.spec.containers[0].env[2].name' "XR_MGMT_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[2].value' ""
}

@test "Control Plane StatefulSet: XR_INTERFACES container env vars is correctly set" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni"}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0"
}

@test "Control Plane StatefulSet: set snoopIpv4Address flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "snoopIpv4Address": true}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,snoop_v4"
}

@test "Control Plane StatefulSet: set snoopIpv4DefaultRoot flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "snoopIpv4DefaultRoute": true}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,snoop_v4_default_route"
}

@test "Control Plane StatefulSet: set snoopIpv6Address flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "snoopIpv6Address": true}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,snoop_v6"
}

@test "Control Plane StatefulSet: set snoopIpv6DefaultRoot flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "snoopIpv6DefaultRoute": true}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,snoop_v6_default_route"
}

@test "Control Plane StatefulSet: set chksum flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "chksum": true}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,chksum"
}

@test "Control Plane StatefulSet: set xrName flag in XR_INTERFACES" {
    template --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "xrName": "foo"}]'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "linux:net1;linux:eth0,xr_name=foo"
}

@test "Control Plane StatefulSet: don't set unsupported flags XR_INTERFACES" {
    template_failure --set-json 'interfaces=[{"type": "multus"}, {"type": "defaultCni", "foo": "bar"}]'
    assert_error_message_contains "Additional property foo is not allowed"
}

@test "Control Plane StatefulSet: XR_MGMT_INTERFACES container env vars is correctly set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "chksum": true}, {"type": "defaultCni"}]'
    assert_query_equal '.spec.template.spec.containers[0].env[2].name' "XR_MGMT_INTERFACES"
    assert_query_equal '.spec.template.spec.containers[0].env[2].value' "linux:net1,chksum;linux:eth0"
}

@test "Control Plane StatefulSet: XR_DISK_USAGE_LIMIT is set if persistence is enabled with default value" {
    template --set 'persistence.enabled=true'
    assert_query_equal '.spec.template.spec.containers[0].env[0].name' "XR_DISK_USAGE_LIMIT"
    assert_query_equal '.spec.template.spec.containers[0].env[0].value' "6G"
}

@test "Control Plane StatefulSet: value of XR_DISK_USAGE_LIMIT can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.size=123kb'
    assert_query_equal '.spec.template.spec.containers[0].env[0].name' "XR_DISK_USAGE_LIMIT"
    assert_query_equal '.spec.template.spec.containers[0].env[0].value' "123K"
}

@test "Control Plane StatefulSet: XR_FIRST_BOOT_CONFIG is set if config is to be applied on first boot" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_FIRST_BOOT_CONFIG"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "/etc/xrd/startup.cfg"
}

@test "Control Plane StatefulSet: XR_EVERY_BOOT_CONFIG is set if ascii config is to be applied on every boot" {
    template --set 'config.ascii=foo' --set 'config.asciiEveryBoot=true'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_EVERY_BOOT_CONFIG"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "/etc/xrd/startup.cfg"
}

@test "Control Plane StatefulSet: XR_ZTP_ENABLE can be set" {
    template --set 'config.ztpEnable=true'
    assert_query_equal '.spec.template.spec.containers[0].env[3].name' "XR_ZTP_ENABLE"
    assert_query_equal '.spec.template.spec.containers[0].env[3].value' "1"
}

@test "Control Plane StatefulSet: XR_ZTP_INI can be set" {
    template --set 'config.ztpEnable=true' --set 'config.ztpIni=foo'
    assert_query_equal '.spec.template.spec.containers[0].env[3].name' "XR_ZTP_ENABLE"
    assert_query_equal '.spec.template.spec.containers[0].env[3].value' "1"
    assert_query_equal '.spec.template.spec.containers[0].env[4].name' "XR_ZTP_ENABLE_WITH_INI"
    assert_query_equal '.spec.template.spec.containers[0].env[4].value' "/etc/xrd/ztp.ini"
}

@test "Control Plane StatefulSet: advanced settings can be used to add env vars" {
    template --set 'advancedSettings.FOO=bar'
    assert_query_equal '.spec.template.spec.containers[0].env[0].name' "FOO"
    assert_query_equal '.spec.template.spec.containers[0].env[0].value' "bar"
}

@test "Control Plane StatefulSet: advanced settings can be used to override default settings" {
    template \
        --set 'config.ascii=foo' \
        --set 'advancedSettings.XR_FIRST_BOOT_CONFIG=foo'
    assert_query_equal '.spec.template.spec.containers[0].env[1].name' "XR_FIRST_BOOT_CONFIG"
    assert_query_equal '.spec.template.spec.containers[0].env[1].value' "foo"
}

@test "Control Plane StatefulSet: default container volumeMounts is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/etc/xrd"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "config"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].readOnly' "true"
}

@test "Control Plane StatefulSet: container volumeMounts for persistence is set if persistence is enabled" {
    template --set 'persistence.enabled=true'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].mountPath' "/xr-storage"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].name' "xr-storage"
}

@test "Control Plane StatefulSet: container volumeMounts for extra host path mounts can be set with default mountPath" {
    template \
        --set 'extraHostPathMounts[0].name=foo' \
        --set 'extraHostPathMounts[0].hostPath=bar'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].mountPath' "bar"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].name' \
        "release-name-xrd-control-plane-hostmount-foo"
}

@test "Control Plane StatefulSet: container volumeMounts for extra host path mounts can be set with specified mountPath" {
    template --set-json 'extraHostPathMounts[0]={"name": "foo", "hostPath": "bar", "mountPath": "baz"}'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].mountPath' "baz"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].name' \
        "release-name-xrd-control-plane-hostmount-foo"
}

@test "Control Plane StatefulSet: extra container volumeMounts can be set" {
    template --set-json 'extraVolumeMounts[0]={"mountPath": "foo", "name": "bar"}'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].mountPath' "foo"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[1].name' "bar"
}

@test "Control Plane StatefulSet: container imagePullSecrets can be set" {
    template --set 'image.pullSecrets[0].name=foo'
    assert_query_equal '.spec.template.spec.imagePullSecrets[0].name' "foo"
}

@test "Control Plane StatefulSet: container nodeSelector can be set" {
    template --set 'nodeSelector.foo=bar'
    assert_query_equal '.spec.template.spec.nodeSelector.foo' "bar"
}

@test "Control Plane StatefulSet: container affinity can be set" {
    template \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=foo' \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=bar'
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key' \
        "foo"
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator' \
        "bar"
}

@test "Control Plane StatefulSet: container tolerations can be set" {
    template --set 'tolerations[0].key=foo'
    assert_query_equal '.spec.template.spec.tolerations[0].key' "foo"
}

@test "Control Plane StatefulSet: default container volumeClaimTemplates is set when persistence is enabled" {
    template --set 'persistence.enabled=true'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.name' "xr-storage"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/name"' "xrd-control-plane"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.accessModes[0]' "ReadWriteOnce"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.resources.requests.storage' "6Gi"
}

@test "Control Plane StatefulSet: volumeClaimTemplates contains set annotations" {
    template --set 'persistence.enabled=true' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa' \
        --set 'persistence.annotations.qux=quux'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.foo' "bar"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.baz' "baa"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.annotations.qux' "quux"
}

@test "Control Plane StatefulSet: volumeClaimTemplates contains set labels" {
    template --set 'persistence.enabled=true' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels.foo' "bar"
    assert_query_equal '.spec.volumeClaimTemplates[0].metadata.labels.baz' "baa"
}

@test "Control Plane StatefulSet: volumeClaimTemplates accessModes can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.accessModes[0]=ReadOnly'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.accessModes[0]' "ReadOnly"
}

@test "Control Plane StatefulSet: volumeClaimTemplates selector can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.selector.matchLabels.release=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.selector.matchLabels.release' "foo"
}

@test "Control Plane StatefulSet: volumeClaimTemplates contains the set storage size" {
    template --set 'persistence.enabled=true' --set 'persistence.size=123kb'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.resources.requests.storage' "123kb"
}

@test "Control Plane StatefulSet: volumeClaimTemplates existing volume can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.existingVolume=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.volumeName' "foo"
}

@test "Control Plane StatefulSet: volumeClaimTemplates storage class can be set" {
    template --set 'persistence.enabled=true' --set 'persistence.storageClass=foo'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.storageClassName' "foo"
}

@test "Control Plane StatefulSet: volumeClaimTemplates data source can be set" {
    template --set 'persistence.enabled=true' \
        --set-json 'persistence.dataSource={"name": "foo", "kind": "bar"}'
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.dataSource.name' "foo"
    assert_query_equal '.spec.volumeClaimTemplates[0].spec.dataSource.kind' "bar"
}