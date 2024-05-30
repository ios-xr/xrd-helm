load "../utils.bash"

cp_chart_dir () {
    readlink -f "${BATS_TEST_DIRNAME}/../../../charts/xrd-control-plane"
}

template () {
    template_no_set \
        --set image.repository=local \
        --set image.tag=latest \
        "$@"
}

template_failure () {
    template_failure_no_set \
        --set image.repository=local \
        --set image.tag=latest \
        "$@"
}
