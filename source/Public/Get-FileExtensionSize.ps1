function Get-FileExtensionSize {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [int]$Top
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
