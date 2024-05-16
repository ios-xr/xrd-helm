#!/usr/bin/env bats

load "../utils.bash"

export TEMPLATE_UNDER_TEST="templates/job.yaml"

setup_file () {
    cd "$(host-check_chart_dir)" || exit
    helm dependency update .
}

@test "host-check-app Job: Name consists of the release name and chart name" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.metadata.name' "release-name-host-check-app"
}

@test "host-check-app Job: Namespace is default" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.metadata.namespace' "default"
}

@test "host-check-app Job: Labels are set" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "host-check-app"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "host-check-app Job: .spec.template labels are set" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/name"' "host-check-app"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.spec.template.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.spec.template.metadata.labels | has("helm.sh/chart")'
}

@test "host-check-app Job: hostNetwork is true" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.hostNetwork' "true"
}

@test "host-check-app Job: /lib/module volume is present" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.volumes[0].name' "modules"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "/lib/modules"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "DirectoryOrCreate"
}

@test "host-check-app: Image repository must be specified" {
    template_failure_no_set --set 'image.tag=latest' \
        --set 'platforms[0]=xrd-vrouter'
    assert_error_message_contains "image: repository is required"
}

@test "host-check-app: Image tag must be specified" {
    template_failure_no_set --set 'image.repository=local'\
        --set 'platforms[0]=xrd-vrouter'
    assert_error_message_contains "image: tag is required"
}

@test "host-check-app Job: container image is set" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].image' "local:latest"
}

@test "host-check-app Job: default container imagePullPolicy is set" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "IfNotPresent"
}

@test "host-check-app Job: container imagePullPolicy can be set" {
    template --set 'image.pullPolicy=Never' --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "Never"
}

@test "host-check-app Job: illegal container imagePullPolicy are rejected" {
    template_failure --set 'image.pullPolicy=foo' --set 'platforms[0]=xrd-vrouter'
    assert_error_message_contains \
        "image.pullPolicy must be one of the following: \"Always\", \"IfNotPresent\", \"Never\""
}

@test "host-check-app Job: /lib/modules container volumeMount" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/lib/modules"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "modules"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].readOnly' "true"
}

@test "host-check-app Job: platform must be specified" {
    template_failure
    assert_error_message_contains "Platforms must be specified"
}

@test "host-check-app Job: platform is vRouter" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].args' "[-p, xrd-vrouter]"
}

@test "host-check-app Job: platform is Control Plane" {
    template --set 'platforms[0]=xrd-control-plane'
    assert_query_equal '.spec.template.spec.containers[0].args' "[-p, xrd-control-plane]"
}

@test "host-check-app Job: both platforms are specified" {
    template --set 'platforms[0]=xrd-control-plane' --set 'platforms[1]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].args' "[]"
}

@test "host-check-app Job: container imagePullSecrets can be set" {
    template --set 'image.pullSecrets[0].name=foo' --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.imagePullSecrets[0].name' "foo"
}

@test "host-check-app Job: container nodeSelector can be set" {
    template --set 'nodeSelector.foo=bar' --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.nodeSelector.foo' "bar"
}

@test "host-check-app Job: container affinity can be set" {
    template --set 'platforms[0]=xrd-vrouter' \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key=foo' \
        --set 'affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator=bar'
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key' \
        "foo"
    assert_query_equal '.spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator' \
        "bar"
}

@test "host-check-app Job: container tolerations can be set" {
    template --set 'platforms[0]=xrd-vrouter' --set 'tolerations[0].key=foo'
    assert_query_equal '.spec.template.spec.tolerations[0].key' "foo"
}

@test "host-check-app Job: backoffLimit is 0" {
    template --set 'platforms[0]=xrd-vrouter'
    assert_query_equal '.spec.backoffLimit' "0"
}
