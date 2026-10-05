$ErrorActionPreference = 'Stop'

# Requires Selenium.WebDriver for PowerShell:
Install-Module Selenium -Scope CurrentUser
Import-Module Selenium -ErrorAction Stop
$driver = Start-SeEdge
$driver.Navigate().GoToUrl('https://extranet.marriott.com/mosaic/psp/psesprt1/')

Read-Host 'Sign in and complete any MFA in Edge, then press Enter here'

function Find-InCurrentOrFrames([string] $xpath) {
    $found = @($script:driver.FindElements([OpenQA.Selenium.By]::XPath($xpath)) |
        Where-Object { $_.Displayed -and $_.Enabled } | Select-Object -First 1)
    if ($found.Count) { return $found[0] }

    foreach ($frame in $script:driver.FindElements([OpenQA.Selenium.By]::CssSelector('iframe, frame'))) {
        try {
            $script:driver.SwitchTo().Frame($frame)
            $found = Find-InCurrentOrFrames $xpath
            if ($found) { return $found }
            $script:driver.SwitchTo().ParentFrame()
        } catch {
            try { $script:driver.SwitchTo().ParentFrame() } catch {}
        }
    }
    return $null
}

function Click-Label([string] $label) {
    $safe = $label.Replace("'", "&apos;")
    $xpath = "//*[self::a or self::button or self::input or self::span or self::div][normalize-space(.)='$safe' or @value='$safe']"
    $element = Find-InCurrentOrFrames $xpath
    if (-not $element) { throw "Could not find enabled control '$label'." }
    try { $element.Click() } catch { $script:driver.ExecuteScript('arguments[0].click();', $element) }
    Start-Sleep -Seconds 2
}

Click-Label 'Employee Self Service'
Click-Label 'Time Report'
Click-Label 'Create/Update'
Click-Label 'Add a New Value'

# Select the requested copy-from period in the page's dropdown.
$period = '10/02/2026'
$select = Find-InCurrentOrFrames "//select[.//option[contains(normalize-space(.),'$period')]]"
if (-not $select) { throw "Could not find a dropdown containing period ending $period." }
$option = @($select.FindElements([OpenQA.Selenium.By]::TagName('option')) |
    Where-Object { $_.Text.Trim() -eq $period } | Select-Object -First 1)
if (-not $option) { throw "Period ending $period is not available in the dropdown." }
$option.Click()

Click-Label 'Add'
Write-Host 'Selected period ending 10/02/2026 and clicked Add. Edge remains open.'