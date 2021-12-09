#!/bin/sh
set -e

trigger_workflow() {
  echo "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/dispatches"
  echo "{\"ref\":\"${ref}\",\"inputs\":${inputs}}"

  trigger_workflow=$(curl --fail -X POST "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/dispatches" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    --data "{\"ref\":\"${ref}\",\"inputs\":${inputs}}")

  echo "Waiting ${wait_interval} seconds until triggered workflow starts"
  sleep $wait_interval
}
