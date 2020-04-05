$Pesterpath = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\..\DNSDebugLog.psd1"

Describe "Basic tests" {
    It "Read a simple log" {
      ([array](Get-DNSDebugLog -Path "$Pesterpath\Example-Data\dns-Locale_en-US-Windows2012.log")).count |Should be 436
    }
    It "Read an empty log" {
      ([array](Get-DNSDebugLog -Path "$Pesterpath\Example-Data\dns-format-Windows2012.log")).count |Should be 0
    }
}
Describe "Localization" {
    It "Verify date on en-US log" {
      Get-DNSDebugLog -Culture 'en-US' -Path "$Pesterpath\Example-Data\dns-Locale_en-US-Windows2012.log" |Select -First 1 |%{Get-Date $_.Datetime -Format 'yyyy-MM-dd HH:mm:ss'} |Should be "2017-06-20 05:36:59"
    }
    It "Verify date on de-AT log" {
      Get-DNSDebugLog -Culture 'de-AT' -Path "$Pesterpath\Example-Data\dns-Locale-de-AT-Windows2008r2.txt"|Select -First 1 |%{Get-Date $_.Datetime -Format 'yyyy-MM-dd HH:mm:ss'} |Should be "2015-09-30 12:04:28"
    }
    It "Verify date on sv-SE log" {
      Get-DNSDebugLog -Culture 'sv-SE' -Path "$Pesterpath\Example-Data\dns-Locale-sv-SE-Windows2012r2.txt"|Select -First 1 |%{Get-Date $_.Datetime -Format 'yyyy-MM-dd HH:mm:ss'} |Should be "2017-05-21 19:46:11"
    }
    It "Verify date on de-DE log" {
      Get-DNSDebugLog -Culture 'de-DE' -Path "$Pesterpath\Example-Data\dns-Locale-de-DE-WindowsUnknown.txt" |Select -First 1 |%{Get-Date $_.Datetime -Format 'yyyy-MM-dd HH:mm:ss'} |Should be "2020-03-06 17:15:40"
    }
}