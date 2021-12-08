#!/bin/sh
set -e

wait_for_workflow_to_finish() {
  last_workflow_url="${GITHUB_SERVER_URL}/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/${TRIGGERED_WORKFLOW_ID}"
  echo "The workflow id is [${TRIGGERED_WORKFLOW_ID}]."
  echo "The workflow logs can be found at ${last_workflow_url}"
  echo "::set-output name=workflow_id::${TRIGGERED_WORKFLOW_ID}"
  echo "::set-output name=workflow_url::${last_workflow_url}"
  echo ""

  # start checking triggered workflow status till completed --------
  conclusion="null"
  status="null"
  while [[ "${conclusion}" == "null" && "${status}" != "\"completed\"" ]]
  do
    echo "Sleeping for \"${wait_interval}\" seconds"
    sleep "${wait_interval}"
    echo "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/runs"
    workflow=$(curl -X GET "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/runs" \
      -H 'Accept: application/vnd.github.antiope-preview+json' \
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq '.workflow_runs[] | select(.id == '${TRIGGERED_WORKFLOW_ID}')')
    conclusion=$(echo "${workflow}" | jq '.conclusion')
    status=$(echo "${workflow}" | jq '.status')
    echo "Checking conclusion [${conclusion}]"
    echo "Checking status [${status}]"
  done
  # ---------------------------------------------------------------
  # check completed target workflow conclusion
  if [[ "${conclusion}" == "\"success\"" && "${status}" == "\"completed\"" ]]
  then
    echo "Triggered workflow complete successfully"
  else
    # Alternative "failure"
    echo "Triggered workflow failed. Reason: [${conclusion}]."
    if [ "${propagate_failure}" = true ]
    then
      echo "Propagating failure to upstream job"
      exit 1
    fi
  fi
  # ---------------------------------------------------------------
}
