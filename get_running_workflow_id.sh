#!/bin/sh
set -e

get_running_workflow_id(){
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
    for wf_id in $list_workflows_ids
    do
      job_id=$(curl -X GET "${GITHUB_API_URL}/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/$wf_id/jobs" \
        -H 'Accept: application/vnd.github.antiope-preview+json' \
        -H "Authorization: Bearer ${INPUT_GITHUB_TOKEN}" | jq ".jobs[] | select(.name | test(\"${INPUT_JOB_UUID}\")) | .id")
      if  [[ ! -z "$job_id" ]]
      then
        # triggered workflow id found
        TRIGGERED_WORKFLOW_ID=$wf_id
        break
      fi
    done
}
