# Structured metadata for this task. Single source of truth for paths and repo
# coordinates — RESUME.md / prompt.md / agent.json hooks all reference these
# fields rather than hard-coding the values in scattered prose.
#
# Edit this file when:
#   - the project moves to a different path on disk
#   - you start tracking the upstream repo / branch prefix
#   - you want the agent to default to a non-PROJECT_PATH workdir

name: {{TASK_NAME}}
project_path: {{PROJECT_PATH}}
repo_url: ""             # https / ssh URL of the upstream repo (fill when known)
branch_prefix: feat/     # convention for new feature branches in this project
default_workdir: {{PROJECT_PATH}}
created: {{DATE}}
