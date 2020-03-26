#! /bin/powerhshell

<#

.SYNOPSIS
This is a powerhsell script for logging speed and latency over an indefinite period of time when ran in the foreground. It uses a remote server (1.1.1.1 by default) and an interval (2 seconds) by default

.DESCRIPTION
-remote <remote server IP or name>
-interval <interval in seconds>
-speedtest ($true|$false)

.EXAMPLE
./PingCheck.ps1 -remote dev0.sh -interval 5

.NOTES
If you run a speedtest your minimum effective interval is the duration of the speedtest +1s

.LINK
https://git.dev0.sh/piper/techsupport_scripts

#>

#get things
param ([string]$remote='1.1.1.1', [decimal]$interval='2', [bool]$speedtest=$false)
$gate = $($(Get-NetIPConfiguration).IPv4DefaultGateway).NextHop

# make our file
$csv = "$env:USERPROFILE\Desktop\PingCheck_$interval.csv"
Add-Content -Path $csv  -Value "Time,$gate,$remote,Youtube,Twitter,Speed"

Write-Host "All output is being made in $csv" -Foreground Green
Write-Warning "If you run a speedtest your minimum effective interval is the duration of the speedtest +1s"
Write-Warning "Do not open the file until you have terminated this script."

While ($true) {
	$time = Get-Date -Format "%M/%d %H:%m:%s"
	$gateJob = Start-Job { $(Test-Connection -ComputerName $using:gate -Count 1).ResponseTime }
	$remoteJob = Start-Job { $(Test-Connection -ComputerName $using:remote -Count 1).ResponseTime }
	$ytJob = Start-Job { $(Test-Connection -Computername 'youtube.com' -Count 1).ResponseTime }
	$twJob = Start-Job { $(Test-Connection -Computername 'twitter.com' -Count 1).ResponseTime }
	If ($speedtest){
			$speed = $($a=Get-Date; Invoke-WebRequest https://dev0.sh/1MiB |Out-Null; "$((10/((Get-Date)-$a).TotalSeconds)*8) Mbps")
		}Else{
			$speed = "skipped"
	}
	Start-Sleep '1'
	$timeGate = Receive-Job $gateJob
	$timeRemote = Receive-Job $remoteJob
	$timeYT = Receive-Job $ytJob
	$timeTW = Receive-Job $twJob
	Add-Content -Path $csv -Value "$time,$timeGate ms,$timeRemote ms,$timeYT ms,$timeTW ms,$speed"
	Start-Sleep -Seconds $interval
}
