Param([Parameter(Mandatory=$true)][string]$Site, [Parameter(Mandatory=$true)][string]$DataSource, [Parameter(Mandatory=$true)][string]$DatabaseName, [Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$false)][bool]$DeleteProfiles=$false)

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server")  
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.UserProfiles")  
Add-PSSnapin Microsoft.SharePoint.PowerShell

#Uncomment for Local run Only
#$site = "<Central Admin URL>"
#$DataSource = "Employee Database server name"
#$DatabaseName = "Emp Database name"
#$LogPath = "C:\SharePoint\UPS Profile Address Updates"
#$DeleteProfiles = $false

$eventSource = "SPUserProfileUpdate"
$logName = "Application"

$separator = "\\";
$failedItems = 0
$successItems = 0
$index = 0

$Audience = $null
$adGroupSocial = "G-SP-Social"
$global:countUsersinADNotInAudience = 0
$global:arrUsersNotInAudience = @()
$logUsersNotInAudience = "$LogPath\Users_G-SP-Social_vs_spsocial_$LogTime.log"

Write-Host "$eventSource - The SharePoint PS Started to find AD-Group (G-SP-Social) users not available in Global Audience-spsocial"
Write-EventLog -LogName $logName -Source $eventSource -EventID 2 -EntryType Information -Message "$eventSource - The SharePoint PS Started to find AD-Group (G-SP-Social) users not available in Global Audience-spsocial"

try{
    #Create Log Directory if not exists
    New-Item $LogPath –type directory
   }catch{}

$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm
$LogFile = "$LogPath\G-SP-Social_vs_spsocial_$LogTime.log"

start-transcript $LogFile

Function GetADGrpMembersSocial()
{
    try 
    { 
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Loading AD Group members of G-SP-Social..." -fore Yellow
        $members = Get-ADGroup $adGroupSocial -Properties Member | Select-Object -ExpandProperty Member | Get-ADUser | Select -ExpandProperty SAMAccountName
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Loaded AD Group members of G-SP-Social." -fore Green
        return $members
    } 
    catch 
    { 
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Failed to load AD Group members of G-SP-Social" -fore Red
        Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error - Failed to load AD Group members of G-SP-Social."
    }
}

Function Difference-SPGlobalAudience-VS-ADGroup
{
    Param([System.Object[]]$upsProfile)

    $isDeleted = $false
    
    try{
        $EmpID = ($upsProfile.AccountName -split $separator,2)[1]
        
        #if profile not deleted yet, check if in AD group, check if not in TA - Delete User Profile
          
        if( (-Not $isDeleted) -and ($adGroupSocialMembers -contains $EmpID))
        {
            $audienceMember = $Audience.GetMembership() | Where {$_.NTName -eq $upsProfile.AccountName}
            
            if($null -eq $audienceMember){
                $global:countUsersinADNotInAudience += 1
                $global:arrUsersNotInAudience += $upsProfile

                Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Account Not-In spsocial: " $EmpID
                if($DeleteProfiles)
                {
                    $upManager.RemoveUserProfile($upsProfile.ID) #Delete User Profile
                    $isDeleted = $true
                    Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Deleted UPS Profile ID: " $EmpID
                }
            }
        }
    }
    catch{
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Remove-SPUserProfile, Error: $_" -fore red
        Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error -Remove-SPUserProfile $_"
    }
    #return $isDeleted
}

#Main Script Ruuning Start Here...
$sitesub = Get-SPSite $Site
$context = Get-SPServiceContext $sitesub

# Load AD Group Members of Social Group
$adGroupSocialMembers = GetADGrpMembersSocial

if($context -eq $null)
{
    Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t $eventSource Error - SharePoint Context is Null."
    Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error - SharePoint Context is Null."
}
else
{
    Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t $eventSource - The SharePoint Context created successfully"
    Write-EventLog -LogName $logName -Source $eventSource -EventID 2 -EntryType Information -Message "$eventSource - The SharePoint Context created successfully"
    #$upsConfigManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileConfigManager($context)
    $upManager = New-Object Microsoft.Office.Server.UserProfiles.UserProfileManager($context)

    $audmanager=New-Object Microsoft.Office.Server.Audience.AudienceManager($context);
    $Audience = $audmanager.Audiences | Where {$_.AudienceName -eq "spsocial"}

    if($upManager -eq $null)
    {
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t $eventSource Error - SharePoint UserProfile Manager is Null."
        Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error - SharePoint UserProfile Manager is Null."
    }
    else
    {
        $usersCount = $upManager.Count.ToString()
        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t $eventSource - The SharePoint User Profile Service Application connected successfully. Total UPS Users: $usersCount"
        Write-EventLog -LogName $logName -Source $eventSource -EventID 2 -EntryType Information -Message "$eventSource - The SharePoint User Profile Service Application connected successfully. Total UPS Users: $usersCount"
        
        $profiles = $upManager.GetEnumerator()

        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Iterating all UPS profiles..." -ForegroundColor Yellow
        foreach($userProfile in $profiles)
        {
            $index += 1
            Try{
                #write-host $userProfile["AccountName"]
                $EmpID = ($userProfile["AccountName"] -split $separator,2)[1]
                Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t $index | Processing AccountID: $EmpID"
                    
                #Ignore Service Accounts
                if( -Not($EmpID.StartsWith("sa_")) -and -Not($EmpID.StartsWith("TEST_")) )
                {
                    Difference-SPGlobalAudience-VS-ADGroup $userProfile
                }
            }
            catch{
                Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Item Failed: $_" -ForegroundColor Red 
                #Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error - EMPID: $EmpID failed to update address, Error Message: $_"
                $failedItems += 1
            }
                
        }

        if($failedItems -gt 0){
            Write-EventLog -LogName $logName -Source $eventSource -EventID 0 -EntryType Error -Message "$eventSource Error - $failedItems items failed"
        }
        Write-EventLog -LogName $logName -Source $eventSource -EventID 1 -EntryType SuccessAudit -Message "$eventSource Success for $successItems items"
    }
}

Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Users In-AD NotIn-Audience: " $global:countUsersinADNotInAudience -ForegroundColor Yellow

$global:arrUsersNotInAudience | Format-List "DisplayName", "AccountName", "SipAddress" > $logUsersNotInAudience

if($DeleteProfiles)
{
    # START FUll UPS Sync
    if($upsConfigManager.IsSynchronizationRunning() -eq $false)
    {
        $upsConfigManager.StartSynchronization($true) 
        Write-Host "Started Full UPS Sync"
    
        Start-Sleep -s 600   #Give 10 minutes (600 seconds for it to complete)
    }
    else
    {
        Write-Host "UPS Sync is runniung already"
    }
    
    ## Start Target Audience Compilation
    $appUPA = Get-SPServiceApplication | Where {$_.TypeName -eq 'User Profile Service Application'}
    if ($appUPA) {
        #Stop Audiences Compilation Job
        Audiencejob.exe $appUPA.Id 0
        #Start Audiences Compilation Job
        Audiencejob.exe $appUPA.Id 1 spsocial  #this compiles all available audiences though
    }
}

stop-transcript
