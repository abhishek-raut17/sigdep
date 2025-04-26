# Git Branching & Merging Strategy

This document outlines the Git strategy used for collaborative development in this project. It ensures a clear flow of code changes from development to production, strict control over merge policies, and comprehensive commit histories.

| **Branch**   | **Purpose**                          | **Naming Pattern**       | **Created From** | **Merged Into** | **Merge Strategy** | **Notes**                                                                 |
|--------------|--------------------------------------|---------------------------|------------------|-----------------|--------------------|---------------------------------------------------------------------------|
| `main`       | Immutable production source         | `main`                    | —                | —               | 🟫 Squash Merge    | 🔒 Locked from direct creation & commits. Updated only via squash merges from `deploy`. |
| `deploy`     | Deploy-ready state                  | `deploy`                  | `main` (once)    | `main`          | 🟦 Squash Merge    | Never deleted or recreated. All deployments are based on this branch.    |
| `feature`    | Groups related stories              | `feature/SIGDEP-*`        | `deploy`         | `deploy`        | 🔀 Standard Merge  | Represents a collection of related stories.                              |
| `story`      | Basic unit of development           | `story/TX-<ticket_number>`| `feature/*`      | `feature/*`     | 🟦 Squash Merge    | Contains subtasks of a feature.                                          |

## Detailed Branch Strategy

### `story/TX-<int>`

- **Purpose**: Basic unit of development. Represents a single story or task.
- **Naming Pattern**: `story/TX-<ticket_number>`
- **Created From**: Relevant `feature/*` branch.
- **Merged Into**: The same `feature/*` branch.
- **Merge Strategy**: 🟦 Squash Merge
- **Squash Commit Format**:

    ```text
    feat(TX-<int>): Story Title

        - Subtask 1
        - Subtask 2
        - ...
    ```

### `feature/SIGDEP-*`

- **Purpose**: Groups together related stories (story branches).
- **Naming Pattern**: `feature/SIGDEP-*`
- **Created From**: `deploy`
- **Merged Into**: `deploy`
- **Merge Strategy**: 🔀 Standard Merge
- **Merge Commit Format**:

    ```text
    Merge branch 'feature/SIGDEP-*'

        Stories:
        - TX-101: User login
        - TX-102: OAuth integration
    ```

### `deploy`

- **Purpose**: Represents the deploy-ready state. Only `feature/*` branches are merged here.
- **Created From**: `main` (at project start)
- **Merged Into**: `main`
- **Merge Strategy into main**: 🟦 Squash Merge
- **Other Rules**:
  - Never deleted or recreated.
  - All deployments are based on this branch.

### `main`

- **Purpose**: Immutable production source.
- **Created Once**: At project initialization.
- **Updated By**: Only via squash merges from `deploy`.
- **Merge Strategy**: 🟫 Squash Merge
- **Commit Title**: Descriptive Release Title (e.g., Release 1.0.0)
- **Squash Message Format**:

    ```text
    Release 1.0.0

        Features:
        - SIGDEP-10: Auth service
        - SIGDEP-11: Billing module
    ```

### 🏷️ Release Tags

- **When**: After every merge into `main`.
- **Tag Name**: Semantic version or release code (e.g., `v1.0.0`).
- **Source**: The commit created by squash merge into `main`.
- **Purpose**: Represents a deployable, immutable release snapshot.

## Merge Policy Summary

| **From**     | **To**       | **Merge Strategy** | **Commit Rules**                                                                 |
|--------------|--------------|--------------------|---------------------------------------------------------------------------------|
| `story/*`    | `feature/*`  | 🟦 Squash          | **Title**: Story name **Body**: Subtasks                                     |
| `feature/*`  | `deploy`     | 🔀 Standard Merge  | **Title**: Feature name **Body**: List of stories                           |
| `deploy`     | `main`       | 🟦 Squash          | **Title**: Release title **Body**: List of features                         |
| Any to `main`| ❌           | 🚫 Forbidden       | Only `deploy` can merge into `main`.                                           |

## Summary Checklist

✅ Always use signed commits
✅ No direct commits to main or deploy
✅ Follow naming conventions strictly
✅ Write clear squash messages
✅ Create release tags from main squash commits
