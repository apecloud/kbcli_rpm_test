#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
    local OS
    local TAG_NAME
    local CLI_NAME
    local ROOT_DIR
    local WORK_SPACE

    parse_command_line "$@"

    make_rpm_repo
}

parse_command_line() {
    while :; do
        case "${1:-}" in
            -os|--os)
                if [[ -n "${2:-}" ]]; then
                    OS="$2"
                    shift
                fi
                ;;
            -tn|--tag-name)
                if [[ -n "${2:-}" ]]; then
                    TAG_NAME="$2"
                    shift
                fi
                ;;
            -cn|--cli-name)
                if [[ -n "${2:-}" ]]; then
                    CLI_NAME="$2"
                    shift
                fi
                ;;
            -rd|--root-dir)
                if [[ -n "${2:-}" ]]; then
                    ROOT_DIR="$2"
                    shift
                fi
                ;;
            -wp|--work-space)
                if [[ -n "${2:-}" ]]; then
                    WORK_SPACE="$2"
                    shift
                fi
                ;;
            *)
                break
                ;;
        esac

        shift
    done
}

make_rpm_repo() {
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
      libbtrfs-dev \
      libdevmapper-dev
    sudo apt-get install -y rpm build-essential
    sudo apt-get install -y createrepo-c
    cd $OS
    curl -O -L https://github.com/apecloud/kbcli/releases/download/$TAG_NAME/$CLI_NAME-$OS-$TAG_NAME.tar.gz

    CLI_FILENAME=$CLI_NAME-$OS-$TAG_NAME
    echo "CLI_FILENAME: $CLI_FILENAME"
    mkdir -p rpmbuild
    mkdir -p rpmbuild/SOURCES
    mkdir -p rpmbuild/SPECS
    mkdir -p rpmbuild/BUILD
    mkdir -p rpmbuild/RPMS
    mkdir -p rpmbuild/SRPMS

    mv "$CLI_FILENAME.tar.gz" rpmbuild/SOURCES/
    cp "$WORK_SPACE/.github/utils/kbcli.spec" rpmbuild/SPECS/
    mv rpmbuild/SPECS/kbcli.spec rpmbuild/SPECS/kbcli-$TAG_NAME.spec
    sed -i "s/^Source0:.*/Source0: $CLI_FILENAME.tar.gz/" rpmbuild/SPECS/kbcli-$TAG_NAME.spec
    sed -i "s/^Version:.*/Version: $TAG_NAME/" rpmbuild/SPECS/kbcli-$TAG_NAME.spec
    sed -i "s/^%setup.*/%setup -q -n $OS/" rpmbuild/SPECS/kbcli-$TAG_NAME.spec

    mv rpmbuild "$ROOT_DIR/"

    if [ "$OS" == "linux-amd64" ]; then
        target_arch='x86_64'
    else
        target_arch='aarch64'
    fi

    rpmbuild --target "$target_arch" -ba "$ROOT_DIR/rpmbuild/SPECS/kbcli-$TAG_NAME.spec"

    mv "$ROOT_DIR/rpmbuild/RPMS/$target_arch/$CLI_NAME-$TAG_NAME-1.$target_arch.rpm" ./
    createrepo_c --update ./
}

main "$@"
