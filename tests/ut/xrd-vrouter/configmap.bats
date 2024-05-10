#!/usr/bin/env bats

load "../utils.bash"

export TEMPLATE_UNDER_TEST="templates/config-configmap.yaml"

setup_file () {
    cd "$(vrouter_chart_dir)" || exit
    helm dependency update .
}

@test "vRouter ConfigMap: No ConfigMap is generated if no config is set" {
    template_failure
    assert_error_message_contains "AAAcould not find template templates/config-configmap.yaml in chart"
}

@test "vRouter ConfigMap: Name consists of the release name and the template name" {
    template --set 'config.script=foo'
    assert_query_equal '.metadata.name' "release-name-xrd-vrouter-config"
}

@test "vRouter ConfigMap: Name can be overridden with fullnameOverride" {
    template --set 'fullnameOverride=xrd-test' --set 'config.script=foo'
    assert_query_equal '.metadata.name' "xrd-test-config"
}

@test "vRouter ConfigMap: Name can be overridden with nameOverride" {
    template --set 'nameOverride=xrd-test' --set 'config.script=foo'
    assert_query_equal '.metadata.name' "release-name-xrd-test-config"
}

@test "vRouter ConfigMap: Namespace is default" {
    template --set 'config.script=foo'
    assert_query_equal '.metadata.namespace' "default"
}

@test "vRouter ConfigMap: No annotations are set by default" {
    template --set 'config.script=foo'
    assert_query '.metadata.annotations | not'
}

@test "vRouter ConfigMap: Global annotations and commonAnnotations can be added and are merged with expected precedence" {
    template \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa' \
        --set 'commonAnnotations.foo=qux' \
        --set 'config.script=foo'
    assert_query_equal '.metadata.annotations.foo' "qux"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "vRouter ConfigMap: Recommended labels are set" {
    template --set 'config.script=foo'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter ConfigMap: Global labels and commonLabels can be added and are merged with the expected precedence" {
    template \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'\
        --set 'commonLabels.foo=qux' \
        --set 'config.script=foo'
    assert_query_equal '.metadata.labels.foo' "qux"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "vRouter ConfigMap: Startup config can be set using username and password" {
    template --set 'config.username=foo' --set 'config.password=bar'
    assert_query_equal '.data."startup.cfg"' \
        "username foo\n group root-lr\n group cisco-support\n password bar\n!"
}

@test "vRouter ConfigMap: password must be set if username is" {
    template_failure --set 'config.username=foo'
    assert_error_message_contains "password must be specified if username specified"
}

@test "vRouter ConfigMap: username must be set if password is" {
    template_failure --set 'config.password=foo'
    assert_error_message_contains "username must be specified if password specified"
}

@test "vRouter ConfigMap: Startup config can be set using ascii" {
    template --set 'config.ascii=foo'
    assert_query_equal '.data."startup.cfg"' "foo"
}

@test "vRouter ConfigMap: Startup script can be set" {
    template --set 'config.script=foo'
    assert_query_equal '.data."startup.sh"' "foo"
}

@test "vRouter ConfigMap: ztpIni can't be set without being enabled" {
    template_failure --set 'config.ztpIni=foo'
    assert_error_message_contains "ztpIni can only be specified if ztpEnable is set to true"
}

@test "vRouter ConfigMap: ztpIni can be set if it is enabled" {
    template --set 'config.ztpIni=foo' --set 'config.ztpEnable=true'
    assert_query_equal '.data."ztp.ini"' "foo"
}

