---
status: current
last-verified: 2026-11-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

GitHub Actions run 1 (`20bb692`) failed in `Build & Package Module`: the
first `Save-PSResource` hit a `MicrosoftArtifactRegistry` 404, which
`$ErrorActionPreference = 'stop'` made fatal. `ci.yml` now has a step that
sets PSGallery to priority 0 before the build step. The fix is uncommitted
on `main` (Decision 6, `debugging-insights.md`).

## Evidence

- Jobs API: the build step failed after 2 s; test and deploy were skipped.
  The raw job log needs a signed-in account, so the failure was reproduced.
- Clean clone of `20bb692`, `./build.ps1 -ResolveDependency -Tasks pack`
  under `stop`: fails at `Resolve-Dependency.ps1` line 986 with
  `ResourceNotFoundException` from the container registry repository.
- Same run with the new step first: `Build succeeded. 19 tasks, 0 errors`,
  no 404 in the log, `FileManagementSample.0.0.1.nupkg` produced.
- That output, tested through the GitHub `pwsh` and `powershell` step
  wrappers: 43 of 43 pass on PowerShell 7.6.4 and on Windows PowerShell 5.1.
- actionlint 1.7.12 reports no findings for `ci.yml`.

## Next step

Owner commits and pushes the fix, then confirms that run 2 is green on all
four test legs (Ubuntu and macOS are not reproducible here). To publish,
add the `GitHubToken` and `GalleryApiToken` repository secrets. Disable any
Azure DevOps pipeline that still points at the deleted `azure-pipelines.yml`.
`Get-FileExtensionSize` still takes no pipeline input (see
`systemPatterns.md`, Decision 5).
