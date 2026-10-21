# AI agent rules for STCOP

## Mandatory documentation entry point

Read the [installation rules](../../AGENTS.md) and follow the
[documentation reading protocol](../ixray-sgm/.ai/workflows/ai-documentation-protocol.md)
before substantive analysis, planning, review, or file changes.
Required entry points: [SGM README](../ixray-sgm/.ai/README.md),
[project overview](../ixray-sgm/.ai/overview.md), [STCOP README](.ai/README.md),
and the relevant pages from both packages selected by the protocol matrix.
Briefly name the sources read and the applicable constraints. For Lua, reading
the full SGM `script-performance.md` is mandatory; a RAG snippet does not
replace reading a document. These requirements also apply when starting
directly from the STCOP repository.

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
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **ixray-sgm-stcop** (4185 symbols, 4178 relationships, 0 execution flows).

> Index stale? Run `node .gitnexus/run.cjs analyze --index-only` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? Bootstrap with `npx`, `bunx`, or `pnpm dlx` — e.g. `bunx gitnexus@latest analyze` (npm 11 npx crash; #1939).

## Always Do

- **MUST run impact analysis before editing.** Use `impact({target: "symbolName", direction: "upstream"})` (MCP) or `node .gitnexus/run.cjs impact "symbolName" --direction upstream --repo .` (CLI fallback); report callers, processes, and risk. Never substitute grep for graph analysis.
- **MUST analyze graph changes before committing.** Use `detect_changes({scope: "all"})` (MCP) or `node .gitnexus/run.cjs detect-changes --scope all --repo .` (CLI fallback). `partial: true` or `truncated: true` is not a clean check — a zero means unseen, not unaffected; re-run it. For regression review: `detect_changes({scope: "compare", base_ref: "main"})` or `node .gitnexus/run.cjs detect-changes --scope compare --base-ref "main" --repo .`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- **MUST treat `risk: UNKNOWN` as unresolved, not as low.** An empty caller set is not evidence the symbol is unused — it can also mean the callers are not resolvable by the index (plain-object property access, dynamic dispatch, cross-language calls). `impact` pairs `UNKNOWN` with a `riskNote` saying so. Confirm with a text search before treating the symbol as safe to change or delete; do not proceed on the strength of a zero.
- When exploring unfamiliar code, use `query({search_query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.
- For security review, `explain({target: "fileOrSymbol"})` lists taint findings (source→sink flows; needs `analyze --pdg`).

## Never Do

- NEVER edit a function, class, or method before MCP/CLI impact analysis.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis, and never read `UNKNOWN` as an all-clear — it means the walk could not answer, which is the one verdict that requires confirming by other means.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit before MCP/CLI graph change analysis.

## Resources

| Resource | Use for |
| --- | --- |
| `gitnexus://repo/ixray-sgm-stcop/context` | Codebase overview, check index freshness |
| `gitnexus://repo/ixray-sgm-stcop/clusters` | All functional areas |
| `gitnexus://repo/ixray-sgm-stcop/processes` | All execution flows |
| `gitnexus://repo/ixray-sgm-stcop/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
| --- | --- |
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

## Project documentation and RAG

- Current documentation: [.ai/README.md](.ai/README.md). Use its navigation and sources before analysis.
- Documentation is indexed separately as **ixray-sgm-stcop-docs**, and source code as **ixray-sgm-stcop**. Specify repo explicitly in every GitNexus query.
- Lua maps in .ai/reference provide lexical navigation, not a proven CALLS graph. Rules and commands: [GitNexus/RAG](../ixray-sgm/.ai/rag/gitnexus.md).
- Update the relevant .ai pages when a contract changes; check links and SHA-256 with the documentation tools.
