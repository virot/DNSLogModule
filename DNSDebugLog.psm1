$DebugMessage = {Param([string]$Message);"$(get-date -Format 's') [$((Get-Variable -Scope 1 MyInvocation -ValueOnly).MyCommand.Name)]: $Message"}

. "$PSScriptRoot\Includes\Get-DNSDebugLog.ps1"