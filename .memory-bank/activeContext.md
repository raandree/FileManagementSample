---
status: current
last-verified: 2026-11-17
owner: active-agent
source: current task evidence
---

# Active context

## Current focus

CI is green on GitHub Actions. The new `Test Results` job writes a test
summary like the Azure Pipelines Tests tab to the summary page of each run
(Decision 7). The job, its script, and the script's tests are uncommitted
on `main`.

## Evidence

- Test-first: the 9 tests in
  `tests/Unit/CI/Write-TestResultSummary.Tests.ps1` failed against a stub
  for the expected reasons, then passed.
- Fresh clone and profile: `./build.ps1 -Tasks test` passes 52 of 52 tests
  on PowerShell 7.6.4 and Windows PowerShell 5.1, with 0 build warnings.
- The `Publish Test Summary` step from `ci.yml`, run on the two NUnit files
  laid out as artifacts, wrote a 130-line summary (104 tests, 100%).
- Script Analyzer with `.vscode/analyzersettings.psd1`: no findings;
  actionlint 1.7.12: no findings.

## Next step

Owner commits and pushes, then checks the summary of the next run, which
covers all four test legs. To publish, add the `GitHubToken` and
`GalleryApiToken` repository secrets. Disable any Azure DevOps pipeline that
still points at the deleted `azure-pipelines.yml`. `Get-FileExtensionSize`
still takes no pipeline input (see `systemPatterns.md`, Decision 5).
