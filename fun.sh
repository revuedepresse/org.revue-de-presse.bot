#!/usr/bin/env bash
set -Eeuo pipefail

function build() {
    local WORKER
    local WORKER_OWNER_UID
    local WORKER_OWNER_GID

    load_configuration_parameters

    if [ -z "${WORKER}" ];
    then

      printf 'A %s is expected as %s ("%s").%s' 'non-empty string' 'worker name' 'WORKER' $'\n'

      return 1

    fi

    if [ -z "${WORKER_OWNER_UID}" ];
    then

      printf 'A %s is expected as %s ("%s").%s' 'non-empty numeric' 'system user uid' 'WORKER_OWNER_UID' $'\n'

      return 1

    fi

    if [ -z "${WORKER_OWNER_GID}" ];
    then

      printf 'A %s is expected as %s ("%s").%s' 'non-empty numeric' 'system user gid' 'WORKER_OWNER_GID' $'\n'

      return 1

    fi

    docker compose \
        --file=./provisioning/containers/docker-compose.yaml \
        --file=./provisioning/containers/docker-compose.override.yaml \
        build \
        --build-arg "WORKER_DIR=${WORKER}" \
        --build-arg "WORKER_OWNER_UID=${WORKER_OWNER_UID}" \
        --build-arg "WORKER_OWNER_GID=${WORKER_OWNER_GID}" \
        process-manager \
        worker
}

function clean() {
    local temporary_directory
    temporary_directory="${1}"

    if [ -n "${temporary_directory}" ];
    then
        printf 'About to revise file permissions for "%s" before clean up.%s' "${temporary_directory}" $'\n'

        set_file_permissions "${temporary_directory}"

        return 0
    fi

    remove_running_container_and_image_in_debug_mode 'app'
    remove_running_container_and_image_in_debug_mode 'worker'
}

function guard_against_missing_variables() {
    if [ -z "${COMPOSE_PROJECT_NAME}" ];
    then

        printf 'A %s is expected as %s ("%s" environment variable).%s' 'non-empty string' 'project name' 'COMPOSE_PROJECT_NAME' $'\n'

        exit 1

    fi

    if [ -z "${WORKER}" ];
    then

        printf 'A %s is expected as %s ("%s" environment variable).%s' 'non-empty string' 'worker name e.g. org.example.twitter-header-bot' 'WORKER' $'\n'

        exit 1

    fi

    if [ "${WORKER}" = 'org.example.twitter-header-bot' ];
    then

        printf 'Have you picked a satisfying worker name ("%s" environment variable - "%s" as default value is not accepted).%s' 'WORKER' 'org.example.twitter-header-bot' $'\n'

        exit 1

    fi

    if [ -z "${WORKER_OWNER_UID}" ];
    then

        printf 'A %s is expected as %s ("%s").%s' 'non-empty numeric' 'system user uid' 'WORKER_OWNER_UID' $'\n'

        exit 1

    fi

    if [ -z "${WORKER_OWNER_GID}" ];
    then

        printf 'A %s is expected as %s ("%s").%s' 'non-empty numeric' 'system user gid' 'WORKER_OWNER_GID' $'\n'

        exit 1

    fi
}

function green() {
    echo -n "\e[32m"
}

function install() {
    local DEBUG
    local WORKER
    local WORKER_OWNER_GID
    local WORKER_OWNER_UID

    load_configuration_parameters

    docker compose \
        -f ./provisioning/containers/docker-compose.yaml \
        -f ./provisioning/containers/docker-compose.override.yaml \
        up \
        --detach \
        --force-recreate \
        app

    docker compose \
        -f ./provisioning/containers/docker-compose.yaml \
        -f ./provisioning/containers/docker-compose.override.yaml \
        exec \
        --env WORKER="${WORKER}" \
        --user root \
        -T app \
        /bin/bash -c 'source /scripts/install-app-requirements.sh'

    clean ''
}

function load_configuration_parameters() {
    if [ ! -e ./provisioning/containers/docker-compose.override.yaml ]; then
        cp ./provisioning/containers/docker-compose.override.yaml{.dist,}
    fi

    if [ ! -e ./.env ]; then
        cp --verbose ./.env{.dist,}
    fi

    validate_docker_compose_configuration

    source ./.env

    printf '%s'           $'\n'
    printf '%b%s%b"%s"%s' "$(green)" 'COMPOSE_PROJECT_NAME: ' "$(reset_color)" "${COMPOSE_PROJECT_NAME}" $'\n'
    printf '%b%s%b"%s"%s' "$(green)" 'WORKER_DIR:           ' "$(reset_color)" "${WORKER}" $'\n'
    printf '%b%s%b"%s"%s' "$(green)" 'WORKER_OWNER_UID:     ' "$(reset_color)" "${WORKER_OWNER_UID}" $'\n'
    printf '%b%s%b"%s"%s' "$(green)" 'WORKER_OWNER_GID:     ' "$(reset_color)" "${WORKER_OWNER_GID}" $'\n'
    printf '%s'           $'\n'

    guard_against_missing_variables
}

function remove_running_container_and_image_in_debug_mode() {
    local container_name
    container_name="${1}"

    if [ -z "${container_name}" ];
    then

        printf 'A %s is expected as %s ("%s").%s' 'non-empty string' '1st argument' 'container name' $'\n'

        return 1

    fi

    local DEBUG
    local WORKER_OWNER_UID
    local WORKER_OWNER_GID
    local WORKER

    load_configuration_parameters

    local project_name
    project_name="${COMPOSE_PROJECT_NAME}"

    docker ps -a |
        \grep "${project_name}" |
        \grep "\-${container_name}\-" |
        awk '{print $1}' |
        xargs -I{} docker rm -f {}

    if [ -n "${DEBUG}" ];
    then

        docker images -a |
            \grep "${project_name}" |
            \grep "\-${container_name}\-" |
            awk '{print $3}' |
            xargs -I{} docker rmi -f {}

        build

    fi
}

function reset_color() {
    echo -n $'\033'\[00m
}

function start() {
    local DEBUG
    local WORKER
    local WORKER_OWNER_GID
    local WORKER_OWNER_UID

    load_configuration_parameters

    rm -f ./.pm2-installed

    local command
    command=$(cat <<-SCRIPT
docker compose \
      --file=./provisioning/containers/docker-compose.yaml \
      --file=./provisioning/containers/docker-compose.override.yaml \
			up \
			--detach \
			--force-recreate \
			process-manager
SCRIPT
)

    echo 'About to execute "'"${command}"'"'
    /bin/bash -c "${command}"
}

function validate_docker_compose_configuration() {
    docker compose \
        -f ./provisioning/containers/docker-compose.yaml \
        -f ./provisioning/containers/docker-compose.override.yaml \
        config -q
}

#
# Expected to be called by the Makefile located
# in the root project directory
#
# ```
# API_KEY=''
# API_SECRET=''
# ACCESS_TOKEN=''
# ACCESS_TOKEN_SECRET=''
# SCREEN_NAME=''
# write_configuration_to_disk [ --help ]
# ```
#
function write_configuration_to_disk() {
    local show_help
    show_help=''

    {
        printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-\-help'

        if [ $? -eq 0 ]; then

            show_help='--help'

        fi

        {
            printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-h'

            if [ $? -eq 0 ] && [ -z "${show_help}" ]; then

                show_help='--help'

            fi

            if [ "${show_help}" = '--help' ]; then

                echo ''                                                                                               1>&2
                echo '# Configure Twitter account header bot'                                                         1>&2
                echo ''                                                                                               1>&2
                echo '```'                                                                                            1>&2
                echo "$ API_KEY='_' API_SECRET='_' ACCESS_TOKEN='_' ACCESS_TOKEN_SECRET='_' SCREEN_NAME='_' make configure" 1>&2
                echo '```'                                                                                            1>&2
                echo ''                                                                                               1>&2
                printf '%s'$'\n' '# Show this help menu by assigning a non-empty value to DEBUG environment variable' 1>&2

                return 0

            fi
        }
    }

    local _api_key
    _api_key="${API_KEY}"

    if [ -z "${_api_key}" ] || [ "${_api_key}" = '_' ];
    then

        printf 'A %s is expected to be declared as %s (%s).%s' 'non-empty string' 'an environment variable' 'API_KEY' $'\n' 1>&2

        return 1

    fi

    local _api_secret
    _api_secret="${API_SECRET}"

    if [ -z "${_api_secret}" ] || [ "${_api_secret}" = '_' ];
    then

        printf 'A %s is expected as a %s (%s).%s' 'non-empty string' 'an environment variable' 'API_SECRET' $'\n' 1>&2

        return 1

    fi

    local _access_token
    _access_token="${ACCESS_TOKEN}"

    if [ -z "${_access_token}" ] || [ "${_access_token}" = '_' ];
    then

        printf 'A %s is expected as a %s (%s).%s' 'non-empty string' 'an environment variable' 'API_TOKEN' $'\n' 1>&2

        return 1

    fi

    local _access_token_secret
    _access_token_secret="${ACCESS_TOKEN_SECRET}"

    if [ -z "${_access_token_secret}" ] || [ "${_access_token_secret}" = '_' ];
    then

        printf 'A %s is expected as a %s (%s).%s' 'non-empty string' 'an environment variable' 'ACCESS_TOKEN_SECRET' $'\n' 1>&2

        return 1

    fi

    local _screen_name
    _screen_name="${SCREEN_NAME}"

    if [ -z "${_screen_name}" ] || [ "${_screen_name}" = '_' ];
    then

        printf 'A %s is expected as a %s (%s).%s' 'non-empty string' 'an environment variable' 'SCREEN_NAME (without "@" prefix)' $'\n' 1>&2

        return 1

    fi

    if [ -e ./.env ];
    then

        printf '%s.%s' 'Skipping configuration, .env file already exists.' $'\n' 1>&2

        return 1

    fi

    printf \
        '%s'$'\n''%s'$'\n''%s'$'\n''%s'$'\n''%s'$'\n' \
        "API_KEY=${_api_key}" \
        "API_SECRET=${_api_secret}" \
        "ACCESS_TOKEN=${_access_token}" \
        "ACCESS_TOKEN_SECRET=${_access_token_secret}" \
        "SCREEN_NAME=${_screen_name}" \
        > ./.env
}

function configure() {
    DEBUG="${DEBUG:-}"

    if [ -z "${DEBUG}" ];
    then

        write_configuration_to_disk

    else

        write_configuration_to_disk --help

    fi
}

set +Eeuo pipefail
