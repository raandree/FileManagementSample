---
status: current
last-verified: 2026-11-17
owner: active-agent
source: repository evidence
---

# System patterns

## Architecture

- `source/Public/*.ps1`: one exported function per file; ModuleBuilder merges
  them into `output/module/FileManagementSample/<version>/` and fills
  `FunctionsToExport`.
- `source/en-US/about_FileManagementSample.help.txt`: conceptual help, copied
  through `CopyPaths` in `build.yaml`.
- `source/WikiSource/`: hand-authored wiki pages copied into
  `output/WikiContent` by the `docs` workflow.
- `tests/QA/module.tests.ps1`: quality gate (changelog format, import, unit
  test per function, Script Analyzer, help completeness).
- `tests/Unit/Public/<Function>.Tests.ps1`: unit tests using `$TestDrive`.
- `build.yaml`: workflows `build`, `test`, `docs`, `pack`, `hqrmtest`,
  `publish`.

## Decisions

### Decision 1: Use the canonical Memory Bank base

- Choice: Keep durable project context in .memory-bank.
- Rationale: Preserve evidence-backed context across sessions.

### Decision 2: Complete the build wiring the repository already declares

- Choice: Import DscResource.Test and DscResource.DocGenerator tasks, add
  `hqrmtest` and `docs` workflows, package with `package_psresource_nupkg`,
  and use the nested `DscTest.Pester` / `DscTest.Script` layout.
- Rationale: `copilot-instructions.md` names `hqrmtest` as the quality gate,
  `wiki-publishing.instructions.md` prescribes the docs and pack workflows,
  and DscResource.Test 0.20.0 ignores the flat `DscTest` keys that the
  Sampler 0.120.1 template still generates.

### Decision 3: Keep command behavior stable while adding help

- Choice: Add help, `[CmdletBinding()]`, `[OutputType()]`, and explicit types
  without changing results, ranking, units, or error handling.
- Rationale: The request was build readiness and documentation; behavior
  changes need an explicit decision from the owner.

### Decision 4: Satisfy HQRM conventions instead of excluding checks

- Choice: Ship `en-US/FileManagementSample.strings.psd1` (no keys yet) and
  keep the changelog diff check enabled.
- Rationale: Excluding a failing check to get a green gate hides problems.

### Decision 5: Give path-taking commands the standard pipeline contract

- Choice: `Get-LargestFile` has `Path` (wildcards; by value and by property
  name) and `LiteralPath` (alias `PSPath`; by property name) in separate
  parameter sets, both `[System.String[]]`, and a `process` block. Each path
  is searched on its own, so `Top` applies per path and output streams per
  input. `Position` is explicit (`Path` 0, `Top` 1) to keep positional calls.
- Rationale: The shared PowerShell Instruction (Pipeline Design) prescribes
  this. Folder objects from `Get-ChildItem` bind through `PSPath`, so names
  with square brackets stay literal; Windows PowerShell 5.1 converts a piped
  `DirectoryInfo` to its name only, so by-value binding alone returns
  nothing there. Per-path `Top` avoids buffering across inputs and makes
  `Get-ChildItem -Directory | Get-LargestFile -Top 1` possible.
