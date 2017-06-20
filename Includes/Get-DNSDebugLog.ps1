Function Get-DNSDebugLog{
<#
.SYNOPSIS
Reads the specified DNS debug log.

.DESCRIPTION
Retrives all entries in the DNS debug log for further processing using powershell or exporting to Excel.

.PARAMETER Path
Specifies the path to the DNS debug logfile.

.PARAMETER Ignore
Specifies which IPs to ignore.

.PARAMETER Culture
If other culture was used on server specify this here

.INPUTS
Takes the filepath of the DNS servers debug log.
And an Ignore parameter to ignore certain ips.

.OUTPUTS
Array of PSCustomObject

\windows\system32\dns\dns.log

.EXAMPLE
Get-DNSDebugLog -Path "$($env:SystemRoot)\system32\dns\dns.log" -Verbose |? {$_.QR -eq "Query"-and $_.Way -eq 'RCV'} |group-Object "Client IP"| Sort-Object -Descending Count| Select -First 10 Name, Count

Name            Count
----            -----
192.168.66.103     21
192.168.66.37      11
192.168.66.22       4
192.168.66.117      1


.EXAMPLE
C:\PS> Import-Module ActiveDirectory
C:\PS> $ignore =  Get-ADDomainController -Filter * | Select-Object -ExpandProperty Hostname |ForEach-Object {[System.Net.Dns]::GetHostAddresses($_)|select -ExpandProperty IPAddressToString}
C:\PS> Get-DNSDebugLog -Ignore:$Ignore -Path '\\dc01.domain.tld\c$\dns.log'

.LINK
Script center: http://gallery.technet.microsoft.com/scriptcenter/Get-DNSDebugLog-Easy-ef048bdf
My Blog: http://virot.eu
Blog Entry: http://virot.eu/wordpress/easy-handling-before-removing-dns/

.NOTES
Author:	Oscar Virot - virot@virot.com
Filename: Get-DNSDebugLog.ps1
#>
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [string]
    [ValidateScript({Test-Path($_)})]
    $Path,
    [Parameter(Mandatory=$False)]
    [string[]]
    $Ignore,
    [System.Globalization.CultureInfo]
    $Culture = [System.Globalization.CultureInfo]::CurrentCulture
  )
  Begin
  {
    Write-Verbose "Storing DNS logfile format"
    $dnspattern = "^(?<date>([0-9]{1,2}.[0-9]{1,2}.[0-9]{2,4}|[0-9]{2,4}-[0-9]{2}-[0-9]{2})\s*[0-9: ]{7,8}\s*(PM|AM)?) ([0-9A-Z]{3,4} PACKET\s*[0-9A-Za-z]{8,16}) (UDP|TCP) (?<way>Snd|Rcv) (?<ip>[0-9.]{7,15}|[0-9a-f:]{3,50})\s*([0-9a-z]{4}) (?<QR>.) (?<OpCode>.) \[.*\] (?<QueryType>.*) (?<query>\(.*)"
    Write-Verbose "Storing storing returning customobject format"
    $returnselect = @{label="Client IP";expression={[ipaddress] ($match.Groups['ip'].value.trim()).trim()}},
      @{label="DateTime";expression={$dt = [datetime]::new(1);[datetime]::TryParse($match.Groups['date'].value.trim(),$Culture.DateTimeFormat,[System.Globalization.DateTimeStyles]::None,[ref]$dt)|Out-Null;$dt}},
      @{label="QR";expression={switch($match.Groups['QR'].value.trim()){" " {'Query'};"R" {'Response'}}}},
      @{label="OpCode";expression={switch($match.Groups['OpCode'].value.trim()){'Q' {'Standard Query'};'N' {'Notify'};'U' {'Update'};'?' {'Unknown'}}}},
      @{label="Way";expression={$match.Groups['way'].value.trim()}},
      @{label="QueryType";expression={$match.Groups['QueryType'].value.trim()}},
      @{label="Query";expression={$match.Groups['query'].value.trim() -replace "(`\(.*)","`$1" -replace "`\(.*?`\)","." -replace "^.",""}}
    if ($Culture -ne [System.Globalization.CultureInfo]::CurrentCulture)
    {
      Write-Verbose "Using custom Culture: $Culture"
    }
  }
  Process
  {
    Write-Verbose "Getting the contents of $Path, and matching for correct rows."
    $rows = ([array](Get-Content $Path)) -notmatch 'ERROR offset' -notmatch 'NOTIMP'
    Write-Verbose "Found $($rows.count) in debuglog, processing 1 at a time."
    ForEach ($row in $rows)
    {
      write-verbose "Row: $($row)"
      $match = [regex]::match($row,$dnspattern)
      if ($match.success )
      {
        Try
	{
          if ($Ignore -notcontains ([ipaddress] $match.Groups['ip'].value.trim()))
          {
            $true | Select-Object $returnselect
          }
        }
        Catch
        {
          Write-Debug 'Failed to interpet row.'
          Write-Debug $row
        }
      }
      else
      {
        Write-Verbose 'Row does not match DNS Pattern'
      }
    }
  }
  End
  {
  }
}
