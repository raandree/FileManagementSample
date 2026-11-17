BeforeAll {
    $script:moduleName = 'FileManagementSample'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Write-TestResultSummary.ps1' {
    BeforeAll {
        $script:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..' |
            Join-Path -ChildPath '..' |
            Join-Path -ChildPath '..' |
            Join-Path -ChildPath '.github' |
            Join-Path -ChildPath 'scripts' |
            Join-Path -ChildPath 'Write-TestResultSummary.ps1'

        <#
            Writes a minimal NUnit 2.5 result file with the structure that
            Pester writes: test-results, an outer test-suite with the duration
            of the test run, and one test-case element for each test.
        #>
        function New-NUnitResultFile
        {
            param
            (
                [Parameter(Mandatory = $true)]
                [System.String]
                $FilePath,

                [Parameter(Mandatory = $true)]
                [System.String]
                $Duration,

                [Parameter(Mandatory = $true)]
                [System.Collections.Hashtable[]]
                $TestCase
            )

            $document = New-Object -TypeName 'System.Xml.XmlDocument'
            $resultsElement = $document.AppendChild($document.CreateElement('test-results'))
            $suiteElement = $resultsElement.AppendChild($document.CreateElement('test-suite'))
            $suiteElement.SetAttribute('time', $Duration)
            $caseParentElement = $suiteElement.AppendChild($document.CreateElement('results'))

            foreach ($case in $TestCase)
            {
                $caseElement = $caseParentElement.AppendChild($document.CreateElement('test-case'))
                $caseElement.SetAttribute('name', $case.Name)
                $caseElement.SetAttribute('result', $case.Result)
                $caseElement.SetAttribute('time', $case.Time)

                if ($case.ContainsKey('Message'))
                {
                    $failureElement = $caseElement.AppendChild($document.CreateElement('failure'))
                    $messageElement = $failureElement.AppendChild($document.CreateElement('message'))
                    $messageElement.InnerText = $case.Message
                }
            }

            $null = New-Item -Path (Split-Path -Path $FilePath -Parent) -ItemType 'Directory' -Force
            $document.Save($FilePath)
        }
    }

    Context 'When result files of two test runs exist' {
        BeforeAll {
            $resultsPath = Join-Path -Path $TestDrive -ChildPath 'TwoRuns'

            $runAFilePath = Join-Path -Path $resultsPath -ChildPath 'RunA' |
                Join-Path -ChildPath 'NUnitXml_RunA.xml'

            New-NUnitResultFile -FilePath $runAFilePath -Duration '1.5' -TestCase @(
                @{
                    Name   = 'Suite.passes one'
                    Result = 'Success'
                    Time   = '0.25'
                }
                @{
                    Name   = 'Suite.passes two'
                    Result = 'Success'
                    Time   = '0.5'
                }
            )

            $runBFilePath = Join-Path -Path $resultsPath -ChildPath 'RunB' |
                Join-Path -ChildPath 'NUnitXml_RunB.xml'

            New-NUnitResultFile -FilePath $runBFilePath -Duration '75' -TestCase @(
                @{
                    Name   = 'Suite.passes three'
                    Result = 'Success'
                    Time   = '0.5'
                }
                @{
                    Name    = 'Suite.fails'
                    Result  = 'Failure'
                    Time    = '0.25'
                    Message = 'Expected 1, but got 2.'
                }
                @{
                    Name   = 'Suite.is skipped'
                    Result = 'Ignored'
                    Time   = '0'
                }
            )

            $summaryPath = Join-Path -Path $TestDrive -ChildPath 'two-runs.md'

            & $script:scriptPath -Path $resultsPath -SummaryPath $summaryPath

            $script:summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding 'UTF8'
        }

        It 'Should report how many test runs passed and failed' {
            $script:summary | Should -Match '2 test run\(s\) completed \(1 passed, 1 failed\)'
        }

        It 'Should report the totals of all test runs' {
            $script:summary | Should -Match '\| 5 \| 3 \| 1 \| 1 \| 60% \| 1m 16s \|'
        }

        It 'Should report one row for each test run' {
            $script:summary | Should -Match '\| RunA \| \S+ Passed \| 2 \| 2 \| 0 \| 0 \| 1\.5s \|'
            $script:summary | Should -Match '\| RunB \| \S+ Failed \| 3 \| 1 \| 1 \| 1 \| 1m 15s \|'
        }

        It 'Should list each failed test with its message' {
            $script:summary | Should -Match '\| RunB \| Suite\.fails \| Expected 1, but got 2\. \|'
        }

        It 'Should list all tests of each test run in a collapsible section' {
            $script:summary | Should -Match '<details><summary>RunB: 3 tests</summary>'
            $script:summary | Should -Match '\| Suite\.is skipped \| Ignored \| 0s \|'
        }
    }

    Context 'When a test name and a message contain Markdown table characters' {
        BeforeAll {
            $resultsPath = Join-Path -Path $TestDrive -ChildPath 'Escaping'

            $runFilePath = Join-Path -Path $resultsPath -ChildPath 'Run' |
                Join-Path -ChildPath 'NUnitXml_Run.xml'

            New-NUnitResultFile -FilePath $runFilePath -Duration '0.5' -TestCase @(
                @{
                    Name    = 'Suite.has | pipe <tag>'
                    Result  = 'Failure'
                    Time    = '0.5'
                    Message = "line one`nline two | x"
                }
            )

            $summaryPath = Join-Path -Path $TestDrive -ChildPath 'escaping.md'

            & $script:scriptPath -Path $resultsPath -SummaryPath $summaryPath

            $script:summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding 'UTF8'
        }

        It 'Should escape the characters so that the table stays intact' {
            $script:summary | Should -Match '\| Suite\.has \\\| pipe &lt;tag&gt; \| line one<br>line two \\\| x \|'
        }
    }

    Context 'When the folder contains no result files' {
        It 'Should write a notice that no result files were found' {
            $summaryPath = Join-Path -Path $TestDrive -ChildPath 'none.md'

            & $script:scriptPath -Path (Join-Path -Path $TestDrive -ChildPath 'Missing') -SummaryPath $summaryPath

            Get-Content -LiteralPath $summaryPath -Raw -Encoding 'UTF8' |
                Should -Match 'No NUnit 2\.5 test result files were found'
        }
    }

    Context 'When a result file is not in the NUnit 2.5 format' {
        BeforeAll {
            $resultsPath = Join-Path -Path $TestDrive -ChildPath 'NUnit3'
            $null = New-Item -Path $resultsPath -ItemType 'Directory' -Force

            $nunit3FilePath = Join-Path -Path $resultsPath -ChildPath 'NUnit3_Run.xml'
            Set-Content -LiteralPath $nunit3FilePath -Value '<test-run><test-case name="Suite.passes" result="Passed" /></test-run>'

            $summaryPath = Join-Path -Path $TestDrive -ChildPath 'nunit3.md'

            & $script:scriptPath -Path $resultsPath -SummaryPath $summaryPath -WarningVariable 'warningMessages' -WarningAction 'SilentlyContinue'

            $script:warningMessages = $warningMessages
            $script:summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding 'UTF8'
        }

        It 'Should skip the file with a warning' {
            $script:warningMessages | Should -Match 'not an NUnit 2\.5 result file'
            $script:summary | Should -Match 'No NUnit 2\.5 test result files were found'
        }
    }

    Context 'When no summary file is given outside GitHub Actions' {
        BeforeAll {
            $script:previousStepSummary = $env:GITHUB_STEP_SUMMARY
            $env:GITHUB_STEP_SUMMARY = $null
        }

        AfterAll {
            $env:GITHUB_STEP_SUMMARY = $script:previousStepSummary
        }

        It 'Should throw an error that names the SummaryPath parameter' {
            { & $script:scriptPath -Path $TestDrive } | Should -Throw -ExpectedMessage '*SummaryPath*'
        }
    }
}
