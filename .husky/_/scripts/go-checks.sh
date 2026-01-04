#!/usr/bin/env sh

COLOR_YELLOW='\033[33m'
COLOR_RED='\033[31m'
COLOR_RESET='\033[0m'

# Based on okular/hooks/pre-commit, credits go to Albert Astals Cid
# Runs gofmt/goimport + golangci-lint on staged Go files only

if [ ! -f .github/.golangci.yml ]; then
    echo "ERROR: no .github/.golangci.yml file found in repository root"
    echo "Make sure you're in the meshery repository root directory"
    exit 1
fi

STAGED_GO_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.go$')

if [ -z "$STAGED_GO_FILES" ]; then
    exit 0
fi

if ! command -v goimports >/dev/null 2>&1; then
    echo "${COLOR_YELLOW}WARNING: goimports not found, falling back to gofmt${COLOR_RESET}"
    echo "Install goimports: go install golang.org/x/tools/cmd/goimports@latest"
    FORMATTER="gofmt"
else
    FORMATTER="goimports"
fi

UNFORMATTED_FILES=$($FORMATTER -l $STAGED_GO_FILES)
if [ -n "$UNFORMATTED_FILES" ]; then
    echo ""
    echo "${COLOR_RED}ERROR: The following files are not formatted correctly:${COLOR_RESET}"
    echo "$UNFORMATTED_FILES"
    echo ""
    echo "To fix, run:"
    echo "    $FORMATTER -w $UNFORMATTED_FILES  # format the files"
    echo "    $FORMATTER -d $UNFORMATTED_FILES  # preview the changes"
    exit 1
fi

output=$(golangci-lint run --config=.github/.golangci.yml --new-from-rev=HEAD 2>&1)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    exit 0
fi

echo "$output"
echo ""
echo "${COLOR_RED}ERROR: golangci-lint found issues in your staged files${COLOR_RESET}"
echo ""
echo "You can fix them using:"
echo "    golangci-lint run --config=.github/.golangci.yml --fix --new-from-rev=HEAD"

exit 1