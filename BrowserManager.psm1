#!/usr/bin/env pwsh

#region    Classes

class Vendor {
    [string] $Name
    [string] $Website
    Vendor() {}
    Vendor([string]$name, [string]$website) {
        $this.Name = $name
        $this.Website = $website
    }
}

class BrowserInfo {
    [string] $Name
    [uri] $Uri
    hidden [IO.DirectoryInfo] $InstallationPath
    hidden [version] $Version
    hidden [bool] $IsDefault
    hidden [Vendor] $Vendor

    BrowserInfo() {}
    BrowserInfo([string]$Name, [uri]$Uri) {
        $this.Name = $name
        $this.Uri = $Uri
    }
    BrowserInfo([string]$name, [version]$version, [Vendor]$vendor, [IO.DirectoryInfo]$installationPath) {
        $this.Name = $name
        $this.Version = $version
        $this.Vendor = $vendor
        $this.InstallationPath = $installationPath
    }
    [void] SetAsDefault() {}
}

class BrowserManager {
    [BrowserInfo] $SelectedBrowser
    [string[]] $FileExtensions
    static [BrowserInfo] $DefaultBrowser
    static [bool] $IsInstallerRunning
    static [BrowserInfo[]] $InstalledBrowsers
    hidden [BrowserInfo] $_currentBrowser
    static hidden [System.Collections.Generic.List[BrowserInfo]] $_BrowserList

    BrowserManager() {}

    [BrowserInfo] GetDefaultBrowser() {
        # Implementation for getting the default browser
        $defaultBrowserName = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" -Name "ProgId" -ErrorAction SilentlyContinue
        if ($defaultBrowserName) {
            $browserInfo = [BrowserInfo]::new()
            $browserInfo.Name = $defaultBrowserName.ProgId
            $browserInfo.Version = "Unknown"
            $browserInfo.Vendor = "Unknown"
            $browserInfo.InstallationPath = "Unknown"
            return $browserInfo
        }
        return $null
    }
    [void] UninstallBrowser([string]$browserName) {}
    [void] SetFileExtensions([string[]]$fileExtensions) {}
    [void] InstallBrowser([string]$browserInstallerPath) {}

    static [BrowserInfo[]] GetInstalledBrowsers() {
        $browserObjectS = $null
        # Get installed browsers implementation ..
        return $browserObjectS
    }
    static [System.Collections.Generic.List[BrowserInfo]] GetBrowserList() {
        $BrowserList = [BrowserManager]::_BrowserList
        if ($null -eq $BrowserList) {
            Write-Debug "Fetching ..." -Debug
            $BrowserList = [System.Collections.Generic.List[BrowserInfo]]::new()
            $(((Invoke-WebRequest -Verbose:$false -Uri 'https://www.webdevelopersnotes.com/browsers-list').Links | Where-Object { $_.rel -eq "noopener noreferrer" -and !$_.title.EndsWith("web site") }).Where({ ![string]::IsNullOrWhiteSpace($_.href) }).ForEach({
                        [BrowserInfo]::new($($_.title -replace " download link$", ''), $($_.href -replace "^https?://", '//' -replace "^//?", 'https://'))
                    }
                ) | Sort-Object -Unique uri
            ).ForEach({ [void]$BrowserList.Add($_) })
            [BrowserManager]::_BrowserList = $BrowserList
        } else {
            Write-Debug "Using already existing list" -Debug
        }
        return $BrowserList
    }
    static [void] SetDefaultBrowser([string]$browserName) {}
    static [void] SetDefaultFileExtensions([string]$browserName, [string[]]$fileExtensions) {}
}
class EdgeUninstaller {
    static [void] Run() {
        # Check if launched with administrative permissions
        $isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isElevated) {
            Write-Host "Error: No administrative permissions. Please relaunch with Administrative Permissions to remove Microsoft Edge."
            Pause
            Exit
        }

        # Call the other static methods
        [EdgeUninstaller]::CreateSystemRestorePoint()
        [EdgeUninstaller]::KillMicrosoftEdge()
        [EdgeUninstaller]::RemoveEdgePackages()
        [EdgeUninstaller]::SetDoNotUpdateRegistryKey()

        Write-Host "Script has finished. If you have Microsoft Edge Legacy/UWP, you must reboot to take effect. Press any key to exit."
        Pause
    }

    static [void] CreateSystemRestorePoint() {
        Write-Host "Creating system restore point..."
        $date = Get-Date -Format "yyyy-MM-dd"
        $command = "wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint ""This_was_made_by_Edge_Remover_on_$date"", 100, 1"
        Invoke-Expression -Command $command
        Write-Host "System restore point created."
    }

    static [void] KillMicrosoftEdge() {
        Write-Host "Killing Microsoft Edge..."
        taskkill /F /IM msedge.exe
        Write-Host "Microsoft Edge killed."
    }

    static [void] RemoveEdgePackages() {
        $programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86)
        $edgeChromiumPackageVersion = Get-ChildItem -Path "$programFiles\Microsoft\Edge\Application" -Directory | Select-Object -ExpandProperty Name -First 1

        if ($edgeChromiumPackageVersion) {
            Write-Host "Removing $edgeChromiumPackageVersion..."
            & "$programFiles\Microsoft\Edge\Application\$edgeChromiumPackageVersion\Installer\setup.exe" --uninstall --force-uninstall --msedge --system-level --verbose-logging
            & "$programFiles\Microsoft\Edge\EdgeCore\$edgeChromiumPackageVersion\Installer\setup.exe" --uninstall --force-uninstall --msedge --system-level --verbose-logging
            powershell.exe -Command "Get-AppxPackage *MicrosoftEdge* | Remove-AppxPackage"
        }
        else {
            Write-Host "Microsoft Edge [Chromium] not found, skipping."
        }

        $edgeLegacyPackageVersion = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" -Name "Microsoft-Windows-Internet-Browser-Package" -ErrorAction SilentlyContinue
        if ($edgeLegacyPackageVersion) {
            Write-Host "Removing $edgeLegacyPackageVersion..."
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$edgeLegacyPackageVersion" -Name Visibility -Value 1
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$edgeLegacyPackageVersion\Owners" -Name "*" -ErrorAction SilentlyContinue
            dism /online /Remove-Package /PackageName:$edgeLegacyPackageVersion
            powershell.exe -Command "Get-AppxPackage *edge* | Remove-AppxPackage"
        }
        else {
            Write-Host "Microsoft Edge [Legacy/UWP] not found, skipping."
        }

        $melodyPackageName = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" -Name "Microsoft-Windows-MicrosoftEdgeDevToolsClient-Package" -ErrorAction SilentlyContinue
        if ($melodyPackageName) {
            Write-Host "Removing $melodyPackageName..."
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$melodyPackageName" -Name Visibility -Value 1
            Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$melodyPackageName\Owners" -Name "*" -ErrorAction SilentlyContinue
            dism /online /Remove-Package /PackageName:$melodyPackageName /NoRestart
        }
        else {
            Write-Host "Package not found."
        }
    }

    static [void] SetDoNotUpdateRegistryKey() {
        Write-Host "Setting DoNotUpdateToEdgeWithChromium registry key..."
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1 -Type DWORD
        Write-Host "DoNotUpdateToEdgeWithChromium registry key set."
    }
}

#endregion Classes

$Private = Get-ChildItem ([IO.Path]::Combine($PSScriptRoot, 'Private')) -Filter "*.ps1" -ErrorAction SilentlyContinue
$Public = Get-ChildItem ([IO.Path]::Combine($PSScriptRoot, 'Public')) -Filter "*.ps1" -ErrorAction SilentlyContinue
# Load dependencies
$PrivateModules = [string[]](Get-ChildItem ([IO.Path]::Combine($PSScriptRoot, 'Private')) -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName)
if ($PrivateModules.Count -gt 0) {
    foreach ($Module in $PrivateModules) {
        Try {
            Import-Module $Module -ErrorAction Stop
        } Catch {
            Write-Error "Failed to import module $Module : $_"
        }
    }
}
# Dot source the files
foreach ($Import in ($Public + $Private)) {
    Try {
        . $Import.fullname
    } Catch {
        Write-Warning "Failed to import function $($Import.BaseName): $_"
        $host.UI.WriteErrorLine($_)
    }
}
# Export Public Functions
$Public | ForEach-Object { Export-ModuleMember -Function $_.BaseName }
#Export-ModuleMember -Alias @('<Aliases>')