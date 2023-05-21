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
    [OutputType([System.Collections.Generic.List[BrowserInfo]])]
    param ()

    process {
        # Todo: Create BrowserList API.
        $BrowserList = [BrowserManager]::GetBrowserList()
    }
    end {
        return $BrowserList
    }
}