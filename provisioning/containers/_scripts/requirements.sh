#!/usr/bin/env bash
set -Eeuo pipefail

function add_system_user_group() {
    if [ $(cat /etc/group | grep "${WORKER_OWNER_GID}" -c) -eq 0 ]; then
        groupadd \
            --gid "${WORKER_OWNER_GID}" \
            worker
    fi

    useradd \
        --gid ${WORKER_OWNER_GID} \
        --home-dir=/var/www \
        --no-create-home \
        --no-user-group \
        --non-unique \
        --shell /usr/sbin/nologin \
        --uid ${WORKER_OWNER_UID} \
        worker
}

function clear_package_management_system_cache() {
    # Remove packages installed with apt except for tini
    apt-get remove --assume-yes build-essential gcc build-essential wget
    apt-get autoremove --assume-yes
    apt-get purge --assume-yes
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}

function create_log_files_when_non_existing() {
    prefix="${1}"
    local prefix="${1}"

    if [ -z "${prefix}" ];
    then
        printf 'A %s is expected (%s).%s' 'non empty string' 'log file' $'\n'

        return 1
    fi

    mkdir \
      --verbose \
      --parents \
      "/var/www/${WORKER}/var/log"

    if [ ! -e "/var/www/${WORKER}/var/log/${prefix}.log" ];
    then

        touch "/var/www/${WORKER}/var/log/${prefix}.log"

        printf '%s "%s".%s' 'Created file located at' "/var/www/${WORKER}/var/log/${prefix}.log" $'\n'

    fi

    if [ ! -e "/var/www/${WORKER}/var/log/${prefix}.error.log" ];
    then

        touch "/var/www/${WORKER}/var/log/${prefix}.error.log"

        printf '%s "%s".%s' 'Created file located at' "/var/www/${WORKER}/var/log/${prefix}.error.log" $'\n'

    fi
}

function install_dockerize() {
    local dockerize_version
    dockerize_version='v0.6.1'

    # [dockerize's git repository](https://github.com/jwilder/dockerize)
    local releases_url
    releases_url="https://github.com/jwilder/dockerize/releases"

    local archive
    archive="dockerize-linux-amd64-${dockerize_version}.tar.gz"

    wget "${releases_url}/download/${dockerize_version}/${archive}" -O "${archive}"

    tar -C /usr/local/bin -xzv --file "${archive}"

    rm "${archive}"
}

function install_process_manager() {
    local _asdf_dir
    _asdf_dir="${1}"

    if [ -z "${_asdf_dir}" ];
    then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '1st argument' 'extendable version manager (asdf dir)' $'\n'

        return 1

    else

        rm -rf "${_asdf_dir}"

    fi

    export ASDF_DIR="${_asdf_dir}"
    echo "${ASDF_DIR}"

    git config --global advice.detachedHead false

    echo git clone https://github.com/asdf-vm/asdf.git --branch v0.10.0 "${_asdf_dir}"
    git clone https://github.com/asdf-vm/asdf.git --branch v0.10.0 "${_asdf_dir}"
    echo

    if [ ! -e "${HOME}/.bashrc" ] || [ $(grep -c 'ASDF_DIR=' "${HOME}/.bashrc") -eq 0 ];
    then

        echo 'export ASDF_DIR='"${_asdf_dir}"       >> "${HOME}/.bashrc"
        echo '. ${ASDF_DIR}/asdf.sh'                >> "${HOME}/.bashrc"
        echo '. ${ASDF_DIR}/completions/asdf.bash'  >> "${HOME}/.bashrc"
        echo 'nodejs 18.7.0'                        >> "${HOME}/.tool-versions"

        source "${HOME}/.bashrc"
        source "${ASDF_DIR}/asdf.sh"

        asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
        asdf install nodejs 18.7.0
        asdf global nodejs 18.7.0

        # [npm Config Setting](https://docs.npmjs.com/cli/v8/using-npm/config#cache)
        npm config set cache "${_asdf_dir}/../npm" --location=global
        npm install pm2

        ./node_modules/.bin/pm2 install pm2-logrotate

    fi

    # twitter header bot installation
    (
      cd public \
      && npm install \
      && npm audit fix --force
    )

    echo '' > ./.pm2-installed
}

function install_process_manager_requirements() {

function install_system_packages() {
    apt-get update

    # Install packages with package management system frontend (apt)
    apt-get install --assume-yes \
        apt-utils \
        ca-certificates \
        curl \
        dirmngr \
        gawk \
        git \
        gpg \
        make \
        procps \
        tini \
        unzip \
        wget
}

    add_system_user_group
    install_system_packages
    install_dockerize
    create_log_files_when_non_existing "${WORKER}"
    set_permissions
    clear_package_management_system_cache
    remove_distributed_version_control_system_files_git "${WORKER}"
}

function remove_distributed_version_control_system_files_git() {
    local worker
    worker="${1}"

    local project_dir
    project_dir="/var/www/${worker}"

    if [ ! -d "${project_dir}" ];
    then

        printf 'Cannot find project directory'

        return 1

    fi

    if [ ! -d "${project_dir}/.git" ];
    then
        rm --recursive --force --verbose "${project_dir}/.git"
    fi
}

function set_permissions() {
    chown worker. \
        /var/www \
        /start.sh

    chown -R worker. "/var/www/${WORKER}"/var/log/*

    chmod -R ug+x \
        /start.sh

    if [ -e /entrypoint.sh ]; then

        chown worker. /entrypoint.sh
        chmod -R ug+x /entrypoint.sh

    fi
}

set -Eeuo pipefail

