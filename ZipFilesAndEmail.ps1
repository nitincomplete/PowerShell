$16Report = "D:\Reports\SP2016_SiteReport.csv"
$13Report = "\\ServerName\reports\SP2013_SiteReport.csv"
$Archive = "D:\Reports\ArchiveReports\"
$16File = "SP2016_SiteReport.csv"
$13File = "SP2013_SiteReport.csv"
$Month = (Get-Date).ToString('MMMM').ToUpper()
$Year = Get-Date -Format yyyy
$ZipName = "${Month}-${year}_Site_Reports.zip"

#Move and compress files
Move-Item $13Report -Destination $Archive
Move-Item $16Report -Destination $Archive
#Copy-Item $13Report -Destination $Archive
#Copy-Item $16Report -Destination $Archive
Compress-Archive -Path $Archive$16File, $Archive$13File -DestinationPath $Archive\$ZipName
Remove-Item $Archive$16File
Remove-Item $Archive$13File

#Email
$To = "<myemail@myemail.com>"
$From = "<myemail@myemail.com>"
$Subject = "${Month}-${Year} SharePoint Reports"
$Body = "The monthly site reports for SharePoint 2013 and SharePoint 2016 are attached.<br /><br />
         Do Not Reply to this email<br />
         If you have any issues, please email myemail@myemail.com"
Send-MailMessage -BodyAsHtml -To $To -From $From -Subject $Subject -Body $Body -Attachments $Archive\$ZipName  -SmtpServer "smtp.myemail.com"
