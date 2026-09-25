#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
tf_binary=${TF_BINARY:-terraform}
case "$tf_binary" in
  terraform|tofu) ;;
  *) echo 'TF_BINARY must be terraform or tofu' >&2; exit 1 ;;
esac
command -v "$tf_binary" >/dev/null

printf '%s\n' \
  'This destroys the infrastructure owned by this tutorial state.' \
  'Published Module Versions remain in Stellwerk; catalogue entries are archived.' \
  'Providers and Resource Types configured with deletion_policy=retain remain.' \
  'An Environment failure stops cleanup before its Runner or credentials are removed.'
read -r -p 'Type destroy-my-infrastructure to continue: ' confirmation
if [[ "$confirmation" != destroy-my-infrastructure ]]; then
  echo 'Cancelled.'
  exit 0
fi

destroy_resources() {
  local resource_type=$1 address state
  local targets=()
  state=$("$tf_binary" state list)
  while IFS= read -r address; do
    if [[ "$address" =~ (^|\.)${resource_type}\. ]]; then
      targets+=("-target=$address")
    fi
  done <<<"$state"
  if [[ ${#targets[@]} -gt 0 ]]; then
    printf 'Destroying %s (%s state resources)...\n' "$resource_type" "${#targets[@]}"
    "$tf_binary" destroy "${targets[@]}" -auto-approve
  fi
}

# Target only exact resource addresses discovered in this state. In particular,
# never continue to Runner teardown after failed Environment destruction.
destroy_resources platform-orchestrator_environment
destroy_resources platform-orchestrator_module_rule
destroy_resources platform-orchestrator_module_version
destroy_resources platform-orchestrator_module_catalogue_entry

"$tf_binary" destroy -auto-approve
remaining=$("$tf_binary" state list)
if [[ -n "$remaining" ]]; then
  printf 'Cleanup left state resources; inspect before retrying:\n%s\n' "$remaining" >&2
  exit 1
fi
echo 'Tutorial runtime removed. Immutable catalogue history and explicitly retained dependencies remain.'
echo 'Remove the tutorial Service User after this final authenticated operation.'
