# action-trigger-workflow
Trigger GitHub action workflow file from another repo and wait to it will be done.

## Example usage

Here is an example setup of this action:

1. Create a `.github/workflows/ci-initiator.yml` file in your GitHub repo.
2. Add the following code to the file.

```yml
name: CI-Initiator

on:
  push:

jobs:
  startCI:
    runs-on: ubuntu-latest
    steps:
      - name: Generate Unique runer id
        id: vars
        run: |
          echo ::set-output name=sha_short::${GITHUB_SHA::7}
          echo ::set-output name=uuid::${{github.ref_name}}:${GITHUB_SHA::7}:${GITHUB_RUN_ID}

      - name: Trigger Remote Action
        uses: AndyKIron/trigger-action-workflow@main
        with:
          owner: REMOTE_REPO_OWNER # remote repository owner
          repo: REMOTE_REPO_NAME #remote repository name
          github_token: ${{ secrets.PAT_TOKEN }} # your token
          workflow_file_name: ci.yml # remote action workflow file name
          job_uuid: "${{ steps.vars.outputs.uuid }}"
          inputs: '{ "branch_name": "${{github.ref_name}}", "user": "${{github.actor}}", "uuid": "${{ steps.vars.outputs.uuid }}", "sha": "${{ steps.vars.outputs.sha_short }}", "event_name": "${{github.event_name}}", "event_action": "${{github.event.action}}"}'
```

### Inputs (with)

| Variable           |          | Purpose                                                                                                |
|--------------------|----------|--------------------------------------------------------------------------------------------------------|
| owner              | required | Remote repository owner name                                                                           |
| repo               | required | Remote repository name                                                                                 |
| github_token       | required | Generated Personal Access Token                                                                        |
| workflow_file_name | required | Remote action workflow filename (with .extension)                                                      |
| job_uuid           | required | Unique string to identify the running remote action workflow                                           |
| inputs             | required | JSON for remote action inputs                                                                          |
| ref                | false    | The reference of the workflow run. The reference can be a branch, tag, or a commit SHA. Default "main" |
| wait_interval      | false    | The number of seconds delay between checking for result of run. Default - 10 sec                       |
| propagate_failure  | false    | Fail current job if downstream job fails. Default - true                                               |
| wait_workflow      | false    | Wait for workflow to finish. Default - true                                                            |



3. On remote target action workflow file (ci.yml for example) you need add needed inputs
4. And one (first) stem must have "name:" with "job_name_substring"

```yml
name: CI-Starter

on:
  workflow_dispatch:
    inputs:
      branch_name:
        required: true
      user:
        required: true
      uuid:
        required: true

jobs:
  # --- Do Job Initiator for ci_initiator can find it in from API in jpb name
  ci-init:
    name: 'CI-Init::${{ github.event.inputs.uuid }}'
    runs-on: ubuntu-latest
    steps:
      - run: |
          echo "Start CI for ${{ github.event.inputs.user }}:${{ github.event.inputs.uuid }}"
  ...
  ...
  ...
```



