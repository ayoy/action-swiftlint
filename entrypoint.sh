#!/bin/bash

# convert swiftlint's output into GitHub Actions Logging commands
# https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands

function stripPWD() {
    if ! ${WORKING_DIRECTORY+false};
    then
        cd - > /dev/null
    fi
    sed -E "s/$(pwd|sed 's/\//\\\//g')\///"
}

function convertToGitHubActionsLoggingCommands() {
    sed -E 's/^(.*):([0-9]+):([0-9]+): (warning|error|[^:]+): (.*)/::\4 file=\1,line=\2,col=\3::\5/'
}

if ! ${WORKING_DIRECTORY+false};
then
	cd ${WORKING_DIRECTORY}
fi

if ! ${DIFF_BASE+false};
then
	changedFiles=$(
		git --no-pager diff --name-only --relative FETCH_HEAD $(git merge-base FETCH_HEAD $DIFF_BASE) -- '*.swift' \
			| sed -E 's/^(.*)$/"\1"/'
	)

	if [ -z "$changedFiles" ]
	then
		echo "No Swift file changed"
		exit
	fi
fi

set -o pipefail

if [ -z "$changedFiles" ]; then
	swiftlint "$@" | stripPWD | convertToGitHubActionsLoggingCommands
else
	echo $changedFiles | xargs swiftlint "$@" | stripPWD | convertToGitHubActionsLoggingCommands
fi
