<#
    .SYNOPSIS
        Gets the largest files in a folder and its subfolders.

    .DESCRIPTION
        The Get-LargestFile function searches the folder specified by the Path
        or LiteralPath parameter, including all of its subfolders, and returns
        the files ordered by size, largest first. The Top parameter limits how
        many files are returned. Only files are returned, never folders.

        The function accepts input from the pipeline. You can pipe folder
        paths, or folder objects such as the output of Get-ChildItem, to it.
        Each folder is searched on its own, so the function returns up to Top
        files for every folder that it receives.

        Items that cannot be read, for example because access is denied, are
        skipped without an error. If the path does not exist, the function
        returns no output.

    .PARAMETER Path
        Specifies the path to the folder to search. The folder and all of its
        subfolders are searched. The path can contain wildcard characters. To
        search a folder whose name contains characters such as square
        brackets, use LiteralPath instead. You can specify more than one path.
        You can also pipe paths, or objects that have a Path property such as
        the output of Resolve-Path, to the function.

    .PARAMETER LiteralPath
        Specifies the path to the folder to search. The folder and all of its
        subfolders are searched. Unlike Path, the value is used exactly as it
        is typed, so no characters are interpreted as wildcard characters. The
        folders that Get-ChildItem returns are bound to this parameter through
        their PSPath property.

    .PARAMETER Top
        Specifies the maximum number of files to return for each folder,
        starting with the largest file.

    .EXAMPLE
        Get-LargestFile -Path 'C:\Logs' -Top 5

        Returns the five largest files in the folder C:\Logs and its
        subfolders.

    .EXAMPLE
        Get-LargestFile -Path $HOME -Top 10 | Select-Object -Property FullName, Length

        Returns the full path and the size in bytes of the ten largest files
        in the home folder of the current user.

    .EXAMPLE
        'C:\Logs', 'D:\Backups' | Get-LargestFile -Top 3

        Returns the three largest files in the folder C:\Logs and its
        subfolders, followed by the three largest files in the folder
        D:\Backups and its subfolders.

    .EXAMPLE
        Get-ChildItem -Path $HOME -Directory | Get-LargestFile -Top 1

        Returns the largest file in each folder directly below the home folder
        of the current user, including the subfolders of those folders.

    .EXAMPLE
        Get-LargestFile -LiteralPath 'C:\Data\Logs [2025]' -Top 5

        Returns the five largest files in the folder named Logs [2025]. The
        square brackets are part of the folder name, not wildcard characters.

    .INPUTS
        System.String

        The path of a folder to search.

    .INPUTS
        System.IO.DirectoryInfo

        A folder to search, for example from Get-ChildItem or Get-Item.

    .OUTPUTS
        System.IO.FileInfo

        The files of each folder, ordered from the largest to the smallest.

    .NOTES
        The size of a file is its Length property, in bytes.
#>
function Get-LargestFile
{
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 0,
                   ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [SupportsWildcards()]
        [System.String[]]
        $Path,

        [Parameter(ParameterSetName = 'LiteralPath', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('PSPath')]
        [System.String[]]
        $LiteralPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [System.Int32]
        $Top
    )

    process
    {
        # The parameter set is resolved for each piped object; use it to find the parameter that holds the path.
        if ($PSCmdlet.ParameterSetName -eq 'LiteralPath')
        {
            $pathParameterName = 'LiteralPath'
            $searchPaths = $LiteralPath
        }
        else
        {
            $pathParameterName = 'Path'
            $searchPaths = $Path
        }

        foreach ($searchPath in $searchPaths)
        {
            $getChildItemParameters = @{
                $pathParameterName = $searchPath
                Recurse            = $true
                File               = $true
                ErrorAction        = 'SilentlyContinue'
            }

            Get-ChildItem @getChildItemParameters |
                Sort-Object -Property Length -Descending |
                Select-Object -First $Top
        }
    }
}
