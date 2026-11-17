# FileManagementSample

FileManagementSample is a PowerShell module that shows which files and file
extensions use the most space in a folder and its subfolders.

## Features

- `Get-LargestFile` returns the largest files in a folder tree, largest
  first, as `System.IO.FileInfo` objects.
- `Get-FileExtensionSize` returns the file extensions with the most files in
  a folder tree, with the number of files and their total size in
  gigabytes (GB).

Both commands search all subfolders, skip items they cannot read, and return
no output when the path does not exist.

## Requirements

- Windows PowerShell 5.1, or PowerShell 7 on Windows, Linux, or macOS.

## Installation

To install the module from the PowerShell Gallery, run:

```powershell
Install-Module -Name 'FileManagementSample' -Scope 'CurrentUser'
```

To use a local build instead, see [Building and testing](#building-and-testing).

## Usage

Find the five largest files in a folder and its subfolders:

```powershell
Get-LargestFile -Path 'C:\Logs' -Top 5
```

`Get-LargestFile` also accepts folder paths and folder objects from the
pipeline, and searches each folder on its own. Find the largest file in each
folder directly below your home folder:

```powershell
Get-ChildItem -Path $HOME -Directory | Get-LargestFile -Top 1
```

Use `-LiteralPath` instead of `-Path` for a folder name that contains wildcard
characters such as square brackets.

Find the three extensions with the most files, with the number of files and
their total size in gigabytes:

```powershell
Get-FileExtensionSize -Path 'C:\Data' -Top 3
```

`Get-FileExtensionSize` ranks extensions by the number of files, not by
size. To list the result by size instead, sort it:

```powershell
Get-FileExtensionSize -Path $HOME -Top 10 |
    Sort-Object -Property TotalFileSize -Descending
```

Each command has full help with parameter descriptions and examples:

```powershell
Get-Help -Name Get-LargestFile -Full
Get-Help -Name Get-FileExtensionSize -Full
Get-Help -Name about_FileManagementSample
```

## Building and testing

The project uses the [Sampler](https://github.com/gaelcolas/Sampler) build
framework. Run every build and test command through `build.ps1`.

1. Download the build dependencies into `output/RequiredModules`:

   ```powershell
   ./build.ps1 -ResolveDependency -Tasks noop
   ```

1. Build the module into `output/module` and run all tests:

   ```powershell
   ./build.ps1
   ```

Other workflows:

- `./build.ps1 -Tasks build` builds the module without running tests.
- `./build.ps1 -Tasks test` runs the tests against the last build.
- `./build.ps1 -Tasks hqrmtest` runs the DscResource.Test quality tests.
- `./build.ps1 -Tasks pack` builds the module, generates the command
  reference and external help, and creates the NuGet package.

Test results are written to `output/testResults`. To try the local build in
the current session, run:

```powershell
Import-Module -Name './output/module/FileManagementSample' -Force
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the
[code of conduct](CODE_OF_CONDUCT.md). Changes are listed in
[CHANGELOG.md](CHANGELOG.md). To report a security issue, see
[SECURITY.md](SECURITY.md).
