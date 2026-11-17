---
status: current
last-verified: 2026-11-17
owner: active-agent
source: repository evidence
---

# Progress

## Current status

`build`, `test`, and `pack` are green. `hqrmtest` last passed except for
the changelog diff check, which then had no git remote. GitHub Actions CI
is green since the repository store fix; the test summary job is not
pushed yet.

## Recent milestones

- 2026-11-16: Memory Bank initialized from repository evidence.
- 2026-11-16: Added comment-based help, unit tests, README, about topic,
  wiki home page, and the `docs` and `hqrmtest` workflows.
- 2026-11-17: Made `Get-LargestFile` pipeline compatible: a `process` block,
  `Path` and `LiteralPath` parameter sets, and 11 new unit tests. It
  previously searched only the last piped path.
- 2026-11-17: Moved CI from Azure Pipelines to GitHub Actions
  (`.github/workflows/ci.yml` from the Sampler template, same four test
  platforms, deploy guarded to the owner `raandree`).
- 2026-11-17: Fixed the first GitHub Actions failure: the build job now
  sets PSGallery to priority 0 before `-ResolveDependency`.
- 2026-11-17: Fixed the second GitHub Actions failure: a fresh runner has
  no PSResourceGet repository store, so the step now creates it before
  `Set-PSResourceRepository`.
- 2026-11-17: Added the `Test Results` job, which writes a summary of all
  test runs to the summary page of each GitHub Actions run.

## Stable capabilities

- `./build.ps1` builds the module and runs QA and unit tests.
- `./build.ps1 -Tasks pack` produces the package, external help, and wiki.
- `Get-LargestFile` and `Get-FileExtensionSize` have complete help.
- `Get-LargestFile` accepts folder paths and folder objects from the
  pipeline; `Top` applies to each path.

## Open work

- Push the test summary job and check its summary on GitHub Actions.
- Add the `GitHubToken` and `GalleryApiToken` secrets before releasing, and
  disable any Azure DevOps pipeline that used `azure-pipelines.yml`.
- Optionally run `hqrmtest` in CI and replace placeholder manifest metadata
  (author `Me`, no project or license URI, no license file).
