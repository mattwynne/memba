#!/usr/bin/env bash
# Helpers for commits made by Memba's Fabro workflow scripts.
#
# Keep the identity scoped to the single git command. Do not write repo-local
# git config here: Fabro reuses the sandbox repository for checkpoint commits,
# so persistent config can leak into later automation commits.

fabro_git_author_name() {
  printf '%s' "${FABRO_GIT_AUTHOR_NAME:-Fabro}"
}

fabro_git_author_email() {
  printf '%s' "${FABRO_GIT_AUTHOR_EMAIL:-noreply@fabro.sh}"
}

fabro_git_committer_name() {
  printf '%s' "${FABRO_GIT_COMMITTER_NAME:-${FABRO_GIT_AUTHOR_NAME:-Fabro}}"
}

fabro_git_committer_email() {
  printf '%s' "${FABRO_GIT_COMMITTER_EMAIL:-${FABRO_GIT_AUTHOR_EMAIL:-noreply@fabro.sh}}"
}

fabro_git_with_identity() {
  local author_name author_email committer_name committer_email
  author_name=$(fabro_git_author_name)
  author_email=$(fabro_git_author_email)
  committer_name=$(fabro_git_committer_name)
  committer_email=$(fabro_git_committer_email)

  GIT_AUTHOR_NAME="$author_name" \
  GIT_AUTHOR_EMAIL="$author_email" \
  GIT_COMMITTER_NAME="$committer_name" \
  GIT_COMMITTER_EMAIL="$committer_email" \
    git \
      -c "user.name=$committer_name" \
      -c "user.email=$committer_email" \
      "$@"
}

fabro_git_commit() {
  fabro_git_with_identity commit "$@"
}

fabro_git_commit_tree() {
  fabro_git_with_identity commit-tree "$@"
}
