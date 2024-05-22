#!/usr/bin/env bats

load "./utils.bash"

export TEMPLATE_UNDER_TEST="templates/job.yaml"

setup_file () {
    cd "$(host-check_chart_dir)" || exit
    helm dependency update .
}

@test "host-check Job: Name consists of the release name and chart name" {
    template
    assert_query_equal '.metadata.name' "release-name-host-check"
}

@test "host-check Job: Namespace is default" {
    template
    assert_query_equal '.metadata.namespace' "default"
}

@test "host-check Job: Labels are set" {
    template
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "host-check"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "host-check Job: .spec.template labels are set" {
    template
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/name"' "host-check"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.spec.template.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.spec.template.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.spec.template.metadata.labels | has("helm.sh/chart")'
}

@test "host-check Job: hostNetwork is true" {
    template
    assert_query_equal '.spec.template.spec.hostNetwork' "true"
}

@test "host-check Job: /lib/module volume is present" {
    template
    assert_query_equal '.spec.template.spec.volumes[0].name' "modules"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.path' "/lib/modules"
    assert_query_equal '.spec.template.spec.volumes[0].hostPath.type' "DirectoryOrCreate"
}

@test "host-check Job: Pod security context is set" {
    template
    assert_query_equal '.spec.template.spec.securityContext.fsGroup' "2000"
}

@test "host-check: Image repository must be specified" {
    template_failure_no_set --set 'image.tag=latest' \
        --set 'targetPlatforms[0]=xrd-vrouter'
    assert_error_message_contains "image: repository is required"
}

@test "host-check: Image tag must be specified" {
    template_failure_no_set --set 'image.repository=local' \
        --set 'targetPlatforms[0]=xrd-vrouter'
    assert_error_message_contains "image: tag is required"
}

@test "host-check: platform must be specified" {
    template_failure_no_set --set 'image.repository=local' \
        --set 'image.tag=latest'
    assert_error_message_contains "targetPlatforms is required"
}

@test "host-check: platforms must be xrd-vrouter or xrd-control-plane" {
    template_failure_no_set --set 'image.repository=local' \
        --set 'image.tag=latest' --set 'targetPlatforms[0]=foo'
    assert_error_message_contains "targetPlatforms must be xrd-control-plane and/or xrd-vrouter"
}

@test "host-check Job: container image is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].image' "local:latest"
}

@test "host-check Job: default container imagePullPolicy is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "Always"
}

@test "host-check Job: container imagePullPolicy can be set" {
    template --set 'image.pullPolicy=Never'
    assert_query_equal '.spec.template.spec.containers[0].imagePullPolicy' "Never"
}

@test "host-check Job: illegal container imagePullPolicy are rejected" {
    template_failure --set 'image.pullPolicy=foo'
    assert_error_message_contains \
        "image.pullPolicy must be one of the following: \"Always\", \"IfNotPresent\", \"Never\""
}

@test "host-check Job: /lib/modules container volumeMount" {
    template
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].mountPath' "/lib/modules"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].name' "modules"
    assert_query_equal '.spec.template.spec.containers[0].volumeMounts[0].readOnly' "true"
}

@test "host-check Job: platform is vRouter" {
    template --set 'targetPlatforms[0]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].args' "[-p, xrd-vrouter]"
}

@test "host-check Job: platform is Control Plane" {
    template --set 'targetPlatforms[0]=xrd-control-plane'
    assert_query_equal '.spec.template.spec.containers[0].args' "[-p, xrd-control-plane]"
}

@test "host-check Job: both targetPlatforms are specified" {
    template --set 'targetPlatforms[0]=xrd-control-plane' --set 'targetPlatforms[1]=xrd-vrouter'
    assert_query_equal '.spec.template.spec.containers[0].args' "[]"
}

@test "host-check Job: Container securityContext is set" {
    template
    assert_query_equal '.spec.template.spec.containers[0].securityContext.capabilities.drop[0]' "ALL"
    assert_query_equal '.spec.template.spec.containers[0].securityContext.allowPrivilegeEscalation' "false"
    assert_query_equal '.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem' "true"
    assert_query_equal '.spec.template.spec.containers[0].securityContext.runAsNonRoot' "true"
    assert_query_equal '.spec.template.spec.containers[0].securityContext.runAsUser' "1000"
}

@test "host-check Job: container imagePullSecrets can be set" {
    template --set 'image.pullSecrets[0].name=foo'
    assert_query_equal '.spec.template.spec.imagePullSecrets[0].name' "foo"
}

@test "host-check Job: container nodeSelector can be set" {
    template --set 'nodeSelector.foo=bar'
    assert_query_equal '.spec.template.spec.nodeSelector.foo' "bar"
}

@test "host-check Job: backoffLimit is 0" {
    template
    assert_query_equal '.spec.backoffLimit' "0"
}
