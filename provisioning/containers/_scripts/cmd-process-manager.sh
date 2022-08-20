#!/usr/bin/env bash
set -Eeo pipefail

source '/scripts/requirements.sh'

start() {
    local project_dir
    project_dir="/var/www/${WORKER}"

    cd "${project_dir}" || exit

    if [ ! -d "${project_dir}/.git" ];
    then
        rm --recursive --force --verbose "${project_dir}/.git"
    fi

    if [ ! -e ./.pm2-installed ];
    then

        local asdf_dir
        asdf_dir="${project_dir}/var/home/asdf"

        install_process_manager "${asdf_dir}" || true

    fi

    (
        cd public

        ./../node_modules/.bin/pm2 \
            --instances 1 \
            --log "./var/log/${WORKER}.json" \
            --log-type json \
            --max-memory-restart 268435456 \
            --no-daemon \
            --restart-delay=10000 \
            start node ./index.js \
            --name 'Keeping bot alive' \
            2>> "${project_dir}/var/log/${WORKER}.error.log"
    )
}
start

set +Eeo pipefail
