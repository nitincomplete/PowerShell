[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

Function ManageAppPools{ 
    Param([bool]$Stop, [String]$AppPoolName)

    $spServers = GET-SPServer | where { $_.Role -ne "Invalid"}
    #Loop through each server and Check Application Pool status
    foreach ($Server in $spServers)
    {
        Write-Host "Server - $($Server.Address), Role: $($Server.Role), Status: $($Server.Status)"
        $ServerMgr = [Microsoft.Web.Administration.ServerManager]::OpenRemote($Server.Address)
        $AppPoolColl = $ServerMgr.ApplicationPools | Where-Object {$_.Name -eq $AppPoolName}
        
        if( ($null -ne $AppPoolColl) -and ($AppPoolColl.length -gt 0) )
        {
            foreach($AppPool in $AppPoolColl)
            {
                Write-Host "AppPool - $($AppPool.Name)"  -ForegroundColor Green
                if($Stop){
                    if($AppPool.State -ne "Stopped"){
                      try{
                        $AppPool.Stop()
                        Start-Sleep -s 10
                      }
                      catch{
                        Write-Host "$(Get-Date -Format yyyy-MM-dd_hh-mm) `t Error: $_" -fore red
                      }
                    }     
                    Write-Host "Application Pool '$($AppPoolName)' Status: $($AppPool.State)" -ForegroundColor Yellow
                }
                else{
                    $AppPool.Start()
                }

            }
        }
        else{
           Write-Host "Application Pool '$($AppPoolName)': Not Available" -ForegroundColor Cyan
        }
    }
}

ManageAppPools -Stop:$false "<appPoolName>"
