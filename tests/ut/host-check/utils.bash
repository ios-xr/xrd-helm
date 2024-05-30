load "../utils.bash"

host-check_chart_dir () {
    readlink -f "${BATS_TEST_DIRNAME}/../../../charts/host-check"
}

template () {
    template_no_set \
        --set image.repository=local \
        --set image.tag=latest \
        --set 'targetPlatforms[0]=xrd-vrouter' \
        "$@"
}

template_failure () {
    template_failure_no_set \
        --set image.repository=local \
        --set image.tag=latest \
        --set 'targetPlatforms[0]=xrd-vrouter' \
        "$@"
}
