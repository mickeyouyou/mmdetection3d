# ! /usr/bin/env bash

export HOST_ARCH="$(uname -m)"
export HOST_OS="$(uname -s)"

IMAGE=reg-ai.chehejia.com/mmdetection3d/mmdetection3d:1.0.3

DOCKER_RUN_CMD="docker run"

USE_GPU_HOST=0

function determine_gpu_use_host() {
    if [[ "${HOST_ARCH}" == "aarch64" ]]; then
        if lsmod | grep -q "^nvgpu"; then
            USE_GPU_HOST=1
        fi
    elif [[ "${HOST_ARCH}" == "x86_64" ]]; then
        if [[ ! -x "$(command -v nvidia-smi)" ]]; then
            echo "No nvidia-smi found. CPU will be used"
        elif [[ -z "$(nvidia-smi)" ]]; then
            echo "No GPU device found. CPU will be used."
        else
            USE_GPU_HOST=1
        fi
    else
        echo "Unsupported CPU architecture: ${HOST_ARCH}"
        exit 1
    fi

    local nv_docker_doc="https://github.com/NVIDIA/nvidia-docker/blob/master/README.md"
    if [[ "${USE_GPU_HOST}" -eq 1 ]]; then
        if [[ -x "$(which nvidia-container-toolkit)" ]]; then
            local docker_version
            docker_version="$(docker version --format '{{.Server.Version}}')"
            if dpkg --compare-versions "${docker_version}" "ge" "19.03"; then
                DOCKER_RUN_CMD="docker run --gpus all"
            else
                echo "Please upgrade to docker-ce 19.03+ to access GPU from container."
                USE_GPU_HOST=0
            fi
        elif [[ -x "$(which nvidia-docker)" ]]; then
            DOCKER_RUN_CMD="nvidia-docker run"
        else
            USE_GPU_HOST=0
            echo "Cannot access GPU from within container. Please install latest Docker" \
                "and NVIDIA Container Toolkit as described by: "
            echo "  ${nv_docker_doc}"
        fi
    fi
}

function run(){
    echo ${DOCKER_RUN_CMD}
    ${DOCKER_RUN_CMD} -itd \
    -v /mnt/NAS/public_datasets/nuscenes-mini:/mmdetection3d/data/nuscenes \
    -v $(pwd):/mmdetection3d \
    -w /mmdetection3d \
    --name "${DOCKER_NAME}" \
    --hostname "${DOCKER_NAME}" \
    ${IMAGE}
}

function main(){
    DOCKER_NAME=mmdetection3d
    determine_gpu_use_host
    run
}
main "$@"
