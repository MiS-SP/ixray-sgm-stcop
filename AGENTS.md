# STCOP addon rules

Read the [installation rules](../../AGENTS.md) even when starting in this repo.
Follow their [reading protocol](../ixray-sgm/.ai/workflows/ai-documentation-protocol.md),
then use [STCOP documentation](.ai/README.md) and the affected SGM contract.
STCOP is optional: its data and registrations must remain in this package.

## Mandatory configuration and DLTX rules

Before modifying weapon LTX files, read the [data ownership and DLTX rules](../ixray-sgm/docs/weapon-dltx-layers.md). They are mandatory for weapons, ammunition, HUD, profiles, and upgrades.

- Fix owned definitions in the owner's file. Use DLTX only to intentionally change another owner's section.
- Shared calibers and their base balance belong to SGM. Do not copy their parameters into STCOP for manual synchronization.
- Keep only justified differences from the effective base in a patch, accounting for inheritance. Do not duplicate numerically equal values. Do not treat an old copied number overriding a newer user change to the base as an intentional difference without confirmation.
- Document the reason for a real difference next to the field or group. Do not repeat parents without an intentional inheritance change or add a late patch to compensate for an earlier duplicate.
- To restore the base value, remove the assignment from the patch; do not replace it with a key-deletion operation or an empty value.
- Remove empty sections; remove an empty file together with its exact include. Stubs and broad patterns that hide missing files are prohibited.
- After a change, verify both SGM and SGM + STCOP, effective values, and includes; for upgrades, verify both INI contexts. When removing copies, check that a shared-base change propagates to STCOP without a second edit.
- Preserve local user changes, encodings, and line endings. The original gamedata is read-only.

<!-- gitnexus:start -->
## Code analysis and documentation

Use the shared [GitNexus guide](../ixray-sgm/.ai/rag/gitnexus.md).
Specify repo explicitly: ixray-sgm-stcop for source, ixray-sgm-stcop-docs for docs.

- Before a symbol edit, run upstream impact and inspect callers/processes/risk.
  Warn on HIGH/CRITICAL; UNKNOWN and empty results require source/text checks.
- Use query for concepts and context for named symbols. Verify dynamic Lua,
  XML and LTX consumers directly; a missing edge does not prove absence.
- Use GitNexus rename for symbols instead of blind find-and-replace.
- Before committing, run detect_changes for the intended scope. Re-run partial
  or truncated results. For regression comparison, use the actual base ref
  (this repository uses main), not the SGM branch name.
- Text-only documentation edits do not require a symbol impact query.

Update relevant .ai pages when their contracts change and run the shared
[documentation checks](../ixray-sgm/.ai/rag/maintenance.md).
<!-- gitnexus:end -->
