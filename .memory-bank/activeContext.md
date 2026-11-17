---
status: current
last-verified: 2026-11-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

`Get-LargestFile` pipeline support is complete. It is committed on the local
branch `ai/get-largestfile-pipeline`, together with the earlier build
readiness work. Nothing is pushed; this clone has no remote.

## Evidence

- `./build.ps1` (build and test): 43 of 43 tests pass on PowerShell 7.6.4
  (16 QA, 27 unit, 19 of them for `Get-LargestFile`). The same 43 tests pass
  on Windows PowerShell 5.1 with `./build.ps1 -Tasks test`.
- `./build.ps1 -Tasks pack`: module, wiki content, external help, and
  `FileManagementSample.<version>.nupkg` are produced.
- `./build.ps1 -Tasks hqrmtest`: 161 of 163 pass and 1 is skipped. The
  changelog diff check fails because this clone has no `origin` remote.
- Script Analyzer reports no findings for the function and its test file.

## Next step

Owner reviews and merges the branch, and decides how to pin `Save-PSResource`
to PSGallery (see `techContext.md`) before CI runs `-ResolveDependency` with
`Stop`. `Get-FileExtensionSize` still takes no pipeline input; extend it the
same way (see `systemPatterns.md`, Decision 5) if wanted.
