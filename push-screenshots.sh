#!/usr/bin/env bash
set -Eeuo pipefail

source "${HOME}/.running/distributed-version-control-system-git.sh"

#
# Push screenshots to remote directory
#
# ```
# push_screenshots '2018-01-01' # [ --dry-mode ]
# ```
function push_screenshots() {
    local since_date
    since_date="${1}"

    if [ -z "${since_date}" ]; then

        printf 'A %s is expected as %s (%s).%s' 'non-empty string' '1st argument' 'publication date since when screenshots are to be pushed remotely' $'\n'

        return 1

    fi

    local dry_mode
    dry_mode="${2}"

    local is_dry_mode_enabled
    is_dry_mode_enabled=''

    if [ -n "${dry_mode}" ]; then

        is_dry_mode_enabled='--dry-mode'

    fi

    while [ "${since_date}" != $(date -I) ]; do

        directory=$(echo -n ${since_date} | sed -E 's#-#/#g')

        if [ -n "${dry_mode}" ]; then
        if [ "${is_dry_mode_enabled}" = '--dry-mode' ]; then

            echo 'Running in dry mode' 1>&2

            echo mkdir --parents screenshots/$directory
            echo mv "screenshots/"*"${since_date}"* screenshots/$directory
            #echo mv "screenshots/"*"${since_date}"* screenshots/$directory
            echo git add screenshots/$directory
            echo gci 'Added the three news most retweeted on the '"${since_date}"
            echo git push origin

        else

            echo mkdir --parents screenshots/$directory
            mkdir --parents screenshots/$directory
            #[ -d screenshots/$directory ] || mv --force "screenshots/"*"${since_date}"* screenshots/$directory

            echo git add -f screenshots/$directory
            git add -f screenshots/$directory

            echo git_commit 'Added the three news most retweeted on the '"${since_date}"
            git_commit 'Added the three news most retweeted on the '"${since_date}"
            git push origin

        fi

        since_date=$(date -I -d "${since_date} + 1 day")

    done
}
alias push-screenshots='push_screenshots'

set +Eeuo pipefail
