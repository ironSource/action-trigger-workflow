#!/bin/sh
set -e

source inputs_validation.sh
source trigger_workflow.sh
source get_running_workflow_id.sh
source wait_for_workflow_to_finish.sh

GITHUB_API_URL="${API_URL:-https://api.github.com}"
GITHUB_SERVER_URL="${SERVER_URL:-https://github.com}"
TRIGGERED_WORKFLOW_ID="null"

main() {
  validate_args

  trigger_workflow

  if [ "${wait_workflow}" = true ]
  then
    get_running_workflow_id
    wait_for_workflow_to_finish
  else
    echo "Skipping waiting for workflow."
  fi
}

main
