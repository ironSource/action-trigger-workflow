#!/bin/sh
set -e

validate_args() {

  wait_interval=10
  if [ "${INPUT_WAITING_INTERVAL}" ]
  then
    wait_interval=${INPUT_WAITING_INTERVAL}
  fi

  propagate_failure=true
  if [ -n "${INPUT_PROPAGATE_FAILURE}" ]
  then
    propagate_failure=${INPUT_PROPAGATE_FAILURE}
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

  if [ -z "${INPUT_JOB_UUID}" ]
  then
    echo "Error: Job unique ID substring is a required argument."
    exit 1
  fi

  inputs=$(echo '{}' | jq)
  if [ "${INPUT_INPUTS}" ]
  then
    inputs=$(echo "${INPUT_INPUTS}" | jq)
  fi

  ref="main"
  if [ -n "$INPUT_REF" ]
  then
    ref="${INPUT_REF}"
  fi
}
