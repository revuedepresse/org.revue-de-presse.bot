#!/usr/bin/env bash
set -Eeuo pipefail

function install_package_manager_asdf() {
    if [ -d "${HOME}/.asdf" ]; then

        # shellcheck disable=SC2016
        printf '%s.%s' 'Skipping package manager ("asdf") installation ("${HOME}/.asdf" exists already).' $'\n' 1>&2

        return

    fi

    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
}
alias install-package-manager='install_package_manager_asdf'

function install_ruby_runtime() {
    source "${HOME}/.asdf/asdf.sh"

    asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
    asdf install ruby 2.6.4
    asdf local ruby 2.6.4
    asdf global ruby 2.6.4
}
alias install-ruby-runtime='install_ruby_runtime'

function install_javascript_runtime_nodejs() {
    source "${HOME}/.asdf/asdf.sh"

    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf install nodejs 18.12.1
    asdf local nodejs 18.12.1
    asdf global nodejs 18.12.1
}
alias install-javascript-runtime='install_javascript_runtime_nodejs'

function install_twitter_client_twurl() {
    source "${HOME}/.asdf/asdf.sh"

    if ! command -v gem >>/dev/null 2>&1; then

        printf '%s.%s' 'ruby (and gem) are required' $'\n' 1>&2
        printf '%s%s' 'install-ruby-runtime?' $'\n' 1>&2

        return 1

    fi

    gem install twurl
}
alias install-twitter-client='install_twitter_client_twurl'

function install_website_screenshot_capture_cli() {
    source "${HOME}/.asdf/asdf.sh"

    if ! command -v npm >>/dev/null 2>&1; then

        printf '%s.%s' 'nodejs (and npm) are required' $'\n' 1>&2
        printf '%s%s' 'install-javascript-runtime?' $'\n' 1>&2

        return 1

    fi

    npm install --global capture-website-cli
}
alias install-website-screenshot-capture-cli='install_website_screenshot_capture_cli'

function install_web_browser() {
    if command -v google-chrome >>/dev/null 2>&1; then

        printf 'Skipping web browser ("%s") installation (Found "%s" command).%s' 'chrome' 'google-chrome' $'\n' 1>&2

        return 0

    fi

    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt install ./google-chrome-stable_current_amd64.deb
    rm -f google-chrome-stable_current_amd64.deb
}
alias install-web-browser='install_web_browser'

function _capture_dated_website_screenshot() {
    local output
    output="${1}"

    if [ -z "${output}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '1st argument' 'output' $'\n'

        return 1

    fi

    local element_selector
    element_selector="${2}"

    if [ -z "${element_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '2nd argument' 'element_selector' $'\n'

        return 1

    fi

    local awaited_element_selector
    awaited_element_selector="${3}"

    if [ -z "${awaited_element_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '3rd argument' 'awaited element selector' $'\n'

        return 1

    fi

    local date
    date="${4}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local device
    device="Pixel 2 XL"

    source "${HOME}/.asdf/asdf.sh"

    capture-website \
        'https://revue-de-presse.org/'"${date}"/'?naked' \
        --delay=20 \
        --emulate-device="${device}" \
        --full-page \
        --output="${output}" \
        --overwrite \
        --scale-factor='0.75' \
        --element="${element_selector}" \
        --wait-for-element="${awaited_element_selector}" \
        --no-block-ads
}
alias capture-dated-website-screenshot='_capture_dated_website_screenshot'

function _capture_dated_website_screenshots_collection() {
    local date
    date="${1}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local media_extension
    media_extension="${2}"

    if [ -z "${media_extension}" ]; then

        media_extension='png'

    fi

    local media_filepath_prefix
    media_filepath_prefix="$(pwd)/screenshots/3-actus-les-plus-relayees-le-${date}-"

    local awaited_element_selector
    local element_selector
    local output

    for i in $(seq 1 3); do

        awaited_element_selector='.list__item:nth-child('${i}')'
        element_selector='.list__item:nth-child('"${i}"')'
        output="${media_filepath_prefix}${i}.${media_extension}"

        printf '%s.%s' 'About to save website screenshot to '"${output}" $'\n' 2>&1

        _capture_dated_website_screenshot "${output}" "${element_selector}" "${awaited_element_selector}" "${date}"

    done

}
alias capture-dated-website-screenshots-collection='_capture_dated_website_screenshots_collection'

function _url() {
    local start_selector
    start_selector="${1}"

    if [ -z "${start_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '1st argument' 'start selector' $'\n' 1>&2

        return 1

    fi

    local end_selector
    end_selector="${2}"

    if [ -z "${end_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '2nd argument' 'end selector' $'\n' 1>&2

        return 1

    fi

    local date
    date="${3}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local hostname
    hostname='api.revue-de-presse.org'

    date="${date}" &&
        /bin/bash -c "curl --silent 'https://${hostname}/api/twitter/highlights?includeRetweets=0&startDate=${date}&endDate=${date}&pageSize=10' -H 'x-auth-token: $AUTH_TOKEN'" |
        jq '.statuses | .['${start_selector}:${end_selector}'] | .[] .status.url ' -r
}
alias url='_url'

function _text() {
    local start_selector
    start_selector="${1}"

    if [ -z "${start_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '1st argument' 'start selector' $'\n' 1>&2

        return 1

    fi

    local end_selector
    end_selector="${2}"

    if [ -z "${end_selector}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '2nd argument' 'end selector' $'\n' 1>&2

        return 1

    fi

    local date
    date="${3}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local hostname
    hostname='api.revue-de-presse.org'

    date="${date}" &&
        /bin/bash -c "curl --silent 'https://${hostname}/api/twitter/highlights?includeRetweets=0&startDate=${date}&endDate=${date}&pageSize=10' -H 'x-auth-token: $AUTH_TOKEN'" |
        jq '.statuses | .['${start_selector}:${end_selector}'] | .[] .status | .text ' | sed -E 's#https://[^"]+##g'
}
alias text='_text'

#```shell
# export AUTH_TOKEN='_tok_'
# post-tweet "$(date -I)"
#```
function tweet() {
    source "${HOME}/.asdf/asdf.sh"

    if ! command -v twurl >>/dev/null 2>&1; then

        printf '%s.%s' 'twurl is required' $'\n' 1>&2
        printf '%s%s' 'install-twitter-client?' $'\n' 1>&2

        return 1

    fi

    local date
    date="${1}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local device
    device="Pixel 2 XL"

    local media_filepath_prefix
    media_filepath_prefix="$(pwd)/screenshots/3-actus-les-plus-relayees-le-${date}-"

    local media_id
    local tweet_id
    local previous_tweet_id
    local response

    local localized_date
    localized_date="$(date -d"${date}" '+%d/%m/%Y')"

    local media_extension='png'

    local alt_text
    local text

    local previous_selector
    previous_selector='0'

    local url

    while true; do

        if [ -e "${media_filepath_prefix}1.${media_extension}" ] &&
            [ -e "${media_filepath_prefix}2.${media_extension}" ] &&
            [ -e "${media_filepath_prefix}3.${media_extension}" ]; then

            break

        fi

        _capture_dated_website_screenshots_collection "${date}"

        sleep 1

    done

    twurl accounts

    for i in $(seq 1 3); do

        if [ ${i} -gt 1 ]; then

            previous_tweet_id="${tweet_id}"

        fi

        file_size=$(stat --format '%s' "./screenshots/3-actus-les-plus-relayees-le-${date}-${i}.${media_extension}")

        response="$(twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=INIT&total_bytes='"${file_size}"'&media_type=image/'"${media_extension}")"

        printf '%s%s' "${response}" $'\n' 1>&2

        media_id="$(echo -n "${response}" | jq '.media_id_string' -r)"

        echo "Media ID: ${media_id}"

        twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=APPEND&media_id='"${media_id}"'&segment_index=0' \
            --file "${media_filepath_prefix}${i}.${media_extension}" \
            --file-field='media'

        twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=FINALIZE&media_id='"${media_id}"

        local hostname
        hostname='api.revue-de-presse.org'

        alt_text="$(_text ${previous_selector} ${i} "${date}")"
        url="$(_url ${previous_selector} ${i} "${date}")"

        previous_selector="${i}"

        echo twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/metadata/create.json' \
            --data '{"media_id": "'"${media_id}"'", "alt_text": {"text": '"${alt_text}"'} }' \
            --trace

        twurl \
            --data '{"media_id": "'"${media_id}"'", "alt_text": {"text": '"${alt_text}"'} }' \
            --header 'Content-Type: application/json' \
            --host 'upload.twitter.com' \
            --request-method POST '/1.1/media/metadata/create.json'

        if [ $i = 1 ]; then

            text="L'actu la plus relayée le ${localized_date} : ${url}"

            response="$(twurl -d 'status='"${text}" -d 'media_ids='"${media_id}" '/1.1/statuses/update.json')"

            printf '%s%s' "${response}" $'\n' 1>&2

            tweet_id="$(echo -n "${response}" | jq '.id_str' -r)"

        else

            if [ $i = 2 ]; then

                text='La seconde actu la plus relayée le '"${localized_date}"' : '"${url}"

            fi

            if [ $i = 3 ]; then

                text='La troisième actu la plus relayée le '"${localized_date}"' : '"${url}"

            fi

            response=$(twurl -d 'in_reply_to_status_id='"${previous_tweet_id}" -d 'status='"${text}" -d 'media_ids='"${media_id}" '/1.1/statuses/update.json')

            printf '%s%s' "${response}" $'\n' 1>&2

            tweet_id="$(echo -n "${response}" | jq '.id_str' -r)"

        fi

    done
}
alias post-tweet='tweet'

#```shell
# export REVUE_AUTH_TOKEN='_tok_'
# prepublish-newsletter "$(date -I)"
#```
function prepublish_newsletter() {
    local dry_mode
    dry_mode=''

    printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-\-dry-run'

    if [ $? -eq 0 ]; then

        dry_mode='--dry-run'

    fi

    printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-N'

    if [ $? -eq 0 ]; then

        dry_mode='--dry-run'

    fi

    local show_help
    show_help=''

    printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-\-help'

    if [ $? -eq 0 ]; then

        show_help='--help'

    fi

    printf "%s\0" "${@}" | grep --line-regexp --quiet --null-data '\-h'

    if [ $? -eq 0 ]; then

        show_help='--help'

    fi

    if [ "${show_help}" = '--help' ]; then

        printf '%s%s' '#                                                    ' $'\n'
        printf '%s%s' '# Post today'"'"'s issue                             ' $'\n'
        printf '%s%s' '#                                                    ' $'\n'
        printf '%s%s' '# ```shell                                           ' $'\n'
        printf '%s%s' '# post-issue # $(date -I)                            ' $'\n'
        printf '%s%s' '#                                                    ' $'\n'
        printf '%s%s' '# -h --help     Show this help                       ' $'\n'
        printf '%s%s' '# -N --dry-run  Generate screenshots                 ' $'\n'
        printf '%s%s' '#               but do not attach items to an issue  ' $'\n'
        printf '%s%s' '# ```                                                ' $'\n'
        printf '%s%s' '#                                                    ' $'\n'

        return 0

    fi

    source "${HOME}/.asdf/asdf.sh"

    local date
    date="${1}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local device
    device="Pixel 2 XL"

    local media_filepath_prefix
    media_filepath_prefix="$(pwd)/screenshots/3-actus-les-plus-relayees-le-${date}-"

    local response

    local localized_date
    localized_date="$(date -d"${date}" '+%d/%m/%Y')"

    local text

    local media_extension
    media_extension='png'

    local previous_selector
    previous_selector='4'

    local api_base_url
    api_base_url='https://www.getrevue.co/api'

    local issue_id
    issue_id="$(curl -H'Authorization: Token '${REVUE_AUTH_TOKEN} "${api_base_url}"'/v2/issues/current' | jq '.[] | .id')"

    printf 'Issue id is %s.%s' "${issue_id}" $'\n'

    local cmd
    local url

    while true; do

        if [ -e "${media_filepath_prefix}1.${media_extension}" ] &&
            [ -e "${media_filepath_prefix}2.${media_extension}" ] &&
            [ -e "${media_filepath_prefix}3.${media_extension}" ]; then

            break

        fi

        _capture_dated_website_screenshots_collection "${date}"

        sleep 1

    done

    for i in $(seq 1 3 | sort --reverse); do

        file_size=$(stat --format '%s' "${media_filepath_prefix}${i}.${media_extension}")

        url="$(_url ${i} ${previous_selector} "${date}")"

        previous_selector="${i}"

        if [ $i = 1 ]; then

            text="L’actu la plus relayée le ${localized_date}"

            cmd="$(
                \cat <<-CMD
		\curl -H'Authorization: Token '"${REVUE_AUTH_TOKEN}" \
                --no-progress-meter \
		--form issue_id="${issue_id}" \
		--form url="${url}" \
		"${api_base_url}/v2/issues/${issue_id}/items" \
		2>&1
CMD
            )"

            cmd="$(
                \cat <<-CMD
		\cat "${media_filepath_prefix}${i}.${media_extension}" | \
		base64 | \
		\curl -H'Authorization: Token '"${REVUE_AUTH_TOKEN}" \
                --no-progress-meter \
		--form issue_id="${issue_id}" \
		--form caption="${text}" \
		--form url="${url}" \
		--form image='<-' \
		--form type=image \
		"${api_base_url}/v2/issues/${issue_id}/items" \
		2>&1
CMD
            )"

            printf '%s:%s' 'About to execute command to add image item' $'\n'
            printf '%s%s' "${cmd}" $'\n'

            if [ "${dry_mode}" != '--dry-run' ]; then

                response="$(bash -c "${cmd}" 2>&1)"

            fi

            printf '%s:%s' 'Received response' $'\n'
            printf '%s%s' "${response}" $'\n'

        else

            if [ $i = 2 ]; then

                text='La seconde actu la plus relayée le '"${localized_date}"

            fi

            if [ $i = 3 ]; then

                text='La troisième actu la plus relayée le '"${localized_date}"

            fi

            cmd="$(
                \cat <<-CMD
		\cat "${media_filepath_prefix}${i}.${media_extension}" | \
		base64 | \
		\curl -H'Authorization: Token '"${REVUE_AUTH_TOKEN}" \
                --no-progress-meter \
		--form issue_id="${issue_id}" \
		--form url="${url}" \
		"${api_base_url}/v2/issues/${issue_id}/items" \
		2>&1
CMD
            )"

            cmd="$(
                \cat <<CMD
		\cat "${media_filepath_prefix}${i}.${media_extension}" | \
		base64 | \
		\curl -H'Authorization: Token '"${REVUE_AUTH_TOKEN}" \
                --no-progress-meter \
		--form issue_id="${issue_id}" \
		--form caption="${text}" \
		--form url="${url}" \
		--form image='<-' \
		--form type=image \
		"${api_base_url}/v2/issues/${issue_id}/items" \
		2>&1
CMD
            )"

            printf '%s:%s' 'About to execute command to add image item' $'\n'
            printf '%s%s' "${cmd}" $'\n'

            if [ "${dry_mode}" != '--dry-run' ]; then

                response="$(bash -c "${cmd}" 2>&1)"

            fi

            printf '%s:%s' 'Received response' $'\n'
            printf '%s%s' "${response}" $'\n'

        fi

    done
}
alias prepublish-newsletter='prepublish_newsletter'

set +Eeuo pipefail
