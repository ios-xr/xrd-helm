#!/usr/bin/env bats

load "utils.bash"

export TEMPLATE_UNDER_TEST="xrd-control-plane/templates/config-configmap.yaml"

setup_file () {
    cd "$(chart_dir)" || exit
    helm dependency update .
}

@test "ConfigMap name consists of the release name and the chart name" {
    template
    assert_query_equal '.metadata.name' "xrd-ha-app-release-name"
}

@test "Namespace is default" {
    template
    assert_query_equal '.metadata.namespace' "default"
}

@test "Recommended labels are set" {
    template
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-ha-app"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "Global labels can be added" {
    template --set 'global.labels.foo=bar' --set 'global.labels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "Config can be set" {
    template --set 'haApp.config=foo'
    assert_query_equal '.data.config' "foo"
}

@test "Config is template-able" {
    template --set-json 'haApp.config="{{ .Release.Name }}-config"'
    assert_query_equal '.data.config' "release-name-config"
}
