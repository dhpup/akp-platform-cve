#!/usr/bin/env bash
# Resets this repo to its pristine (prospect-ready) state after a demo/test run.
#
# What it does:
#   1. Force-pushes the `pristine` tag back onto main (undoes personalize.sh
#      and any promotion commits Kargo made to main)
#   2. Deletes all remote env/* branches (the rendered branches Kargo pushed)
#   3. Resets your local checkout to match
#
# What it does NOT do (do these first / separately):
#   - Delete the Argo CD root app. Run this BEFORE resetting so the
#     ApplicationSets prune everything and Kargo stops pushing:
#       argocd app delete platform-aoa --cascade
#   - Clean up the monorepo (test tags, releases, GHCR packages)
#   - Touch your Akuity instances or clusters

set -e

if ! git rev-parse -q --verify refs/tags/pristine >/dev/null; then
  echo "ERROR: no 'pristine' tag found. Tag your prospect-ready commit first:" >&2
  echo "  git tag pristine && git push origin pristine" >&2
  exit 1
fi

echo "This will FORCE-PUSH main back to the 'pristine' tag and delete all"
echo "remote env/* branches. Anything committed to main since the tag is lost."
echo -n "Continue? [y/N] "
read -r answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo "Aborted."
  exit 1
fi

echo "==> Resetting main to 'pristine'"
git push --force origin refs/tags/pristine:refs/heads/main

echo "==> Deleting remote env/* branches"
branches=$(git ls-remote --heads origin 'env/*' | sed 's#.*refs/heads/##')
if [[ -n "$branches" ]]; then
  # shellcheck disable=SC2086
  git push origin --delete $branches
else
  echo "    (none found)"
fi

echo "==> Resetting local checkout"
git checkout main
git fetch origin --prune
git reset --hard pristine

echo ""
echo "Done. main is back to the pristine, prospect-ready state."
echo "Reminders:"
echo "  - If you haven't already: argocd app delete platform-aoa --cascade"
echo "  - Remove Kargo git credentials if you created them (kargo delete credentials ...)"
echo "  - Monorepo cleanup (if used): delete test tags/releases and GHCR versions"
