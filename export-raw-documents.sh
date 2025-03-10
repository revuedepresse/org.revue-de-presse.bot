#!/usr/bin/env bash
set -Eeuo pipefail

#
# Export raw documents in JSON
#
# ```
# export AUTH_TOKEN='api_example_org_token$' && export-raw-documents # [ --dry-run ]
# ```
function export_raw_documents() {
    local dry_mode
    dry_mode="${1}"

    local dry_mode_enabled

    if [ -n "${dry_mode}" ]; then

        dry_mode_enabled='--dry-mode'

    fi

    if [ -z "${AUTH_TOKEN}" ]; then

        printf 'An %s is expected as %s ("%s" environment variable).%s' 'non-empty string' 'authorization token' 'AUTH_TOKEN' $'\n'

        return 1

    fi

    local auth_token
    auth_token=$(printf '%s' "${AUTH_TOKEN}")

    local endpoint
    endpoint='https://api.revue-de-presse.org/api/twitter/highlights?includeRetweets=0\&startDate=\1\&endDate=\1\&pageSize=10'

    export IFS=_$'\n'

    for cmd in $(find screenshots |
        \grep -E 'screenshots\/[0-9][0-9][0-9][0-9]\/[0-9][0-9]\/[0-9][0-9]$' |
        sed -E 's#screenshots\/(.+)#mkdir --parents ./raw-documents/\1 ;curl -XGET --silent -H '"'"'x-auth-token: '"${auth_token}""'"' --output "./raw-documents/\1/placeholder.json" '"'""${endpoint}""'"'#g'); do

        if [ -z "${dry_mode_enabled}" ]; then

            printf '%s' 'Exporting raw JSON document for most retweeted news by running the following command: ' $'\n'
            echo "${cmd}" | sed 's|'"$(echo -n "${AUTH_TOKEN}")"'|*******|g'

            /bin/bash -c "${cmd}"

        else

            echo ${cmd}

        fi

    done
}
alias export-raw-documents='export_raw_documents'

function commit_raw_documents() {
    local year
    year="$(date -d now '+%Y')"

    if [ -n "${1}" ]; then
        year="${1}"
    fi

    find ./raw-documents -regex './raw-documents/'"${year}"'.*json$' \
        -exec sh -c 'export at_date="$(echo $1 | sed -E "s#placeholder##g" | sed -E "s#.\/raw-documents\/([^\/]+\/[^\/]+\/[^\/]+)\/#\1#g" | sed -E "s#/#-#g" | sed -E "s#.json##")" && mkdir --parents ./raw-documents/"$(echo $at_date | sed -E "s#-#/#")" && export filename=./raw-documents/"$(echo $at_date | sed -E "s#-#/#")"/${at_date}.json && mv --verbose $1 $filename && git add -f $filename && git commit -m "Added a JSON document containing the 10 most retweeted news on the ${at_date}" ' shell {} \;
}
alias commit-raw-documents='commit_raw_documents'

set +Eeuo pipefail
