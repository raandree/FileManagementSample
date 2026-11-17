# Changelog for FileManagementSample

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add comment-based help to `Get-LargestFile` and `Get-FileExtensionSize`, so
  `Get-Help` shows a synopsis, a description, parameter descriptions,
  examples, and the output of each command.
- Describe both commands, with examples, in the conceptual help topic
  `about_FileManagementSample`.
- Add the `LiteralPath` parameter to `Get-LargestFile`, so a folder whose name
  contains wildcard characters such as square brackets can be searched.
- Accept several paths in the `Path` parameter of `Get-LargestFile`, and accept
  folder objects from the pipeline, for example
  `Get-ChildItem -Directory | Get-LargestFile -Top 1`.

### Changed

- Declare the output type of `Get-LargestFile` (`System.IO.FileInfo`) and
  `Get-FileExtensionSize` (`PSCustomObject`), so PowerShell can complete their
  properties further down the pipeline.

### Fixed

- Fix `Get-LargestFile` searching only the last path when several paths are
  piped to it. It now searches every path, and `Top` applies to each path.

