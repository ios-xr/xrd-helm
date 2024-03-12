#!/usr/bin/env bats

load "utils.bash"

export TEMPLATE_UNDER_TEST="templates/network-attachments.yaml"

setup_file () {
    cd "$(cp_chart_dir)" || exit
    helm dependency update .
}

@test "Control Plane NetworkAttachmentDefinition: Name consists of the release name, template name and index" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.name' "release-name-xrd-control-plane-0"
}

@test "Control Plane NetworkAttachmentDefinition: Name can be overridden with fullnameOverride" {
    template --set-json 'interfaces=[{"type": "multus"}]' --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test-0"
}

@test "Control Plane NetworkAttachmentDefinition: Name can be overridden with nameOverride" {
    template --set-json 'interfaces=[{"type": "multus"}]' --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test-0"
}

@test "Control Plane NetworkAttachmentDefinition: Names have correct index when more than one interface requested" {
    template  \
        --set-json 'interfaces=[{"type": "multus"}, {"type": "multus"}]' \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_multiline_query_equal '.metadata.name' \
        "release-name-xrd-control-plane-0\n---\nrelease-name-xrd-control-plane-1\n---\nrelease-name-xrd-control-plane-2"
}

@test "Control Plane NetworkAttachmentDefinition: Namespace is default" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.namespace' "default"
}

@test "Control Plane NetworkAttachmentDefinition: No annotations are set by default" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_query '.metadata.annotations | not'
}

@test "Control Plane NetworkAttachmentDefinition: Global annotations and commonAnnotations can be added and are correctly merged" {
    template \
        --set-json 'interfaces=[{"type": "multus"}]' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "Control Plane NetworkAttachmentDefinition: Recommended labels are set" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-control-plane"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "Control Plane NetworkAttachmentDefinition: Global labels and commonLabels can be added and are correctly merged" {
    template \
        --set-json 'interfaces=[{"type": "multus"}]' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "Control Plane NetworkAttachmentDefinition: Check default config" {
    template --set-json 'interfaces=[{"type": "multus"}]'
    assert_multiline_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"plugins\": [\n    null\n  ]\n}"
}

@test "Control Plane NetworkAttachmentDefinition: Config can be set for MGMT interfaces" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "config": {"foo": "bar"}}]'
    assert_multiline_query_equal '.spec.config'\
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"plugins\": [\n    {\n      \"foo\": \"bar\"\n    }\n  ]\n}"
}

@test "Control Plane NetworkAttachmentDefinition: Config can be set for interfaces" {
    template --set-json 'interfaces=[{"type": "multus", "config": {"foo": "bar"}}]'
    assert_multiline_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"plugins\": [\n    {\n      \"foo\": \"bar\"\n    }\n  ]\n}"
}

@test "Control Plane NetworkAttachmentDefinition: No interfaces" {
    template_failure
}

@test "Control Plane NetworkAttachmentDefinition: No custom resource created for defaultCNI" {
    template_failure --set-json 'interfaces=[{"type": "defaultCni"}]'
}

@test "Control Plane NetworkAttachmentDefinition: error if multiple defaultCNI requested" {
    template_failure \
        --set-json 'interfaces=[{"type": "defaultCni"}]'  \
        --set-json 'mgmtInterfaces=[{"type": "defaultCni"}]'
    assert_error_message_contains "At most one defaultCni interface can be specified across both interfaces and mgmtInterfaces"
}

@test "Control Plane NetworkAttachmentDefinition: error if unknown interface type is requested" {
    template_failure --set-json 'interfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}

@test "Control Plane NetworkAttachmentDefinition: error if PCI interface type is requested" {
    template_failure --set-json 'interfaces=[{"type": "pci"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}

@test "Control Plane NetworkAttachmentDefinition: error if unknown mgmt interface type is requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}

@test "Control Plane NetworkAttachmentDefinition: error if PCI mgmt interface type is requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "pci"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}