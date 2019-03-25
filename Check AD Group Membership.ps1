/* Check AD Group Membership */

$user = "12345"
$group = "AD Group"

Write-Host "Loading AD Group Members @" $(Get-Date -Format yyyy-MM-dd_hh-mm-ss) -ForegroundColor Yellow
$members = Get-ADGroup $group -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser | Select -ExpandProperty SAMAccountName
Write-Host "Loaded AD Group Members @" $(Get-Date -Format yyyy-MM-dd_hh-mm-ss) -ForegroundColor Green

If ($members -contains $user) {
      Write-Host "$user exists in the group" -ForegroundColor Green
 } Else {
        Write-Host "$user does not exist in the group" -ForegroundColor Red
}
