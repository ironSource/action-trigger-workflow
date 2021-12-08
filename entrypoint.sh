#!/bin/sh
set -e

GITHUB_API_URL="${API_URL:-https://api.github.com}"
GITHUB_SERVER_URL="${SERVER_URL:-https://github.com}"

validate_args() {
  wait_interval=10 # Waits for 10 seconds
  if [ "${INPUT_WAITING_INTERVAL}" ]
  then
    wait_interval=${INPUT_WAITING_INTERVAL}
  fi

  propagate_failure=true
  if [ -n "${INPUT_PROPAGATE_FAILURE}" ]
  then
    propagate_failure=${INPUT_PROPAGATE_FAILURE}
  fi

  trigger_workflow=true
  if [ -n "${INPUT_TRIGGER_WORKFLOW}" ]
  then
    trigger_workflow=${INPUT_TRIGGER_WORKFLOW}
  fi

  wait_workflow=true
  if [ -n "${INPUT_WAIT_WORKFLOW}" ]
  then
    wait_workflow=${INPUT_WAIT_WORKFLOW}
  fi

  if [ -z "${INPUT_OWNER}" ]
  then
    echo "Error: Owner is a required argument."
    exit 1
  fi

  if [ -z "${INPUT_REPO}" ]
  then
    echo "Error: Repo is a required argument."
    exit 1
  fi

  if [ -z "${INPUT_GITHUB_TOKEN}" ]
  then
    echo "Error: Github token is required. You can head over settings and"
    echo "under developer, you can create a personal access tokens. The"
    echo "token requires repo access."
    exit 1
  fi

  if [ -z "${INPUT_WORKFLOW_FILE_NAME}" ]
  then
    echo "Error: Workflow File Name is required"
    exit 1
  fi

  if [ -z "${INPUT_JOB_NAME_SUBSTRING}" ]
  then
    echo "Error: Job name substring is a required argument."
    exit 1
  fi

  inputs=$(echo '{}' | jq)
  if [ "${INPUT_INPUTS}" ]
  then
    inputs=$(echo "${INPUT_INPUTS}" | jq)
  fi

  ref="main"
  if [ "$INPUT_REF" ]
  then
    ref="${INPUT_REF}"
  fi
}

trigger_workflow() {
  echo "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/dispatches"
  echo "{\"ref\":\"${ref}\",\"inputs\":${inputs}}"

  trigger_workflow=$(curl --fail -X POST "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/workflows/${INPUT_WORKFLOW_FILE_NAME}/dispatches" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" \
    --data "{\"ref\":\"${ref}\",\"inputs\":${inputs}}")

  echo "Sleeping for ${wait_interval} seconds"
  sleep $wait_interval
}

wait_for_workflow_to_finish() {
  # Find the id of the last run using filters to identify the workflow triggered by this action
  echo "Getting the ID of the workflow..."

  # get list of workflow ids --------------------------------------
  query="event=workflow_dispatch"
  if [ "$INPUT_GITHUB_USER" ]
  then
    query="${query}&actor=${INPUT_GITHUB_USER}"
  fi

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
      -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq ".jobs[] | select(.name | test(\"${INPUT_JOB_NAME_SUBSTRING}\")) | .id")
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
    echo "Yes, success"
  else
    # Alternative "failure"
    echo "Conclusion is not success, its [${conclusion}]."
    if [ "${propagate_failure}" = true ]
    then
      echo "Propagating failure to upstream job"
      exit 1
    fi
  fi
  # ---------------------------------------------------------------
}

main() {
  validate_args

  if [ "${trigger_workflow}" = true ]
  then
    trigger_workflow
  else
    echo "Skipping triggering the workflow."
  fi

  if [ "${wait_workflow}" = true ]
  then
    wait_for_workflow_to_finish
  else
    echo "Skipping waiting for workflow."
  fi
}

main
