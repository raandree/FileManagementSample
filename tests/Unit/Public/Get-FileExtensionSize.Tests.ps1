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

Describe 'Get-FileExtensionSize' {
    BeforeAll {
        $script:rootPath = Join-Path -Path $TestDrive -ChildPath 'Files'
        $script:emptyPath = Join-Path -Path $TestDrive -ChildPath 'Empty'

        <#
            Each extension has a distinct file count so the ranking is
            deterministic: .txt (4 files, 1000 bytes), .log (3 files,
            6000 bytes), .bin (2 files, 12000 bytes), no extension (1 file,
            50 bytes).
        #>
        $fixtureFiles = @(
            @{
                PathSegment = @('a.txt')
                Size        = 100
            }
            @{
                PathSegment = @('b.txt')
                Size        = 200
            }
            @{
                PathSegment = @('sub', 'c.txt')
                Size        = 300
            }
            @{
                PathSegment = @('sub', 'deeper', 'd.txt')
                Size        = 400
            }
            @{
                PathSegment = @('e.log')
                Size        = 1000
            }
            @{
                PathSegment = @('sub', 'f.log')
                Size        = 2000
            }
            @{
                PathSegment = @('sub', 'deeper', 'g.log')
                Size        = 3000
            }
            @{
                PathSegment = @('h.bin')
                Size        = 5000
            }
            @{
                PathSegment = @('sub', 'i.bin')
                Size        = 7000
            }
            @{
                PathSegment = @('LICENSE')
                Size        = 50
            }
        )

        foreach ($fixtureFile in $fixtureFiles)
        {
            $filePath = $script:rootPath

            foreach ($segment in $fixtureFile.PathSegment)
            {
                $filePath = Join-Path -Path $filePath -ChildPath $segment
            }

            $null = New-Item -Path (Split-Path -Path $filePath -Parent) -ItemType 'Directory' -Force

            [System.IO.File]::WriteAllBytes($filePath, (New-Object -TypeName 'System.Byte[]' -ArgumentList $fixtureFile.Size))
        }

        $null = New-Item -Path $script:emptyPath -ItemType 'Directory' -Force
    }

    Context 'When the folder tree contains files' {
        It 'Should rank the extensions by number of files, including files in subfolders' {
            $result = FileManagementSample\Get-FileExtensionSize -Path $script:rootPath -Top 4

            @($result).Count | Should -Be 4
            $result.Extension | Should -Be @('.txt', '.log', '.bin', '')
            $result.FileCount | Should -Be @(4, 3, 2, 1)
        }

        It 'Should report the total size of each extension in gigabytes' {
            $result = FileManagementSample\Get-FileExtensionSize -Path $script:rootPath -Top 4

            $result.TotalFileSize | Should -Be @((1000 / 1GB), (6000 / 1GB), (12000 / 1GB), (50 / 1GB))
        }

        It 'Should return only the requested number of extensions' {
            $result = FileManagementSample\Get-FileExtensionSize -Path $script:rootPath -Top 2

            @($result).Count | Should -Be 2
            $result.Extension | Should -Be @('.txt', '.log')
        }

        It 'Should return objects with the properties Extension, FileCount, and TotalFileSize' {
            $result = FileManagementSample\Get-FileExtensionSize -Path $script:rootPath -Top 1

            @($result)[0].PSObject.Properties.Name | Should -Be @('Extension', 'FileCount', 'TotalFileSize')
        }
    }

    Context 'When the folder tree contains no files' {
        It 'Should return nothing for an empty folder' {
            $result = FileManagementSample\Get-FileExtensionSize -Path $script:emptyPath -Top 5

            $result | Should -BeNullOrEmpty
        }

        It 'Should return nothing when the path does not exist' {
            $missingPath = Join-Path -Path $TestDrive -ChildPath 'Missing'

            $result = FileManagementSample\Get-FileExtensionSize -Path $missingPath -Top 5

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When the parameters are not valid' {
        It 'Should throw when Path is an empty string' {
            { FileManagementSample\Get-FileExtensionSize -Path '' -Top 1 } |
                Should -Throw -ErrorId 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Get-FileExtensionSize'
        }

        It 'Should throw when Top is not a number' {
            { FileManagementSample\Get-FileExtensionSize -Path $script:rootPath -Top 'many' } |
                Should -Throw -ErrorId 'ParameterArgumentTransformationError,Get-FileExtensionSize'
        }
    }
}
