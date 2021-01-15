#!/bin/bash

export STORAGE_DRIVER=vfs

image_repo=quay.io/fedoraci/fedora
arches=(aarch64 ppc64le x86_64 s390x)

eln_build_name=$(koji -q latest-build --type=image eln-updates-candidate Fedora-Container-Base | awk '{print $1}')
if [[ -n ${eln_build_name} ]]; then
    # Download the image
    work_dir=$(mktemp -d)
    pushd ${work_dir} &> /dev/null
    koji download-build --type=image  ${eln_build_name}

    # Import the images
    for arch in "${arches[@]}"; do
	image="${eln_build_name}.${arch}.tar.xz"
	if [[ -f "$image" ]]; then
            xz -d "${image}"
            skopeo copy --dest-creds="$USERNAME:$PASSWORD" docker-archive:${eln_build_name}.${arch}.tar "docker://$image_repo:eln-${arch}"
	else
	    echo "WARNING: Image ${eln_build_name} for ${arch} not found"
	fi
    done

    # Create and upload multi-arch manifest
    buildah rmi "$image_repo:eln"  # jic the manifest already exists
    buildah manifest create "$image_repo:eln" "${arches[@]/#/docker://$image_repo:eln-}"
    buildah manifest push --creds="$USERNAME:$PASSWORD" "$image_repo:eln" "docker://$image_repo:eln" --all

    popd &> /dev/null

    printf "Removing temporary directory\n"
    rm -rf $work_dir
fi
