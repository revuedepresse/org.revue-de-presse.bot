#!/bin/bash

function install_package_manager_asdf() {
    if [ -d "${HOME}/.asdf" ]; then

        # shellcheck disable=SC2016
        printf '%s.%s' 'Skipping package manager ("asdf") installation ("${HOME}/.asdf" exists already).' $'\n' 1>&2

        return 0

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
    asdf install nodejs 16.15.1
    asdf local nodejs 16.15.1
    asdf global nodejs 16.15.1
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
        --scale-factor=1 \
        --element="${element_selector}" \
        --wait-for-element="${awaited_element_selector}" \
        --no-block-ads
}
alias capture-dated-website-screenshot='_capture_dated_website_screenshot'

function _capture_dated_website_screenshots_collection() {
    source "${HOME}/.asdf/asdf.sh"

    local date
    date="${1}"

    if [ -z "${date}" ]; then

        date="$(date -I)"

    fi

    local media_filepath_prefix
    media_filepath_prefix="$(pwd)/screenshots/3-actus-les-plus-relayees-le-${date}-"

    local awaited_element_selector
    local element_selector
    local output

    for i in $(seq 1 3); do

        awaited_element_selector='.list__item:nth-child('${i}')'
        element_selector='.list__item:nth-child('"${i}"')'
        output="${media_filepath_prefix}${i}.png"

        printf '%s.%s' 'About to save website screenshot to '"${output}" $'\n' 2>&1

        _capture_dated_website_screenshot "${output}" "${element_selector}" "${awaited_element_selector}" "${date}"

    done

}
alias capture-dated-website-screenshots-collection='_capture_dated_website_screenshots_collection'

function _capture_dated_website_screenshots_since() {
    local since_date
    since_date="${1}"

    if [ -z "${since_date}" ]; then

        since_date="$(date -I)"

    fi

    while [ "$since_date" != "$(date -I)" ]; do

        echo DATE="${since_date}" make capture-dated-website-screenshots-collection

        for _ in $(seq 1 3); do

            DATE="${since_date}" make capture-dated-website-screenshots-collection

            if [ $? -eq 0 ]; then

                break

            else

                printf 'Retrying to capture date website screenshot (on the %s).%s' "${since_date}" $'\n' 1>&2

            fi

        done

        since_date=$(date -I -d "$since_date + 1 day")

    done
}
alias capture-dated-website-screenshots-since='_capture_dated_website_screenshots_since'

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

    export hostname='api.revue-de-presse.org'

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

    export hostname='api.revue-de-presse.org'

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

    local alt_text
    local text

    local previous_selector
    previous_selector='0'

    local url

    for i in $(seq 1 3); do

        if [ ${i} -gt 1 ]; then

            previous_tweet_id="${tweet_id}"

        fi

        capture-website \
            'https://revue-de-presse.org/'"${date}"/'?naked' \
            --delay=20 \
            --emulate-device="${device}" \
            --full-page \
            --output="${media_filepath_prefix}${i}.png" \
            --overwrite \
            --scale-factor=1 \
            --element='.list__item:nth-child('"${i}"')' \
            --wait-for-element='.list__item:nth-child('${i}')' \
            --no-block-ads

        file_size=$(stat --format '%s' "./screenshots/3-actus-les-plus-relayees-le-${date}-${i}.png")

        response="$(twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=INIT&total_bytes='"${file_size}"'&media_type=image/png')"

        printf '%s%s' "${response}" $'\n' 1>&2

        media_id="$(echo -n "${response}" | jq '.media_id_string' -r)"

        echo "Media ID: ${media_id}"

        twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=APPEND&media_id='"${media_id}"'&segment_index=0' \
            --file "${media_filepath_prefix}${i}.png" \
            --file-field='media'

        twurl \
            --host "upload.twitter.com" \
            --request-method POST '/1.1/media/upload.json?command=FINALIZE&media_id='"${media_id}"

        export hostname='api.revue-de-presse.org'

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
