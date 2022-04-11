#!/bin/sh
set -e

wait_for_workflow_to_finish() {
  # Find the id of the last run using filters to identify the workflow triggered by this action
  echo "Getting the ID of the workflow..."

  # get list of workflow ids --------------------------------------
  query="event=workflow_dispatch"
  list_workflows_ids=$(curl -X GET "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/runs?${query}" \
    -H 'Accept: application/vnd.github.antiope-preview+json' \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq '.workflow_runs[] | select(.status=="queued" or .status=="in_progress") | .id')
  # ---------------------------------------------------------------

  # get triggered workflow id by job name substring included branch name and short SHA of commit
  triggered_workflow_id="null"
  for wf_id in $list_workflows_ids
  do
    job_id=$(curl -X GET "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/$wf_id/jobs" \
      -H 'Accept: application/vnd.github.antiope-preview+json' \
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq ".jobs[] | select(.name | test(\"${INPUT_JOB_UUID}\")) | .id")
    if  [[ ! -z "$job_id" ]]
    then
      # triggered workflow id found
      triggered_workflow_id=$wf_id
      break
    fi
  done
  # ---------------------------------------------------------------

  last_workflow_url="${GITHUB_SERVER_URL}/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/${triggered_workflow_id}"
  echo "The workflow id is [${triggered_workflow_id}]."
  echo "The workflow logs can be found at ${last_workflow_url}"
  echo "::set-output name=workflow_id::${triggered_workflow_id}"
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
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq '.workflow_runs[] | select(.id == '${triggered_workflow_id}')')
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
