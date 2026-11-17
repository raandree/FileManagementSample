---
status: current
last-verified: 2026-11-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

GitHub Actions run 2 (`a5083df`) failed in the new step: on a fresh runner
the PSResourceGet repository store does not exist, so
`Set-PSResourceRepository` could not load its dynamic parameters. The step
now calls `Get-PSResourceRepository` first, which creates the store. The fix
is uncommitted on `main` (`debugging-insights.md`).

## Evidence

- Fresh-profile simulation (`USERPROFILE`, `HOME`, `LOCALAPPDATA`, and
  `APPDATA` redirected to an empty folder): the run 2 step fails with the
  same message; with `Get-PSResourceRepository` first it succeeds.
- Fresh clone of `a5083df` with a fresh profile, steps read from `ci.yml`:
  the build step alone fails with the run 1 404, and the bootstrapped
  PSResourceGet 1.3.1 has registered `MicrosoftArtifactRegistry` (40).
  With the fixed step first: `Build succeeded. 19 tasks, 0 errors`, no 404,
  and the store holds only PSGallery at priority 0.
- actionlint 1.7.12 reports no findings for `ci.yml`.

## Next step

Owner commits and pushes the fix, then confirms that run 3 is green on all
four test legs (Ubuntu and macOS are not reproducible here). To publish,
add the `GitHubToken` and `GalleryApiToken` repository secrets. Disable any
Azure DevOps pipeline that still points at the deleted `azure-pipelines.yml`.
`Get-FileExtensionSize` still takes no pipeline input (see
`systemPatterns.md`, Decision 5).
