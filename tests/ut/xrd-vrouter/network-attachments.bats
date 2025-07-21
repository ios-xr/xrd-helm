#!/usr/bin/env bats

load "./utils.bash"

export TEMPLATE_UNDER_TEST="templates/network-attachments.yaml"

setup_file () {
    cd "$(vrouter_chart_dir)" || exit
    helm dependency update .
}

@test "vRouter NetworkAttachmentDefinition (multus): Name consists of the release name, template name and index" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.name' "release-name-xrd-vrouter-0"
}

@test "vRouter NetworkAttachmentDefinition (multus): Name can be overridden with fullnameOverride" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition (multus): Name can be overridden with nameOverride" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition (multus): Namespace is default" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.namespace' "default"
}

@test "vRouter NetworkAttachmentDefinition (multus): No annotations are set by default" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query '.metadata.annotations | not'
}

@test "vRouter NetworkAttachmentDefinition (multus): Global annotations and commonAnnotations can be added and are correctly merged" {
    template \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition (multus): Recommended labels are set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter NetworkAttachmentDefinition (multus): Global labels and commonLabels can be added and are correctly merged" {
    template \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition (multus): Check default config" {
    template --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      null\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (multus): Config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "config": {"foo": "bar"}}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"foo\": \"bar\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Name consists of the release name, template name and index" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]'
    assert_query_equal '.metadata.name' "release-name-xrd-vrouter-0"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Name can be overridden with fullnameOverride" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]' \
        --set 'fullnameOverride=xrd-test'
    assert_query_equal '.metadata.name' "xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Name can be overridden with nameOverride" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]' \
        --set 'nameOverride=xrd-test'
    assert_query_equal '.metadata.name' "release-name-xrd-test-0"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Namespace is default" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]'
    assert_query_equal '.metadata.namespace' "default"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Default annotations are set" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]'
    assert_query_equal '.metadata.annotations."k8s.v1.cni.cncf.io/resourceName"' "foo"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Global annotations and commonAnnotations can be added and are correctly merged" {
    template \
        --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]' \
        --set 'global.annotations.foo=bar' \
        --set 'commonAnnotations.baz=baa'
    assert_query_equal '.metadata.annotations."k8s.v1.cni.cncf.io/resourceName"' "foo"
    assert_query_equal '.metadata.annotations.foo' "bar"
    assert_query_equal '.metadata.annotations.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Recommended labels are set" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]'
    assert_query_equal '.metadata.labels."app.kubernetes.io/name"' "xrd-vrouter"
    assert_query_equal '.metadata.labels."app.kubernetes.io/instance"' "release-name"
    assert_query_equal '.metadata.labels."app.kubernetes.io/managed-by"' "Helm"
    assert_query '.metadata.labels | has("app.kubernetes.io/version")'
    assert_query '.metadata.labels | has("helm.sh/chart")'
}

@test "vRouter NetworkAttachmentDefinition (sriov): Global labels and commonLabels can be added and are correctly merged" {
    template \
        --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]' \
        --set 'global.labels.foo=bar' \
        --set 'commonLabels.baz=baa'
    assert_query_equal '.metadata.labels.foo' "bar"
    assert_query_equal '.metadata.labels.baz' "baa"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Config can be set" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"type\": \"sriov\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition: multiple sriov interfaces can be created together" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}},{"type": "sriov", "resource": "bar", "config": {"type": "sriov"}}]'
    assert_query_equal '.metadata.name' \
        "release-name-xrd-vrouter-0\n---\nrelease-name-xrd-vrouter-1"
}

@test "vRouter NetworkAttachmentDefinition: sriov interfaces and multus mgmt interfaces can be created together" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}}]' \
        --set-json 'mgmtInterfaces=[{"type": "multus"}]'
    assert_query_equal '.metadata.name' \
        "release-name-xrd-vrouter-0\n---\nrelease-name-xrd-vrouter-1"
}

@test "vRouter NetworkAttachmentDefinition: No custom resource created for defaultCNI mgmt interfaces" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "defaultCni"}]'
}

@test "vRouter NetworkAttachmentDefinition: No custom resource created for pci interfaces" {
    template_failure --set-json 'interfaces=[{"type": "pci"}]'
}

@test "vRouter NetworkAttachmentDefinition: Interface cannot be type defaultCNI" {
    template_failure --set-json 'interfaces=[{"type": "defaultCni"}]'
    assert_error_message_contains "type must be one of the following: \"pci\", \"sriov\""
}

@test "vRouter NetworkAttachmentDefinition: Interface cannot be type multus" {
    template_failure --set-json 'interfaces=[{"type": "multus"}]'
    assert_error_message_contains "type must be one of the following: \"pci\", \"sriov\""
}

@test "vRouter NetworkAttachmentDefinition: MGMT interface cannot be type pci" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "pci"}]'
    assert_error_message_contains "type must be one of the following: \"defaultCni\", \"multus\", \"sriov\""
}

@test "vRouter NetworkAttachmentDefinition: Error if multiple defaultCNI requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "defaultCni"}, {"type": "defaultCni"}]'
    assert_error_message_contains \
        "At most one defaultCni interface can be specified across both interfaces and mgmtInterfaces"
}

@test "vRouter NetworkAttachmentDefinition: At most one MGMT interface can be specified" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "multus"}, {"type": "multus"}]'
    assert_error_message_contains "Only one management interface can be specified on XRd vRouter"
}

@test "vRouter NetworkAttachmentDefinition: error if unknown interface type is requested" {
    template_failure --set-json 'interfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"pci\", \"sriov\""
}

@test "vRouter NetworkAttachmentDefinition: error if unknown mgmt interface type is requested" {
    template_failure --set-json 'mgmtInterfaces=[{"type": "foo"}]'
    assert_error_message_contains "must be one of the following: \"defaultCni\", \"multus\", \"sriov\""
}

@test "vRouter NetworkAttachmentDefinition (sriov): Additional CNI config can be set" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}, "additionalCNIConfig": [{"bar": "baz"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"type\": \"sriov\"\n      },\n      {\n        \"bar\": \"baz\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (sriov): Multiple additional CNI config can be set" {
    template --set-json 'interfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}, "additionalCNIConfig": [{"bar": "baz"}, {"qux": "quux"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"type\": \"sriov\"\n      },\n      {\n        \"bar\": \"baz\"\n      },\n      {\n        \"qux\": \"quux\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (sriov mgmt): Additional CNI config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}, "additionalCNIConfig": [{"bar": "baz"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"type\": \"sriov\"\n      },\n      {\n        \"bar\": \"baz\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (sriov mgmt): Multiple additional CNI config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "sriov", "resource": "foo", "config": {"type": "sriov"}, "additionalCNIConfig": [{"bar": "baz"}, {"qux": "quux"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"type\": \"sriov\"\n      },\n      {\n        \"bar\": \"baz\"\n      },\n      {\n        \"qux\": \"quux\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (multus): Additional CNI config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "config": {"foo": "bar"}, "additionalCNIConfig": [{"baz": "qux"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"foo\": \"bar\"\n      },\n      {\n        \"baz\": \"qux\"\n      }\n    ]\n}"
}

@test "vRouter NetworkAttachmentDefinition (multus): Multiple additional CNI config can be set" {
    template --set-json 'mgmtInterfaces=[{"type": "multus", "config": {"foo": "bar"}, "additionalCNIConfig": [{"baz": "qux"}, {"quux": "corge"}]}]'
    assert_query_equal '.spec.config' \
        "{\n  \"cniVersion\": \"0.3.1\",\n  \"name\": \"release-name-xrd-vrouter-0\",\n  \"plugins\":\n    [\n      {\n        \"foo\": \"bar\"\n      },\n      {\n        \"baz\": \"qux\"\n      },\n      {\n        \"quux\": \"corge\"\n      }\n    ]\n}"
}