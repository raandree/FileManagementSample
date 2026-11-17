---
status: current
last-verified: 2026-11-17
owner: shared
source: repository evidence
---

# Product context

## Problem

Users need to find what consumes space in a folder tree: the largest files
and the file extensions that occur most often, with their total size.

## Users

- PowerShell users and administrators (To confirm).

## Core workflows

1. `Get-LargestFile -Path <folder> -Top <n>` returns the `n` largest files
   (recursive) as `System.IO.FileInfo` objects. Folder paths and folder
   objects can be piped in; `Top` then applies to each folder.
2. `Get-FileExtensionSize -Path <folder> -Top <n>` returns the `n` extensions
   with the most files, each with `FileCount` and `TotalFileSize` in GB.

## Experience goals

- Non-interactive use: all input comes from parameters or, for
  `Get-LargestFile`, the pipeline.
- `Get-Help` gives synopsis, description, parameters, and examples for every
  command.
