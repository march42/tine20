#!/usr/bin/env bash
set -e

function build_image() {
    local target=$1
    local image=$2
    local base_image=$3
    local source_image=$4
    local build_image=$5
    local built_image=$6
    local alpine_php_repository_branch=$7
    local alpine_php_repository_repository=$8
    local alpine_php_package=$9

    echo "$0: building target ${target} as ${image} ..."

    local cmd="docker build ${DOCKER_ADDITIONAL_BUILD_ARGS}"
    cmd+=" --target ${target}"
    cmd+=" --tag ${image}"
    cmd+=" --file ${target}.Dockerfile"
    cmd+=" --build-arg BUILDKIT_INLINE_CACHE=1"
    cmd+=" --build-arg ALPINE_PHP_REPOSITORY_BRANCH=${alpine_php_repository_branch}"
    cmd+=" --build-arg ALPINE_PHP_REPOSITORY_REPOSITORY=${alpine_php_repository_repository}"
    cmd+=" --build-arg ALPINE_PHP_PACKAGE=${alpine_php_package}"

    # image locations
    cmd+=" --build-arg BASE_IMAGE=${base_image}"
    cmd+=" --build-arg SOURCE_IMAGE=${source_image}"
    cmd+=" --build-arg BUILD_IMAGE=${build_image}"
    cmd+=" --build-arg BUILT_IMAGE=${built_image}"

    cmd+=" --build-arg CACHE_BUST=$(date +%s)"

    # configured by environment variables
    cmd+=" --build-arg CUSTOM_APP_VENDOR"
    cmd+=" --build-arg CUSTOM_APP_NAME"
    cmd+=" --build-arg CUSTOM_APP_GIT_URL"
    cmd+=" --build-arg CUSTOM_APP_VERSION"

    for cache_image in "${cache_from[@]}"; do
        echo "0: using cache from ${cache_image}"
        cmd+=" --cache-from ${cache_image}"
        docker pull "${cache_image}" || echo "$0: failed to pull cache image -- ${cache_image}"
    done

    cmd+=" ../../"

    ${cmd}

    echo "$0: ... building target ${target}. done"
}

function build_image_and_dependencies() {
    local target=$1
    local image=$2
    local base_image=$3
    local source_image=$4
    local build_image=$5
    local built_image=$6
    local alpine_php_repository_branch=$7
    local alpine_php_repository_repository=$8
    local alpine_php_package=$9

    echo $@

    local tmp_images=()

    echo "$0: building ${target} image as ${image} ..."

    if [ 'base' == "${target}" ]; then
        build_image "${target}" "${image}" '' '' '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
    else
        if [[ -z "${base_image}" ]]; then
            echo "$0: base_image not provided ..."

            base_image=base:tmp-$(uuidgen)
            tmp_images+=(${base_image})

            build_image "base" "${base_image}" '' '' '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
        fi

        if [ 'source' == "${target}" ] || [ 'dev' == "${target}" ]; then
            build_image "${target}" "${image}" "${base_image}" '' '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
        else
            if [[ -z "${source_image}" ]]; then
                echo "$0: source_image not provided ..."

                source_image=source:tmp-$(uuidgen)
                tmp_images+=(${source_image})

                build_image "source" "${source_image}" "${base_image}" '' '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
            fi

            if [ 'build' == "${target}" ] || [ 'test-source' == "${target}" ]; then
                build_image "${target}" "${image}" "${base_image}" "${source_image}" '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
            else
                if [[ -z "${build_image}" ]]; then
                    echo "$0: build_image not provided ..."

                    build_image=build:tmp-$(uuidgen)
                    tmp_images+=(${build_image})

                    build_image "build" "${build_image}" "${base_image}" "${source_image}" '' '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
                fi

                if [ 'built' == "${target}" ] || [ 'test-built' != "${target}" ]; then
                    if [ 'built' != "${target}" ]; then
                        echo "$0: unknown target image -- ${target}"
                        echo "$0: building built target/image instead"
                    fi

                    build_image "${target}" "${image}" "${base_image}" "${source_image}" "${build_image}" '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
                else
                    if [[ -z "${built_image}" ]]; then
                        echo "$0: built_image not provided ..."

                        built_image=built:tmp-$(uuidgen)
                        tmp_images+=(${built_image})

                        build_image "built" "${built_image}" "${base_image}" "${source_image}" "${build_image}" '' "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
                    fi

                    if [ 'test-built' == "${target}" ]; then
                        build_image "${target}" "${image}" "${base_image}" "${source_image}" "${build_image}" "${built_image}" "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"
                    else
                        echo "$0: unreachable state -- unknown target image -- ${target}"
                        exit 1;
                    fi
                fi
            fi
        fi
    fi

    for tmp_image in "${tmp_images[@]}"; do
        echo "$0: deleting tmp image: ${tmp_image}"

        docker image rm "${tmp_image}"
    done

    echo "$0: ... building ${target} image. done"

    if [[ $push == true ]]; then
        echo "$0: pushing image ${image} ..."
        docker push ${image}
        echo "$0: ... pushing image ${image}. done"
    fi
}

function use_old_image_if_nothing_has_changed() {
    local image=$1
    local old_image=$2

    echo "$0: checking if the build produced a new image ..."

    if docker pull -q "${old_image}"; then
        local new_layer=$(docker inspect --format "{{range .RootFS.Layers}}{{.}}{{end}}" ${image})
        local old_layer=$(docker inspect --format "{{range .RootFS.Layers}}{{.}}{{end}}" ${image})
        if [ "${new_layer}" == "${old_layer}" ]; then
            echo "$0: build produced no new layers. Reusing old image $old_image ..."
            docker tag "${old_image}" "${image}"
        else
            echo "$0: build produced new layers"
        fi
    else
        echo "$0: failed to pull old image, it might not exist -- ${old_image}"
    fi

    echo "$0: ... checking if the build produced a new image. done"
}

function make_image() {
    local target=$1
    local image=${2:-${image:-"${registry}${name:-${target}}:${tag}"}}
    local base_image=$3
    local source_image=$4
    local build_image=$5
    local built_image=$6
    local php_version=$7

    local alpine_php_repository_branch=
    local alpine_php_repository_repository=
    local alpine_php_package=

    case "${php_version}" in
        7.3)
            alpine_php_repository_branch=v3.12
            alpine_php_repository_repository=main
            alpine_php_package=php7
            ;;
        7.4)
            alpine_php_repository_branch=edge
            alpine_php_repository_repository=main
            alpine_php_package=php7
            ;;
        8.0)
            alpine_php_repository_branch=edge
            alpine_php_repository_repository=community
            alpine_php_package=php8
            ;;
        *)
            echo "$0: unsupported php version -- ${php_version}!"
            exit 1
            ;;
    esac

    build_image_and_dependencies "${target}" "${image}" "${base_image}" "${source_image}" "${build_image}" "${built_image}" "${alpine_php_repository_branch}" "${alpine_php_repository_repository}" "${alpine_php_package}"

    local old_image=${arr[0]}
    if [ -n "${old_image}" ] && [ 'true' == "${use_old_image}" ]; then
        use_old_image_if_nothing_has_changed "${image}" "${old_image}"
    fi

    if [ 'true' == "${push}" ]; then
        docker push "${image}"
    fi
}

function help() {
    echo "$0 [<opts>] <task>"
    echo 'tasks:'
    echo '  base'
    echo '  dev'
    echo '  source'
    echo '  test-source'
    echo '  build'
    echo '  built'
    echo '  test-built'
    echo 'options:'
    echo '  -r registry: default is ""'
    echo '  -t tag: default is latest'
    echo '  -p push: whether to push'
    echo '  -n name: overwrite image name'
    echo '  -c cache_image: cache images to use; -c image:1 -c img:2'
    echo '  -i image: overwrite image name; default [<repository>/]>name>:<tag>'
    echo '  -u use old image if nothing has changed; default is false'
    echo '  -h help'
    echo 'env:'
    echo '  DOCKER_ADDITIONAL_BUILD_ARGS: add args to docker build'
    echo '  PHP_VERSION: set php version; default is 7.3'
    echo '  BASE_IMAGE: set base image'
    echo '  SOURCE_IMAGE: set source image'
    echo '  BUILD_IMAGE: set build image'
    echo '  BUILT_IMAGE set built image'
    echo '  CUSTOM_APP_VENDOR: composer vendor'
    echo '  CUSTOM_APP_NAME: composer app name'
    echo '  CUSTOM_APP_GIT_URL: composer git repo'
    echo '  CUSTOM_APP_VERSION: composer git repo version'
}

cd "$(dirname "$0")"

registry=''
tag='latest'
push='false'
use_old_image='false'
name=''
cache_from=()
PHP_VERSION=${PHP_VERSION:-'7.3'}

while getopts i:r:t:c:n:uph opt
do
    case ${opt} in
        t) tag="${OPTARG}";;
        r) registry="${OPTARG}/";;
        p) push='true';;
        n) name="${OPTARG}";;
        i) image="${OPTARG}";;
        u) use_old_image=true;;
        c) cache_from+=("${OPTARG}");;
        h)
            help
            exit 0
            ;;
    esac
done

shift $(($OPTIND - 1))

case ${1} in
    base) make_image 'base' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    dev) make_image 'dev' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    source) make_image 'source' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    test-source) make_image 'test-source' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    build) make_image 'build' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    built) make_image 'built' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    test-built) make_image 'test-built' '' "${BASE_IMAGE}" "${SOURCE_IMAGE}" "${BUILD_IMAGE}" "${BUILT_IMAGE}" "${PHP_VERSION}";;
    '')
        help
        exit 0
        ;;
    *)
        echo "$0: unknown task -- ${1}"
        help
        exit 1
        ;;
esac