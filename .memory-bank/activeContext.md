---
status: current
last-verified: 2026-11-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

CI moved from Azure Pipelines to GitHub Actions: `.github/workflows/ci.yml`
replaces `azure-pipelines.yml` (Decision 6 in `systemPatterns.md`). The
change is uncommitted on `main`, which matches `origin/main`.

## Evidence

- actionlint 1.7.12 reports no findings for `ci.yml`. It rejects mutated
  copies that put a matrix expression in a step `shell` or reference an
  unknown `needs` job.
- Action majors checked against the latest releases on 2026-11-17:
  `checkout` v7.0.1, `upload-artifact` v7.0.2, `download-artifact` v8.0.2.
- `./build.ps1 -Tasks test`: 43 of 43 tests pass on PowerShell 7.6.4.

## Next step

Before the first push, the owner decides how to keep `Save-PSResource` on
PSGallery (see `techContext.md`); if the runner also lists
`MicrosoftArtifactRegistry` first, the CI build job fails at
`-ResolveDependency`. To publish, add the `GitHubToken` and
`GalleryApiToken` repository secrets. Disable any Azure DevOps pipeline that
still points at the deleted `azure-pipelines.yml`. `Get-FileExtensionSize`
still takes no pipeline input (see `systemPatterns.md`, Decision 5).
