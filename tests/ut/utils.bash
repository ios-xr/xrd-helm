bats_load_library "bats-assert/load.bash"
bats_load_library "bats-support/load.bash"

template_no_set () {
    echo -n "# Run 'helm template'"
    [ "$#" -eq 0 ] && echo "" || echo " with arguments: $*"

    run -0 helm template . \
        -s "$TEMPLATE_UNDER_TEST" \
        "$@"

    # shellcheck disable=SC2154
    echo "$output"

    echo "# Assert output passes yamllint"
    echo "$output" | yamllint -d '{extends: default, rules: {indentation: {indent-sequences: false}, line-length: disable}}' -

    echo "# Assert output passes Kubeconform"
    echo "$output" | kubeconform -strict -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/v0.0.12/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
}

template_failure_no_set () {
    echo -n "# Run 'helm template'"
    [ "$#" -eq 0 ] && echo "" || echo " with arguments: $*"
    echo "# (Expecting failure)"

    run helm template . \
        -s "$TEMPLATE_UNDER_TEST" \
        "$@"

    [ "$status" -eq 1 ]

    # shellcheck disable=SC2154
    echo "$output"
}

assert_query () {
    assert "$(echo "$output" | yq -e "$1")"
}

assert_query_equal () {
    assert_equal "$(echo "$output" | yq -e "$1")" "$(echo -e "$2")"
}

assert_fields_equal () {
    assert_equal "$(echo "$output" | yq -e "$1")" "$(echo "$output" | yq -e "$2")"
}

assert_error_message_contains () {
    assert_output --partial "$1"
}
