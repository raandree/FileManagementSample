---
status: current
last-verified: 2026-11-17
owner: software-engineer
source: CI run 44073236726 and local reproduction
---

# Debugging insights

## CI build step fails seconds into dependency resolution

- Symptom: `Build & Package Module` fails about 2 s after it starts. The
  only annotation is `Process completed with exit code 1`, and the raw job
  log needs a signed-in GitHub account.
- Signature (local reproduction): `ResourceNotFoundException: Response
  returned status code package: Not Found` from
  `ContainerRegistryServerAPICalls`, thrown by `Save-PSResource` at
  `Resolve-Dependency.ps1` line 986.
- Cause: without `-Repository`, `Save-PSResource` asks
  `MicrosoftArtifactRegistry` (priority 40) before PSGallery (50), and the
  404 is fatal under the `$ErrorActionPreference = 'stop'` that GitHub
  Actions prepends to `pwsh` and `powershell` steps.
- Fix: the build job step `Prefer PSGallery for dependency resolution`
  sets PSGallery to priority 0 before `./build.ps1 -ResolveDependency`.
- Reproduce: clone the failing commit into a temporary folder, which starts
  with an empty `output/RequiredModules` like a runner, and run
  `./build.ps1 -ResolveDependency -Tasks pack` detached with
  `$ErrorActionPreference = 'stop'`.
