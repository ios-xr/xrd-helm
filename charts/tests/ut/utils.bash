bats_load_library "bats-assert/load.bash"
bats_load_library "bats-support/load.bash"

chart_dir () {
    readlink -f "${BATS_TEST_DIRNAME}/../.."
}

template () {
    echo -n "# Run 'helm template'"
    [ "$#" -eq 0 ] && echo "" || echo " with arguments: $*"

    run -0 helm template . \
        --set 'xrdHelm.image.repository=ecr/xrd-helm' \
        --set 'xrd.enabled=false' \
        -s "$TEMPLATE_UNDER_TEST" \
        "$@"

    # shellcheck disable=SC2154
    echo "$output"

    echo "# Assert output passes yamllint"
    echo "$output" | yamllint -d '{extends: default, rules: {indentation: {indent-sequences: false}, line-length: disable}}' -

    echo "# Assert output passes Kubeconform"
    echo "$output" | kubeconform -strict
}

assert_query () {
    assert "$(echo "$output" | yq -e "$1")" "$2"
}

assert_query_equal () {
    assert_equal "$(echo "$output" | yq -e "$1")" "$2"
}
