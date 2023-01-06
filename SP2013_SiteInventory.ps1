###############################################################################
# This script gets list of administrators for each site collection within 
# sharepoint farm and saves output in tab separated format (.csv) file. 
###############################################################################

#Set file location for saving information. We'll create a tab separated file.
$FileLocation = "D:\Reports\SP2013_SiteReport.csv"

#Load SharePoint snap-in
Add-PSSnapin Microsoft.SharePoint.PowerShell

#Fetches webapplications in the farm
$WebApplications = Get-SPWebApplication -IncludeCentralAdministration
Write-Output "SiteName `t URL `t Site Collection Owner `t Site Collection Owner Email `t Owner Department `t Site Collection Secondary Owner `t Site Collection Secondary Owner Email `t Secondary Owner Department `t Created `t LastContentModifiedDate `t SizeInMB" | Out-file $FileLocation

# Function to calculate folder size
Function GetFolderSize($folder)
{
    $FolderSize = 0
    foreach ($File in $Folder.Files)
    {
	 	#Get File Size
        $FolderSize += $file.TotalLength;
		
		#Get the Versions Size
        foreach ($fileVersion in $file.Versions)
        {
            $FolderSize += $fileVersion.Size
        }
    }
    foreach ($subfolder in $folder.SubFolders)
    {
        $FolderSize += GetFolderSize $SubFolder
    }
    return $FolderSize
}

foreach($WebApplication in $WebApplications)
{
    #Fetches site collections list within sharepoint webapplication
    Write-Output ""
    Write-Output "Working on web application $($WebApplication.Url)"
    $Sites = Get-SPSite -WebApplication $WebApplication -Limit All    

    foreach($Site in $Sites)
    {   
        if($Site -ne $null)
        {
            if( -not($Site.Url.StartsWith("https//mysite","CurrentCultureIgnoreCase")) -and -not($Site.Url.StartsWith("https://feprsp13app","CurrentCultureIgnoreCase")) -and -not($Site.Url.StartsWith("https://loanops","CurrentCultureIgnoreCase")) )
            {
            
                #$SizeInKB = $Site.Usage.Storage
                #$SizeInMB = $SizeInKB/1024/1024
                #$SizeInMB = [math]::Round($SizeInMB,2)         
                  
                ##Fetches information for each  site
                #Write-Output "$($Site.RootWeb.Title) `t $($Site.Url) `t $($Site.Owner.Name) `t $($Site.Owner.Email) `t $ownerDept `t $($Site.SecondaryContact.Name) `t $($Site.SecondaryContact.Email) `t $secOwnerDept `t $($Site.LastContentModifiedDate) `t $($SizeInMB)" | Out-File $FileLocation -Append
                #$Site.Dispose();

                $ownerLoginName = $($Site.Owner.LoginName);
                $secOwnerLoginName = $($Site.SecondaryContact.LoginName);

                $ownerDept = "";
                $secOwnerDept = "";
            
                $context = Get-SPServiceContext $Site            
                $profMan = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)

                if($ownerLoginName -ne $null){
                    $ownerLoginName = $ownerLoginName.Replace("i:0#.w|","")        
                    try{
                        $prof = $profMan.GetUserProfile($ownerLoginName);
                        $ownerDept = $prof["SPS-Department"]
                    }
                    catch{}
                }
                if($secOwnerLoginName -ne $null){
                    $secOwnerLoginName = $secOwnerLoginName.Replace("i:0#.w|","")        
                    try{
                        $prof = $profMan.GetUserProfile($secOwnerLoginName);
                        $secOwnerDept = $prof["SPS-Department"]
                    }
                    catch{}
                }
                foreach($Web in $Site.AllWebs)
                {
                    if($Web -ne $null)
                    {
                        $webSize = GetFolderSize $Web.RootFolder #Call function to calculate Folder Size
                        $formatedSize = [Math]::Round($webSize/1MB, 2)
                        #Fetches information for each  site
                        Write-Output "$($Web.Title) `t $($Web.Url) `t $($Site.Owner.Name) `t $($Site.Owner.Email) `t $ownerDept `t $($Site.SecondaryContact.Name) `t $($Site.SecondaryContact.Email) `t $secOwnerDept `t $($Web.Created) `t $($Web.LastItemModifiedDate) `t $($formatedSize)" | Out-File $FileLocation -Append
                    }

                }
            }
        }
    }
}



#Unload SharePoint snap-in
Remove-PSSnapin Microsoft.SharePoint.PowerShell

Write-Output ""
Write-Output "Script Execution finished"
    
##############################################################################
## End of Script
##############################################################################
