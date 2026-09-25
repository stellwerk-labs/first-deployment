# Module Management tutorial migration

Use compatible Orchestrator server, Runner, Console, CLI and Terraform/OpenTofu
provider versions that support Module Version Management. Run `terraform init`
with the provider version specified for your Orchestrator release. Providers
that predate Module Version Management do not support the catalogue, version
and lifecycle resources used here.

## Ownership and publication

Each Module has a catalogue entry and a separate immutable version resource.
The tutorial publishes a complete version `1.0.0`, initially Proposed, and
explicitly promotes it with a reason using `lifecycle_status = "default"`.
Module Rules depend on that publication so the first deployment can resolve
the Default. The dependency provider records exist before publication.

The tutorial owns this baseline lifecycle while `lifecycle_status` is set.
Before experimenting with a later promotion in Console or another client,
remove `lifecycle_status` and `transition_reason` from historical version
resources and apply: status becomes an observation, not a demand to restore
the predecessor. For atomic promotion of multiple Modules use the provider's
`module_lifecycle_transaction` receipt with explicitly captured numeric
resource versions. Never derive its expected revisions from live resources
that the receipt itself changes.

Resource Types are immutable contracts. To change a contract create a new Resource Type ID;
to change a Module definition publish a new complete SemVer version.

## Explicit output declarations

Each of the eleven Module Versions declares its reviewed `output_schema` as a
literal part of the complete immutable definition. The declarations equal their
bound Resource Type schemas as JSON. They are not populated from API responses,
copied automatically by the provider, or inferred from source during publication.
The source output blocks were inspected, but this is an authoring claim, not
proof of actual provider output values or a substitute for deployment tests.

A new managed publication for any nonempty Resource Type schema requires this
declaration, even without a `module_contract`. `{type="object", properties={}}`
is nonempty too; only `{}` imposes no output constraint. An unequal declaration,
even one that appears compatible, fails this conservative first implementation.
Legacy Versions keep their history. Missing output declarations are not added
retroactively.

The optional Resource Type `module_contract` may additionally constrain fixed
inputs, parameter declarations, provider mappings, dependencies, co-provisioned
resources and outputs. The tutorial does not retrofit contracts into retained
immutable Resource Types. A stricter contract requires a new Resource Type and
Module identity. Provider import/refresh must preserve any stored declaration.
These requirements apply to new publications through every supported client.
Checks against older releases do not validate this contract.

## Sources and digest claims

Every referenced source uses an immutable Git commit, not `main`, with the same
exact `source_revision`. External `artifact_digest` is optional in this
iteration; these examples deliberately omit it. Do not manufacture a digest or
treat a Git archive hash as an agreed cross-client artifact format. If an author
supplies an actual claim, its format is `sha256:<64 lowercase hexadecimal
characters>` and it remains immutable. Empty or malformed values are invalid;
inline source must always omit the field.

Both absence and a supplied claim remain Unverified and permit otherwise
eligible publication, promotion and deployment. A revision selects source but
does not verify content integrity. Trusted artifact serialization, verification,
packaging and signatures are deferred. Retain the referenced Git objects for
future deployments and recovery. Neither a digest nor an output declaration
can be added later by mutating an already published Version.

## Existing Terraform/OpenTofu state

Back up state securely and stop concurrent applies before changing ownership.
Do not apply the old and new configurations at the same time. An existing
legacy Module is migrated by the Orchestrator server; do not create a duplicate
identity to avoid an import.

For each legacy Module (example address below):

```bash
terraform state rm platform-orchestrator_module.k8s_namespace
terraform import platform-orchestrator_module_catalogue_entry.k8s_namespace k8s-namespace
```

Use the actual existing slug, not an assumed ID. Do not run apply between
removing old state ownership and importing its replacement. Review the full
plan before applying. The server may retain legacy versions named v0/v1;
these are not SemVer and must not be fabricated or imported as `1.0.0`.
Publishing a first new managed SemVer version is a separate explicit action.
An already managed published version can be imported as
`<module-slug>/<version-uuid-or-semver>`.

## Teardown and a later run

`./destroy-order.sh` destroys only objects owned by its current state, in
dependency order, and stops at the first failure. `TF_BINARY=tofu` selects
OpenTofu. Environments must finish destruction while their Runners and
credentials still exist. Never bypass an Environment destroy failure by
deleting its cluster or state.

Version deletion removes Terraform ownership, not immutable server history.
Empty catalogue shells are deleted; a specifically identified retained-history
conflict archives the catalogue instead. Other conflicts remain errors.
Providers and Resource Types set `deletion_policy = "retain"` because permanent
history can still reference them. Retain means no API deletion, not Provider
archival or credential revocation. Remove the tutorial Service User manually
after the last authenticated teardown call; it was created outside this state.

A successful teardown leaves no managed resource addresses in this state,
but intentionally leaves these historical catalogue objects in Stellwerk.
Teardown does not empty the database. Do not discard state to hide a failure. To reuse
the same IDs, import the retained Provider (`<type>.<id>`), Resource Type (`<id>`),
catalogue (`<slug>`) and version (`<slug>/1.0.0`), and explicitly unarchive the
catalogue with a reason before normal deployment. Retained dependency IDs are
not all prefixed; changing only the infrastructure prefix does not avoid them.
Review an apply/no-op plan before deploying. A factory reset is not the public
tutorial teardown path.

## Qualification evidence

On 2026-09-08, the local Kubernetes reference workflow passed setup, deployment,
teardown, retained import, no-op reapply, redeployment and final teardown checks.
The test record includes the exact component and provider revisions.

Cloud and VM variants have had static checks only. They need their own runtime
tests; a successful local Kubernetes run does not validate those variants.
