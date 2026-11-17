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

Describe 'Get-LargestFile' {
    BeforeAll {
        $script:rootPath = Join-Path -Path $TestDrive -ChildPath 'Files'
        $script:otherPath = Join-Path -Path $TestDrive -ChildPath 'Other'
        $script:bracketPath = Join-Path -Path $TestDrive -ChildPath 'Brackets [old]'
        $script:emptyPath = Join-Path -Path $TestDrive -ChildPath 'Empty'

        $fixtureFiles = @(
            @{
                RootPath    = $script:rootPath
                PathSegment = @('small.txt')
                Size        = 10
            }
            @{
                RootPath    = $script:rootPath
                PathSegment = @('medium.log')
                Size        = 200
            }
            @{
                RootPath    = $script:rootPath
                PathSegment = @('sub', 'large.bin')
                Size        = 3000
            }
            @{
                RootPath    = $script:rootPath
                PathSegment = @('sub', 'deeper', 'huge.dat')
                Size        = 5000
            }
            @{
                RootPath    = $script:otherPath
                PathSegment = @('notes.txt')
                Size        = 40
            }
            @{
                RootPath    = $script:otherPath
                PathSegment = @('archive.zip')
                Size        = 4000
            }
            @{
                RootPath    = $script:bracketPath
                PathSegment = @('inside.bin')
                Size        = 700
            }
        )

        foreach ($fixtureFile in $fixtureFiles)
        {
            $filePath = $fixtureFile.RootPath

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
        It 'Should return the largest files first, including files in subfolders' {
            $result = FileManagementSample\Get-LargestFile -Path $script:rootPath -Top 3

            @($result).Count | Should -Be 3
            $result.Name | Should -Be @('huge.dat', 'large.bin', 'medium.log')
            # Expand Length explicitly; $result.Length is the length of the array itself.
            $result | Select-Object -ExpandProperty 'Length' | Should -Be @(5000, 3000, 200)
        }

        It 'Should return file objects that point to the files on disk' {
            $result = FileManagementSample\Get-LargestFile -Path $script:rootPath -Top 1

            $result | Should -BeOfType ([System.IO.FileInfo])
            $result.FullName | Should -Exist
        }

        It 'Should return every file but no folders when Top exceeds the number of files' {
            $result = FileManagementSample\Get-LargestFile -Path $script:rootPath -Top 10

            @($result).Count | Should -Be 4
            $result.Name | Should -Not -Contain 'sub'
            $result.Name | Should -Not -Contain 'deeper'
        }

        It 'Should accept Path and Top by position' {
            $result = FileManagementSample\Get-LargestFile $script:rootPath 2

            $result.Name | Should -Be @('huge.dat', 'large.bin')
        }
    }

    Context 'When the folder tree contains no files' {
        It 'Should return nothing for an empty folder' {
            $result = FileManagementSample\Get-LargestFile -Path $script:emptyPath -Top 5

            $result | Should -BeNullOrEmpty
        }

        It 'Should return nothing when the path does not exist' {
            $missingPath = Join-Path -Path $TestDrive -ChildPath 'Missing'

            $result = FileManagementSample\Get-LargestFile -Path $missingPath -Top 5

            $result | Should -BeNullOrEmpty
        }
    }

    Context 'When several paths are searched' {
        It 'Should search every path that is piped in' {
            $result = $script:rootPath, $script:otherPath | FileManagementSample\Get-LargestFile -Top 1

            $result.Name | Should -Be @('huge.dat', 'archive.zip')
        }

        It 'Should apply Top to each piped path separately' {
            $result = $script:rootPath, $script:otherPath | FileManagementSample\Get-LargestFile -Top 2

            $result.Name | Should -Be @('huge.dat', 'large.bin', 'archive.zip', 'notes.txt')
        }

        It 'Should search every path in a Path array' {
            $result = FileManagementSample\Get-LargestFile -Path $script:rootPath, $script:otherPath -Top 1

            $result.Name | Should -Be @('huge.dat', 'archive.zip')
        }
    }

    Context 'When objects are piped in' {
        It 'Should search the folders that Get-ChildItem returns' {
            $result = Get-ChildItem -Path $TestDrive -Directory |
                Where-Object -Property 'Name' -In -Value 'Files', 'Other' |
                FileManagementSample\Get-LargestFile -Top 1

            @($result.Name | Sort-Object) | Should -Be @('archive.zip', 'huge.dat')
        }

        It 'Should search the paths that Resolve-Path returns' {
            $result = Resolve-Path -LiteralPath $script:rootPath, $script:otherPath |
                FileManagementSample\Get-LargestFile -Top 1

            $result.Name | Should -Be @('huge.dat', 'archive.zip')
        }

        It 'Should search a folder with square brackets in its name when the folder is piped in' {
            $result = Get-Item -LiteralPath $script:bracketPath | FileManagementSample\Get-LargestFile -Top 1

            $result.Name | Should -Be 'inside.bin'
        }

        It 'Should search folders and paths that are piped in together' {
            $pipelineItems = @(
                (Get-Item -LiteralPath $script:rootPath)
                $script:otherPath
                (Get-Item -LiteralPath $script:bracketPath)
            )

            $result = $pipelineItems | FileManagementSample\Get-LargestFile -Top 1

            $result.Name | Should -Be @('huge.dat', 'archive.zip', 'inside.bin')
        }
    }

    Context 'When the path contains wildcard characters' {
        It 'Should expand the wildcard characters in Path' {
            $wildcardPath = Join-Path -Path $script:rootPath -ChildPath '*.bin'

            $result = FileManagementSample\Get-LargestFile -Path $wildcardPath -Top 5

            $result.Name | Should -Be 'large.bin'
        }

        It 'Should search a folder with square brackets in its name when LiteralPath is used' {
            $result = FileManagementSample\Get-LargestFile -LiteralPath $script:bracketPath -Top 1

            $result.Name | Should -Be 'inside.bin'
        }
    }

    Context 'When the parameters are not valid' {
        It 'Should throw when Path is an empty string' {
            { FileManagementSample\Get-LargestFile -Path '' -Top 1 } |
                Should -Throw -ErrorId 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Get-LargestFile'
        }

        It 'Should throw when Top is not a number' {
            { FileManagementSample\Get-LargestFile -Path $script:rootPath -Top 'many' } |
                Should -Throw -ErrorId 'ParameterArgumentTransformationError,Get-LargestFile'
        }

        It 'Should throw when LiteralPath is an empty string' {
            { FileManagementSample\Get-LargestFile -LiteralPath '' -Top 1 } |
                Should -Throw -ErrorId 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Get-LargestFile'
        }

        It 'Should throw when Path and LiteralPath are used together' {
            $parameters = @{
                Path        = $script:rootPath
                LiteralPath = $script:otherPath
                Top         = 1
            }

            { FileManagementSample\Get-LargestFile @parameters } |
                Should -Throw -ErrorId 'AmbiguousParameterSet,Get-LargestFile'
        }
    }
}
