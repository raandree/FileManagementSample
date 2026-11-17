---
status: current
last-verified: 2026-11-16
owner: shared
source: repository evidence
---

# Project brief

## Purpose

`FileManagementSample` is a PowerShell script module that reports on disk
usage of a folder tree. It was scaffolded from the Sampler `SimpleModule`
template and is built, tested, packaged, and published through Sampler.

## Scope

- In scope: public commands `Get-LargestFile` and `Get-FileExtensionSize`,
  their help and tests, and the Sampler build, test, docs, and publish
  workflows.
- Out of scope: To confirm.

## Stakeholders

- Module owner: To confirm (manifest still lists the placeholder author `Me`).

## Acceptance criteria

1. `./build.ps1` (workflows `build` and `test`) passes.
2. `./build.ps1 -Tasks hqrmtest` (documented quality gate) passes.
3. `./build.ps1 -Tasks pack` produces the module package and wiki content.
4. Every public command has complete comment-based help and a unit test.
