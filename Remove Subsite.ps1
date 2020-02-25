Param([Parameter(Mandatory=$true)][string]$WebUrl, [Parameter(Mandatory=$true)][string]$LogPath)

#********Script to Remove/Delete Subsite from SharePoint 2010 **********#

if ($null -eq (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"  -ErrorAction SilentlyContinue
}

$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm-ss
$LogFile = "$LogPath\SP10_Remove-SPWeb_$LogTime.log"

start-transcript $LogFile

# Get Start Time
$startDTM = (Get-Date)

#Get the site
$web = Get-SPWeb $WebUrl

#Delete the subsite
$web.Delete()

Write-Host "SPWeb/Subsite '$($WebUrl)' has been deleted successfully."

# Get End Time
$endDTM = (Get-Date)
# Get Time elapsed
"`r`n$(Get-Date) Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

stop-transcript
