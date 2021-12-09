#!/bin/sh
set -e

source /validate_args.sh
source /trigger_workflow.sh
source /wait_for_workflow_to_finish.sh

GITHUB_API_URL="${API_URL:-https://api.github.com}"
GITHUB_SERVER_URL="${SERVER_URL:-https://github.com}"

main() {
  validate_args

  trigger_workflow

  if [ "${wait_workflow}" = true ]
  then
    wait_for_workflow_to_finish
  else
    echo "Skipping waiting for workflow."
  fi
}

main
