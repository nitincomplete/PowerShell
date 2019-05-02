$LogPath = "C:\Logs\"
$LogTime = Get-Date -Format yyyy-MM-dd_hh-mm
$LogFile = "$LogPath\Full-UPS_Audience-Sync-$LogTime.log"

start-transcript $LogFile
    
    try{
        # Delete all log Files Logs older than 15 day(s)
        $Daysback = "-15"
        $CurrentDate = Get-Date
        $DatetoDelete = $CurrentDate.AddDays($Daysback)
        $files = Get-ChildItem $LogPath -Recurse -force -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt "$DatetoDelete" } 

        foreach($file in $files)
        {
            write-host "Deleting File $File" backgroundcolor "DarkRed"
            Remove-item $file.Fullname | out-null
        }
    }
    catch{
        Write-Host "delete older log files, Error: $_" -fore red
    }

stop-transcript
