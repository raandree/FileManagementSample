<#
    .SYNOPSIS
        Gets the file extensions that occur most often in a folder, with the
        number of files and their total size.

    .DESCRIPTION
        The Get-FileExtensionSize function searches the folder specified by
        the Path parameter, including all of its subfolders, and groups the
        files by extension. The extensions are ranked by the number of files,
        not by size, and the Top parameter limits how many extensions are
        returned. For each extension, the function returns the number of files
        and their combined size in gigabytes (GB).

        Files without an extension are grouped under an empty extension.
        Extensions are compared without regard to case. Items that cannot be
        read, for example because access is denied, are skipped without an
        error. If the path does not exist, the function returns no output.

    .PARAMETER Path
        Specifies the path to the folder to search. The folder and all of its
        subfolders are searched.

    .PARAMETER Top
        Specifies the maximum number of extensions to return, starting with
        the extension that has the most files.

    .EXAMPLE
        Get-FileExtensionSize -Path 'C:\Data' -Top 3

        Returns the three extensions with the most files in the folder C:\Data
        and its subfolders, with the number of files and their total size in
        gigabytes.

    .EXAMPLE
        Get-FileExtensionSize -Path $HOME -Top 10 | Sort-Object -Property TotalFileSize -Descending

        Gets the ten extensions with the most files in the home folder of the
        current user, and then sorts them by total size, largest first.

    .OUTPUTS
        System.Management.Automation.PSCustomObject

        One object for each extension, with the following properties:

        - Extension: The extension including the leading dot, for example
          '.txt'. The value is empty for files without an extension.
        - FileCount: The number of files with the extension.
        - TotalFileSize: The combined size of the files in gigabytes (GB), as
          a System.Double. Multiply by 1GB to get the size in bytes.
#>
function Get-FileExtensionSize
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $Top
    )

    $fileGroups = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Group-Object -Property Extension |
        Sort-Object -Property Count -Descending |
        Select-Object -First $Top

    $fileGroups | ForEach-Object {
        $_ | Add-Member -Name Size -MemberType NoteProperty -Value ($_.Group | Measure-Object -Property Length -Sum).Sum
    }

    $fileGroups | ForEach-Object {
        [PSCustomObject]@{
            Extension = $_.Name
            FileCount = $_.Count
            TotalFileSize = $_.Size / 1GB
        }
    }
}
