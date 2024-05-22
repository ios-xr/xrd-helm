#!/usr/bin/env bats

load "./utils.bash"

export TEMPLATE_UNDER_TEST="templates/network-attachments.yaml"

setup_file () {
    cd "$(vrouter_chart_dir)" || exit
    helm dependency update .
}

@test "vRouter NetworkAttachmentDefinition: Name consists of the release name, template name and index" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.name' "release-name-xrd-vrouter-0"
}

@test "vRouter NetworkAttachmentDefinition: Name can be overridden with fullnameOverride" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition: Name can be overridden with nameOverride" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition: Namespace is default" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.namespace' "default"
}

@test "vRouter NetworkAttachmentDefinition: No annotations are set by default" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query '.metadata.annotations | not'
}

@test "vRouter NetworkAttachmentDefinition: Global annotations and commonAnnotations can be added and are correctly merged" {
    template \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition: Recommended labels are set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter NetworkAttachmentDefinition: Global labels and commonLabels can be added and are correctly merged" {
    template \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition: Check default config" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"plugins\": [\n    null\n  ]\n}"
}

@test "vRouter NetworkAttachmentDefinition: Config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "config": {"foo": "bar"}}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"plugins\": [\n    {\n      \"foo\": \"bar\"\n    }\n  ]\n}"
}

@test "vRouter NetworkAttachmentDefinition: No interfaces" {
    template_failure --set-json 'interfaces=[{"type": "pci"}]'
}

@test "vRouter NetworkAttachmentDefinition: No custom resource created for defaultCNI" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "defaultCni"}]'
}

@test "vRouter NetworkAttachmentDefinition: Error if multiple defaultCNI requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "defaultCni"}, {"type": "defaultCni"}]'
    assert_error_message_contains \
        "At most one defaultCni interface can be specified across both interfaces and mgmtInterfaces"
}

@test "vRouter NetworkAttachmentDefinition: Interface cannot be type defaultCNI" {
    template_failure --set-json 'interfaces=[{"type": "defaultCni"}]'
    assert_error_message_contains "type must be one of the following: \"pci\""
}

@test "vRouter NetworkAttachmentDefinition: Interface cannot be type multus" {
    template_failure --set-json 'interfaces=[{"type": "multus"}]'
    assert_error_message_contains "type must be one of the following: \"pci\""
}

@test "vRouter NetworkAttachmentDefinition: MGMT interface cannot be type pci" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "pci"}]'
    assert_error_message_contains "type must be one of the following: \"defaultCni\", \"multus\""
}

@test "vRouter NetworkAttachmentDefinition: At most one MGMT interface can be specified" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "multus"}, {"type": "multus"}]'
    assert_error_message_contains "Only one management interface can be specified on XRd vRouter"
}

@test "vRouter NetworkAttachmentDefinition: error if unknown interface type is requested" {
    template_failure --set-json 'interfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"pci\""
}

@test "vRouter NetworkAttachmentDefinition: error if unknown mgmt interface type is requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}

@test "vRouter NetworkAttachmentDefinition: error if PCI mgmt interface is requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "pci"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\""
}