# Task Name — Workflow

> Process definition for this task.

## Overview

Describe what this task automates or accomplishes.

## Stages

| Stage | Description |
|-------|-------------|
| prepare | Setup environment |
| build | Compile/build |
| test | Run tests |
| deploy | Deploy to target |

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TARGET_HOST` | Deploy target | `localhost` |
| `VERSION` | Release version | `1.0.0` |

## Trigger

- Manual: `when: manual`
- Auto: On tag creation
