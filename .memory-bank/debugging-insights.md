---
status: current
last-verified: 2026-11-17
owner: software-engineer
source: CI runs 1 and 2 and fresh-profile reproductions
---

# Debugging insights

## Simulate a fresh runner locally

A runner starts with an empty user profile; this machine does not. Before
trusting a local CI check, run each step in a child `pwsh` whose
`USERPROFILE`, `HOME`, `LOCALAPPDATA`, and `APPDATA` point to an empty
folder, prepend `$ErrorActionPreference = 'stop'` to the step script, and
use a fresh clone so `output/RequiredModules` starts empty.

## CI build step fails seconds into dependency resolution

- Symptom: `Build & Package Module` fails about 2 s after it starts. The
  only annotation is `Process completed with exit code 1`, and the raw job
  log needs a signed-in GitHub account.
- Signature (local reproduction): `ResourceNotFoundException: Response
  returned status code package: Not Found` from
  `ContainerRegistryServerAPICalls`, thrown by `Save-PSResource` at
  `Resolve-Dependency.ps1` line 986.
- Cause: PSResourceGet 1.3.1, which `Resolve-Dependency.ps1` bootstraps,
  creates the repository store with `MicrosoftArtifactRegistry` (priority
  40) ahead of PSGallery (50). Without `-Repository`, `Save-PSResource`
  asks it first, and its 404 is fatal under the
  `$ErrorActionPreference = 'stop'` that GitHub Actions prepends to `pwsh`
  and `powershell` steps.
- Fix: the build job step `Prefer PSGallery for dependency resolution`
  sets PSGallery to priority 0 before `./build.ps1 -ResolveDependency`.

## `Set-PSResourceRepository` fails on a fresh runner

- Symptom: the step fails with "Cannot retrieve the dynamic parameters for
  the cmdlet. Loading repository store failed: Could not find a part of the
  path" for `PSResourceGet/PSResourceRepository.xml`.
- Cause: the cmdlet loads the repository store while binding its dynamic
  parameters, and a fresh profile has no store yet.
- Fix: call `Get-PSResourceRepository` first; it creates the store.
