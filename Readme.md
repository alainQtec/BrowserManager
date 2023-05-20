# BrowserManager

Manage Installed browsers and easily set the default browser.

**Take control of your browsing experience**.

Easily manage and customize your default browser, uninstall unwanted browsers, and set file extensions with simple PowerShell commands. Choose the browser that suits your needs and preferences :)

<!-- Todo: Make the code cross-patform. ie: Windows, Linux & mac -->
<!-- *But this would mean users should have Powershell core Installed! humm ... -->

## Installation

```powershell
Install-Module -Name BrowserManager
```

## Usage

- **Get the Default Browser**

```Powershell
$BrowserInfo = Get-DefaultBrowser
```

- **Set a Browser as Default**

```PowerShell
Set-DefaultBrowser -Name "Chrome"
```

or

```PowerShell
(Get-InstalledBrowsers).Where({ $_ -Name -eq "Google Chrome" }).SetAsDefault()
```

- **Uninstall a Browser**

```PowerShell
Uninstall-Browser -BrowserName "Firefox"
```

- **Set File Extensions for a Browser**

```PowerShell
Set-BrowserFileExtensions -BrowserName "Edge" -FileExtensions ".html", ".htm"
```

## Contributing

Contributions are welcome! If you find any issues or want to enhance the functionality of the module, feel free to open an issue or submit a pull request :)

## License

This project is licensed under the [MIT License](License).