Param([Parameter(Mandatory=$true)][string]$webAppUrl, [Parameter(Mandatory=$true)][string]$LogPath)

#********Script to set PeoplePickerSearchInMultipleForests for SharePoint Web Applications **********#

if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm-ss
$LogFile = "$LogPath\SP16_PeoplePicker-MultiForest_$LogTime.log"

start-transcript $LogFile

# Get Start Time
$startDTM = (Get-Date)

$webapp = Get-SPWebApplication $webAppURL

if($null -ne $webapp){
    Write-Host "`r`n$(Get-Date)|Found Web Application: "$webapp.Url -ForegroundColor Yellow
}else{
    Write-Host "`r`n$(Get-Date)|Error: Cannot find Web Application "$webAppUrl -ForegroundColor Red
}

$ws = $webapp.WebService

#Enable People Picker Search In Multiple Forests
Write-Host "`r`n$(Get-Date)|Enabling People Picker Search In Multiple Forests..." -ForegroundColor Yellow
$ws.PeoplePickerSearchInMultipleForests = $True
$ws.update()

Write-Host "`r`n$(Get-Date)|Script has been completed successfully." -ForegroundColor Green

# then IISReset

# Get End Time
$endDTM = (Get-Date)
# Get Time elapsed
"`r`n$(Get-Date) Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

stop-transcript
