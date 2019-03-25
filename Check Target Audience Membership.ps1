/* Check Target Audience Membership */

Add-pssnapin microsoft.sharepoint.powershell -ErrorAction SilentlyContinue
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Audience");

$url = "<Url of Central Admin>"
 
# Create objects
$spsite=new-Object Microsoft.SharePoint.SPSite($url);
$spcontext=[Microsoft.Office.Server.ServerContext]::GetContext($spsite);
$searchcontext=[Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($spsite)
$audmanager=New-Object Microsoft.Office.Server.Audience.AudienceManager($spcontext);
$Audience = $audmanager.Audiences | Where {$_.AudienceName -eq "<Name of Target Audinece>"}
$Member = $Audience.GetMembership() | Where {$_.NTName -eq "<User ID of user>"}

if($null -ne $Member){
    Write-Host $true
}
else{
    Write-Host $false
}    
