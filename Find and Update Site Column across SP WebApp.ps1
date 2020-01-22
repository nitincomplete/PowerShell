Param([Parameter(Mandatory=$true)][string]$LogPath, [Parameter(Mandatory=$true)][string]$webAppUrl)

#********Script to Modify (SystemUpdate) 'Data Classification' field **********#

if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

$assembly = [Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")
$type = $assembly.GetType("Microsoft.SharePoint.SPEventManager");
$propEventFiring = $type.GetProperty([string]"EventFiringDisabled",[System.Reflection.BindingFlags] ([System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Static)); 

$fieldDataClassification = "Data Classification"

$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm
$LogFile = "$LogPath\SP10_Correct-DataClassification_$LogTime.log"

start-transcript $LogFile

# Get Start Time
$startDTM = (Get-Date)

    if($null -ne $webAppUrl)
    {
        Write-Host "WebApp is Not Null"
        Write-Host "Web Application : " $webAppUrl -ForegroundColor Green
        $Allsites = Get-SPWebApplication $webAppUrl | Get-SPSite -Limit All
        if($null -ne $Allsites){
            foreach($site in $Allsites)
            {
                $siteColl = Get-SPSite $Site
                if($null -ne $siteColl)
                {
                    try{
                        #Write-Host "`r`n$(Get-Date) Processing Site Collection|"$site.Url -ForegroundColor Green
                        foreach($web in $siteColl.AllWebs)
                        {
                            try
                            {
                                if($null -ne $web)
                                {
                                    #write-host "`r`n$(Get-Date) `t Processing Subsite|"$web.Url -ForegroundColor Yellow
                                    $Libraries = $web.Lists | where {($_.BaseType -eq "DocumentLibrary") -and ($_.Hidden -eq $false)}
                                    foreach($list in $Libraries)
                                    {
                                        try{
                                            if( ($list.Title -ne "Site Assets") -and ($list.Title -ne "Site Pages") -and ($list.Title -ne "Style Library") -and ($list.Title -ne "Form Templates") )
                                            {
                                                #write-host "`r`n$(Get-Date) Processing List Name|"$list.Title
                                                if(($null -ne $list.Fields) -and ($list.Fields.ContainsField($fieldDataClassification) -eq $true) )
                                                {
                                                    write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|True"
                                                    $items = $list.items
                                                    if($null -ne $items)
                                                    {
                                                        #Go through all items
                                                        #write-host "`r`n$(Get-Date)|Updating lib '" $list.Title "'..."
                                                        foreach($item in $items)
                                                        {
                                                            try{
                                                                if( ($item[$fieldDataClassification] -eq "Public / Internal Use") -or ($item[$fieldDataClassification] -eq "Public - Internal Use") )
                                                                {
                                                                    $item[$fieldDataClassification] = "Internal"
                                                                }
                                                                elseif( ($item[$fieldDataClassification] -eq "Confidential / Highly Restricted") -or ($item[$fieldDataClassification] -eq "Confidential - Highly Restricted") )
                                                                {
                                                                    $item[$fieldDataClassification] = "Sensitive"
                                                                }
                                                                else{
                                                                    $item[$fieldDataClassification] = "Internal"
                                                                }
								                                $propEventFiring.SetValue($null, $true, $null); #SET EVENT FIRING DISABLED			
                                                                #Update the item
                                                                $item.SystemUpdate($false)
								                                $propEventFiring.SetValue($null, $false, $null); #SET EVENT FIRING DISABLED
                                                                #write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|True|Corrected ItemID: "$item["ID"] -ForegroundColor Green
                                                            }
                                                            catch 
                                                            { 
                                                                write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|True|Error ItemID:"$item["ID"]", Failed to update|Exception: "$_.Exception -ForegroundColor Red
                                                            }
                                                        }
                                                        write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|True|Finished Updating for whole Library" -ForegroundColor Green                                                
                                                    }
                                                    else{
                                                        write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|True|No Items" -ForegroundColor Green
                                                    }
                                                }
                                                else
						                        {  #This is culprit
                                                    write-host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|"$list.DefaultView.Url"|False"
                                                }
                                            }
                                        }
                                        catch 
                                        { 
                                            Write-Host "`r`n$(Get-Date)|"$site.Url"|"$web.Url"|"$list.Title"|Error at Foreach-Lists Iteration|Exception|"$_.Exception -ForegroundColor Red
                                        }
                                    }
                                    $web.Dispose()
                                }
                                else {
                                    Write-Host "`r`n$(Get-Date)|Subsite is Null|Exception|"$_.Exception.Message -ForegroundColor Red
                                }
                            }
                            catch 
                            { 
                                Write-Host "`r`n$(Get-Date)|Either web in error or List of Libraries in error|Exception|"$_.Exception.Message -ForegroundColor Red
                            }
                        }
                    }
                    catch{
                        Write-Host "`r`n$(Get-Date)|Exception|"$_.Exception.Message -ForegroundColor Red
                    }
                    finally{
                        $siteColl.Dispose()
                    }
                }
                else {
                    Write-Host "`r`n$(Get-Date)|SiteCollection is Null" -ForegroundColor Red
                }
            }
        }
        else {
            Write-Host "`r`n$(Get-Date)|No Site Collections available in this webapp." -ForegroundColor Red
        }
    }
    else {
        Write-Host "`r`n$(Get-Date)|WebApp is null" -ForegroundColor Red
    }


# Get End Time
$endDTM = (Get-Date)
# Get Time elapsed
"`r`n$(Get-Date) Elapsed Time: $(($endDTM-$startDTM).totalseconds) seconds"

stop-transcript
