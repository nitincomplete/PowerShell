Param([Parameter(Mandatory=$true)][string]$webAppUrl, [Parameter(Mandatory=$true)][string]$LogPath)

#********Script to Remove Orphan Users from SharePoint Sites **********#

if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm
$LogFile = "$LogPath\SP10_Remove-OrphanUsers_$LogTime.log"
$OrphanUsersReport = "$LogPath\SP10_Report-OrphanUsers_$LogTime.csv"

start-transcript $LogFile

# Get Start Time
$startDTM = (Get-Date)

#$webAppUrl = "http://ft8kspwebd1/"
$webApp = Get-SPWebApplication $webAppURL
 
# Grant the user running this script full permissions
#$userRunningScript = "FTBCO\27352"
#$webApp.GrantAccessToProcessIdentity($userRunningScript)
 
# CSV File to hold the list of orphaned users
# Make sure the "D:\Nitin\OrphanedUsers" folder exists first
"SharePoint Domain|Display Name|Login Name|Website|SP-Group(s)|Orphan Type" | out-file $OrphanUsersReport -append
 
# This hashtable will hold the usernames and website urls of all orphaned users we find
# Not exactly intuitive, I know... but the key is the login name and the value is the website
$orphanedUsers = @{}
 
# Array to hold already processed users
# For an organization with lots of sites and lots of users, this helps speed up script execution somewhat
# The logic below includes a condition to only process users who have NOT been added to this array
$processedUsers = @()
 
Foreach ($site in $webApp.Sites)  
{
    Write-host "Checking site collection:" $site.Url
    Foreach ($web in $site.AllWebs)
    {
        # Only search SharePoint websites that have unique role assignments
        #if ($web.HasUniqueRoleAssignments -eq $true)
        #{
            Write-host "Checking website:" $web.Url
            Foreach ($user in $web.SiteUsers)
            {
                if ($processedUsers -notcontains $user.LoginName.ToLower())
                {
                    $processedUsers += $user.LoginName.ToLower()
                     
                    # Don't search security groups
                    # Don't search built-in user accounts
                    if (($user.IsDomainGroup -eq $false) -and
                        (!($user.LoginName.ToLower() -like "*nt authority\authenticated users*")) -and
                        (!($user.LoginName.ToLower() -like "*sharepoint\system*")) -and
                        (!($user.LoginName.ToLower() -like "*nt authority\system*")) -and
                        (!($user.LoginName.ToLower() -like "*nt authority\local service*")))
                    {
                        # SharePoint to LDAP mapping hashtable
                        # Write an LDAP path/query for each SharePoint domain (or NetBIOS name) that you are working with
                        # Put all keys in lowercase
                        $spToADMapping = @{
                            'ftn' = 'LDAP://OU=1FTN Financial,OU=Domain Users,DC=ftbco,DC=FTN,DC=com'
                            'ftbco' = 'LDAP://OU=Domain Users,DC=ftbco,DC=FTN,DC=com'
                            'first_tennessee' = 'LDAP://CN=ForeignSecurityPrincipals,DC=ftbco,DC=FTN,DC=com'
                        }
 
                        # Check if login name is claims encoded
                        $loginNameDecoded = ""
                        if ($user.LoginName -like "*|*")
                        {
                            $mgr = [Microsoft.SharePoint.Administration.Claims.SPClaimProviderManager]::Local
                            if ($mgr -ne $null)
                            {
                                $loginNameDecoded = $mgr.DecodeClaim($user.LoginName).Value
                            }
                        }
                        else
                        {
                            $loginNameDecoded = $user.LoginName
                        }
                         
                        $loginNameArray = $loginNameDecoded.split("\")
                         
                        # Username without the domain part
                        $account = $loginNameArray[1]
                         
                        # Domain name in SharePoint which could also be the NetBIOS name depending on configuration
                        $domainInSharePoint = $loginNameArray[0]
                         
                        if ($spToADMapping.ContainsKey($domainInSharePoint.ToLower()))
                        {
                            $searchRoot = New-Object System.DirectoryServices.DirectoryEntry
                             
                            # This filter will check if the specified account exists in Active Directory
                            $filterForAnADUser = "(&(objectCategory=person)(objectClass=user)(samAccountName=$account))"
                                                          
                            $activeUserSearcher = New-Object System.DirectoryServices.DirectorySearcher
                            $activeUserSearcher.SearchRoot = $spToADMapping[$domainInSharePoint.ToLower()]
                            $activeUserSearcher.Filter = $filterForAnADUser
                            $activeUserResult = $activeUserSearcher.FindOne()
                             
                            #Uncomment below lines if disabled users are to be deleted too
                            # This filter will check if the specified account has been disabled in Active Directory
                            #$filterForADisabledADUser = "(&(objectCategory=person)(objectClass=user)(samAccountName=$account)(userAccountControl:1.2.840.113556.1.4.803:=2))"

                            #$disabledUserSearcher = New-Object System.DirectoryServices.DirectorySearcher
                            #$disabledUserSearcher.SearchRoot = $spToADMapping[$domainInSharePoint.ToLower()]
                            #$disabledUserSearcher.Filter = $filterForADisabledADUser
                            #$disabledUserResult = $disabledUserSearcher.FindOne()
                             
                            $consoleMessage = ""
                            $orphanType = ""
                            $toDelete = $false
                             
                            if ($activeUserResult -eq $null)
                            {
                                # The user does not exist in AD. Let's mark it for deletion from SharePoint.
                                $toDelete = $true
                                $consoleMessage = "Not in AD:"
                                $orphanType = "Deleted"
                            }

                            #Uncomment below lines if disabled users are to be deleted too
                            #if ($disabledUserResult -ne $null)
                            #{
                                # The user has been disabled in AD. Let's mark it for deletion from SharePoint.
                                #$toDelete = $true
                                #$consoleMessage = "|Not ACTIVE in AD:"
                                #$orphanType = "Disabled"
                            #}
                             
                            if ($toDelete -eq $true)
                            {
                                if (!($orphanedUsers.ContainsKey($user.LoginName.ToLower())))
                                {
                                    $orphanedUsers.add($user.LoginName.ToLower(), $web.Url)
                                     
                                    # Prints out lots of messages to the consoleMessage
                                    # Uncomment this if you like
                                    Write-host "$consoleMessage $loginNameDecoded" -ForegroundColor Yellow
                                     
                                    # When an employee is replaced, organizations often need to copy over the SharePoint permissions associated with the previous employee's role to the newly on-boarded employee
                                    # If the previous employee is deleted from SharePoint, we won't be able to see the groups they belonged to thereafter
                                    # To prevent this problem, we will log the information about groups that an orphaned user belongs to before we delete them
                                    # This log can also be used for other purposes (audit, etc)
                                    $userGroups = ""
                                    Foreach ($group in $user.Groups)
                                    {
                                        $userGroups += $group.Name + "`n"
                                    }
                                    $userGroups = $userGroups.Trim()
                                    
                                    # Double quotes so that the CSV (Microsoft Excel) will honor the newline character inside the "Group(s)" cell
                                    $userGroups = '"' + $userGroups  + '"'
                                     
                                    # The groups a user belongs to will be listed one group per line in the output .csv file
                                    "$domainInSharePoint|$($user.Name)|$loginNameDecoded|$($web.Url)|$userGroups|$orphanType" | out-file $OrphanUsersReport -append
                                }
                            }
                        }
                    }
                }
            }
        #}
    }
}
 
# Delete the orphaned users from SharePoint
# Proceed with caution when executing this section
# See comments inside the block
Foreach ($orphan in $orphanedUsers.keys)
{
    # Check if login name is claims encoded
    # This block is only used to provide clean Write-Host messages
    # Uncomment this if you like since it is probably overkill
    # If you uncomment it, just replace $loginNameWithoutClaims with $orphan in the Write-Host command after Remove-SPUser
    $loginNameWithoutClaims = ""
    if ($orphan -like "*|*")
    {
        $cMgr = [Microsoft.SharePoint.Administration.Claims.SPClaimProviderManager]::Local
        if ($cMgr -ne $null)
        {
            $loginNameWithoutClaims = $cMgr.DecodeClaim($orphan).Value
        }
    }
    else
    {
        $loginNameWithoutClaims = $orphan
    }
     
    # Since user deletion from SharePoint is not exactly reversible, I strongly recommend extensive testing before you let this script loose in your SharePoint farm
    # To allow testing user deletion one by one, I have deliberately set the -confirm flag to true in the command below
    # So, before each user gets deleted, you will have a chance to inspect the user before pressing yes
    # When you are comfortable with your test results, you can run the script without pauses by changing $true to $false in the command below
    #Remove-SPUser $orphan -web $orphanedUsers[$orphan] -confirm:$false
    Write-Host "User $loginNameWithoutClaims processed and/or deleted" -ForegroundColor Yellow
     
    # Comment out these two lines if you don't want the "Press any key to continue..." feature after each user deletion is processed
    # Note: This feature does not work with PowerShell ISE
    #Write-Host -NoNewLine "`nPress any key to continue...";
    #$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}

# Get End Time
$endDTM = (Get-Date)
# Get Time elapsed
"`r`n$(Get-Date) Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

stop-transcript
