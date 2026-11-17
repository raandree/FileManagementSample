# Welcome to the FileManagementSample wiki

Module version: #.#.#

FileManagementSample is a PowerShell module that shows which files and file
extensions use the most space in a folder and its subfolders.

## Getting started

To install the module from the PowerShell Gallery, run:

```powershell
Install-Module -Name 'FileManagementSample' -Scope 'CurrentUser'
```

Then search a folder, for example your home folder:

```powershell
Get-LargestFile -Path $HOME -Top 10
Get-FileExtensionSize -Path $HOME -Top 10
```

## Commands

- `Get-LargestFile` returns the largest files in a folder tree, largest
  first.
- `Get-FileExtensionSize` returns the file extensions with the most files in
  a folder tree, with the number of files and their total size in
  gigabytes (GB).

Each command has its own reference page in this wiki, listed in the sidebar.
In PowerShell, run `Get-Help <command name> -Full` for the same information.
