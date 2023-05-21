function Get-BrowserList {
    <#
    .SYNOPSIS
        Lists of all web browsers in the market – the popular, as well as the little-known ones. 
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .NOTES
        Thanks to webdevelopersnotes
    .LINK
        https://www.webdevelopersnotes.com/browsers-list
    .LINK
        https://github.com/alainQtec/BrowserManager/blob/main/Private/Get-BrowserList.ps1
    .EXAMPLE
        Get-BrowserList -Verbose
        Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[psobject]])]
    param ()

    process {
        $BrowserList = [System.Collections.Generic.List[psobject]]::new()
        $links = $(Invoke-WebRequest 'https://www.webdevelopersnotes.com/browsers-list').Links | Where-Object { $_.rel -eq "noopener noreferrer" -and !$_.title.EndsWith("web site") }
        $links = $links.Where({ ![string]::IsNullOrWhiteSpace($_.href) }) | ForEach-Object {
            $title, $href = ($_.title -replace " download link$", ''), $_.href -replace "^https?://", '//' -replace "^//?", 'https://'
            [PSCustomObject]@{
                title = $title
                href  = $href
            }
        } | Sort-Object -Property href -Unique
        $links.ForEach({ [void]$BrowserList.Add($_) })
    }

    end {
        return $BrowserList
    }
}