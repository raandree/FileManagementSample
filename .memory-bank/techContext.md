---
status: current
last-verified: 2026-11-17
owner: active-agent
source: repository evidence
---

# Tech context

## Stack

- PowerShell script module; manifest `PowerShellVersion = '5.0'`.
- Sampler 0.120.1, InvokeBuild 5.14.23, ModuleBuilder 3.2.18,
  PSScriptAnalyzer 1.25.0, Pester 6.2.0 (all resolved from `latest` in
  `RequiredModules.psd1` into `output/RequiredModules`).
- DscResource.Test 0.20.0 (HQRM tests), DscResource.DocGenerator 0.13.0
  (wiki and external help) with PlatyPS 0.14.2.
- Dependency resolution uses PSResourceGet (`Resolve-Dependency.psd1`).

## Environment

- Local: Windows, PowerShell 7.6.4, Node.js and npm present.
- GitVersion is not installed locally, so builds fall back to version 0.0.1.
- CI: Azure Pipelines (`azure-pipelines.yml`): Build (`pack`) -> Test matrix
  (Windows PS 5.1 and 7, Ubuntu, macOS) -> Deploy (`publish`).
- PSResourceGet registers `MicrosoftArtifactRegistry` (priority 40) before
  PSGallery; the Sampler template calls `Save-PSResource` without
  `-Repository`, so `-ResolveDependency` writes one non-terminating 404 per
  module and aborts when `$ErrorActionPreference` is `Stop` (the default of
  the Azure Pipelines `PowerShell@2` task).
- Local `dotnet` has no NuGet source, so `package_module_nupkg` cannot run
  here; `pack` uses `package_psresource_nupkg` instead.
- The local clone has no `origin` remote, so the HQRM check
  `Should have CHANGELOG.md in the diff` fails locally only.

## Constraints

- `./build.ps1` is the only entry point; never call `Invoke-Pester`,
  `Invoke-Build`, or `Build-Module` directly or edit `PSModulePath`.
- Agents never commit, push, tag, or publish; the user owns Git operations.
- `.ps1` files are ASCII-only, DSC Community style, `[CmdletBinding()]` and
  `[OutputType()]` on every function, explicit .NET types.
- `source/FileManagementSample.psm1` is a placeholder; never edit it.

## Validation

- Bootstrap: `./build.ps1 -ResolveDependency -Tasks noop`
- Build and test: `./build.ps1` (or `-Tasks build` / `-Tasks test`)
- Focused test: `./build.ps1 -Tasks test -PesterPath '<file>'
  -CodeCoverageThreshold 0`. `test` uses the last build in `output/module`;
  after changing `source/` run `-Tasks build, test` instead.
- Windows PowerShell 5.1 check: run `powershell.exe -NoProfile -File
  ./build.ps1 -Tasks test` (detached) against the existing build.
- Quality gate: `./build.ps1 -Tasks hqrmtest`
- Package and docs: `./build.ps1 -Tasks pack`
- Failures: read the newest `output/testResults/NUnitXml_*.xml`.
- Agents run builds detached and tee logs to `output/agentic` (Sampler
  0.120.1 `Clean` keeps that folder).
