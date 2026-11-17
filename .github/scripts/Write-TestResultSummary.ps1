<#
    .SYNOPSIS
        Writes a Markdown summary of NUnit test results to the GitHub Actions
        job summary.

    .DESCRIPTION
        The script searches the folder specified by the Path parameter and all
        of its subfolders for NUnit 2.5 XML files whose names start with
        NUnit, such as the files that the Sampler test workflow writes to the
        folder output/testResults. Each file is one test run. A test run is
        named after the folder that contains the file, or after the file when
        it is directly in the folder specified by the Path parameter.

        The summary shows the totals of all test runs, one row for each test
        run, the failed tests with their messages, and a collapsible list of
        all tests of each test run. Tests that neither passed nor failed, for
        example skipped tests, are counted as others. Files in another format
        are skipped with a warning. The summary is appended to the file
        specified by the SummaryPath parameter.

    .PARAMETER Path
        Specifies the folder to search for NUnit XML files.

    .PARAMETER SummaryPath
        Specifies the file to append the summary to. The default is the file
        in the environment variable GITHUB_STEP_SUMMARY, which GitHub Actions
        shows on the summary page of the workflow run.

    .PARAMETER Title
        Specifies the heading of the summary.

    .EXAMPLE
        ./.github/scripts/Write-TestResultSummary.ps1 -Path ./testResults

        Appends the summary of all NUnit files below the folder testResults to
        the job summary of the current GitHub Actions step.

    .EXAMPLE
        ./.github/scripts/Write-TestResultSummary.ps1 -Path ./output/testResults -SummaryPath ./summary.md

        Appends the summary of a local test run to the file summary.md.
#>
[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [System.String]
    $Path,

    [Parameter()]
    [System.String]
    $SummaryPath = $env:GITHUB_STEP_SUMMARY,

    [Parameter()]
    [System.String]
    $Title = 'Test results'
)

<#
    .SYNOPSIS
        Escapes text so that it can be used in a cell of a Markdown table.
#>
function ConvertTo-MarkdownTableText
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $Text
    )

    $escapedText = $Text.Trim().Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('|', '\|')

    return ($escapedText -replace '\r?\n', '<br>')
}

<#
    .SYNOPSIS
        Converts an NUnit time attribute in seconds to a number, or to 0 when
        the value is missing or invalid.
#>
function ConvertFrom-NUnitTime
{
    [CmdletBinding()]
    [OutputType([System.Double])]
    param
    (
        [Parameter()]
        [System.String]
        $Value
    )

    $seconds = [System.Double] 0
    $numberStyle = [System.Globalization.NumberStyles]::Float
    $culture = [System.Globalization.CultureInfo]::InvariantCulture

    $null = [System.Double]::TryParse($Value, $numberStyle, $culture, [ref] $seconds)

    return $seconds
}

<#
    .SYNOPSIS
        Formats a duration in seconds, for example as 1.5s or as 1m 15s.
#>
function Format-TestDuration
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Double]
        $Seconds
    )

    if ($Seconds -ge 60)
    {
        $timeSpan = [System.TimeSpan]::FromSeconds($Seconds)

        return ('{0}m {1}s' -f [System.Math]::Floor($timeSpan.TotalMinutes), $timeSpan.Seconds)
    }

    return [System.String]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:0.##}s', $Seconds)
}

if ([System.String]::IsNullOrEmpty($SummaryPath))
{
    throw 'No summary file was specified. Pass the SummaryPath parameter, or run the script in a GitHub Actions step, which sets GITHUB_STEP_SUMMARY.'
}

$passedSymbol = [System.Char]::ConvertFromUtf32(0x2705)
$failedSymbol = [System.Char]::ConvertFromUtf32(0x274C)

$resultFiles = @()

if (Test-Path -LiteralPath $Path -PathType 'Container')
{
    $rootPath = (Get-Item -LiteralPath $Path).FullName

    $resultFiles = @(
        Get-ChildItem -LiteralPath $Path -Filter 'NUnit*.xml' -File -Recurse |
            Sort-Object -Property 'FullName'
    )
}

$testRuns = @(
    foreach ($resultFile in $resultFiles)
    {
        $document = New-Object -TypeName 'System.Xml.XmlDocument'
        $document.Load($resultFile.FullName)

        if ($document.DocumentElement.LocalName -ne 'test-results')
        {
            # Invoke-Build replaces Write-Warning to collect warnings, which ignores -WarningAction.
            Microsoft.PowerShell.Utility\Write-Warning -Message ('Skipping the file {0} because it is not an NUnit 2.5 result file.' -f $resultFile.FullName)

            continue
        }

        $tests = @(
            foreach ($testCase in $document.SelectNodes('//test-case'))
            {
                $result = $testCase.GetAttribute('result')
                $outcome = 'Other'

                if ($result -eq 'Success')
                {
                    $outcome = 'Passed'
                }
                elseif ($result -in @('Failure', 'Error'))
                {
                    $outcome = 'Failed'
                }

                $message = ''
                $messageNode = $testCase.SelectSingleNode('failure/message')

                if ($messageNode)
                {
                    $message = $messageNode.InnerText
                }

                [PSCustomObject]@{
                    Name     = $testCase.GetAttribute('name')
                    Result   = $result
                    Outcome  = $outcome
                    Duration = ConvertFrom-NUnitTime -Value $testCase.GetAttribute('time')
                    Message  = $message
                }
            }
        )

        $runName = $resultFile.Directory.Name

        if ($resultFile.DirectoryName -eq $rootPath)
        {
            $runName = $resultFile.BaseName
        }

        # The outer test-suite element holds the duration of the whole run.
        $duration = [System.Double] 0
        $suiteNode = $document.SelectSingleNode('/test-results/test-suite')

        if ($suiteNode -and $suiteNode.HasAttribute('time'))
        {
            $duration = ConvertFrom-NUnitTime -Value $suiteNode.GetAttribute('time')
        }
        else
        {
            foreach ($test in $tests)
            {
                $duration += $test.Duration
            }
        }

        [PSCustomObject]@{
            Name        = $runName
            Tests       = $tests
            TotalCount  = $tests.Count
            PassedCount = @($tests | Where-Object -FilterScript { $_.Outcome -eq 'Passed' }).Count
            FailedCount = @($tests | Where-Object -FilterScript { $_.Outcome -eq 'Failed' }).Count
            Duration    = $duration
        }
    }
)

$lines = New-Object -TypeName 'System.Collections.Generic.List[System.String]'
$lines.Add(('## {0}' -f $Title))
$lines.Add('')

if ($testRuns.Count -eq 0)
{
    $lines.Add(('No NUnit 2.5 test result files were found in {0}.' -f (ConvertTo-MarkdownTableText -Text $Path)))
}
else
{
    $totalCount = 0
    $passedCount = 0
    $failedCount = 0
    $totalDuration = [System.Double] 0

    foreach ($testRun in $testRuns)
    {
        $totalCount += $testRun.TotalCount
        $passedCount += $testRun.PassedCount
        $failedCount += $testRun.FailedCount
        $totalDuration += $testRun.Duration
    }

    $failedRunCount = @($testRuns | Where-Object -FilterScript { $_.FailedCount -gt 0 }).Count
    $passPercentage = 'n/a'

    if ($totalCount -gt 0)
    {
        $passPercentage = [System.String]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:0.#}%', 100 * $passedCount / $totalCount)
    }

    $lines.Add(('{0} test run(s) completed ({1} passed, {2} failed)' -f $testRuns.Count, ($testRuns.Count - $failedRunCount), $failedRunCount))
    $lines.Add('')
    $lines.Add('| Total tests | Passed | Failed | Others | Pass percentage | Duration |')
    $lines.Add('| ---: | ---: | ---: | ---: | ---: | ---: |')
    $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f $totalCount, $passedCount, $failedCount, ($totalCount - $passedCount - $failedCount), $passPercentage, (Format-TestDuration -Seconds $totalDuration)))
    $lines.Add('')
    $lines.Add('| Test run | Outcome | Total | Passed | Failed | Others | Duration |')
    $lines.Add('| --- | --- | ---: | ---: | ---: | ---: | ---: |')

    foreach ($testRun in $testRuns)
    {
        $outcomeText = '{0} Passed' -f $passedSymbol

        if ($testRun.FailedCount -gt 0)
        {
            $outcomeText = '{0} Failed' -f $failedSymbol
        }

        $otherCount = $testRun.TotalCount - $testRun.PassedCount - $testRun.FailedCount

        $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f (ConvertTo-MarkdownTableText -Text $testRun.Name), $outcomeText, $testRun.TotalCount, $testRun.PassedCount, $testRun.FailedCount, $otherCount, (Format-TestDuration -Seconds $testRun.Duration)))
    }

    if ($failedCount -gt 0)
    {
        $lines.Add('')
        $lines.Add('### Failed tests')
        $lines.Add('')
        $lines.Add('| Test run | Test | Message |')
        $lines.Add('| --- | --- | --- |')

        foreach ($testRun in $testRuns)
        {
            foreach ($test in @($testRun.Tests | Where-Object -FilterScript { $_.Outcome -eq 'Failed' }))
            {
                $lines.Add(('| {0} | {1} | {2} |' -f (ConvertTo-MarkdownTableText -Text $testRun.Name), (ConvertTo-MarkdownTableText -Text $test.Name), (ConvertTo-MarkdownTableText -Text $test.Message)))
            }
        }
    }

    foreach ($testRun in $testRuns)
    {
        $lines.Add('')
        $lines.Add(('<details><summary>{0}: {1} tests</summary>' -f (ConvertTo-MarkdownTableText -Text $testRun.Name), $testRun.TotalCount))
        $lines.Add('')
        $lines.Add('| Test | Outcome | Duration |')
        $lines.Add('| --- | --- | ---: |')

        foreach ($test in $testRun.Tests)
        {
            $outcomeText = ConvertTo-MarkdownTableText -Text $test.Result

            if ($test.Outcome -eq 'Passed')
            {
                $outcomeText = '{0} Passed' -f $passedSymbol
            }
            elseif ($test.Outcome -eq 'Failed')
            {
                $outcomeText = '{0} Failed' -f $failedSymbol
            }

            $lines.Add(('| {0} | {1} | {2} |' -f (ConvertTo-MarkdownTableText -Text $test.Name), $outcomeText, (Format-TestDuration -Seconds $test.Duration)))
        }

        $lines.Add('')
        $lines.Add('</details>')
    }
}

$summaryFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SummaryPath)
$utf8NoBom = New-Object -TypeName 'System.Text.UTF8Encoding' -ArgumentList $false

[System.IO.File]::AppendAllText($summaryFilePath, (($lines -join "`n") + "`n"), $utf8NoBom)
