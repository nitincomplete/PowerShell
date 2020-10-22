if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) 
{ 
   Add-PSSnapin Microsoft.SharePoint.PowerShell 
}
$count=0;

$SPWebApp = Get-SPWebApplication http://spwf

foreach ($SPSite in $SPWebApp.Sites)
{
$rootWeb = $SPSite.RootWeb
# Get the GUID of your Site Column
$fields=$rootWeb.Fields;
$guid = $fields["Title"].id

    if ($SPSite -ne $null)
    {
        foreach($Web in $SPSite.AllWebs)
       {
            $lists =$web.Lists;

            for ($i=0; $i -lt $lists.count ; $i++)
                {
                  for ($j=0; $j -lt $lists[$i].fields.count; $j++)
                    {
                        if ($lists[$i].fields[$j].id -eq $guid)
                        {
                            $count =$count +1;
                            Write-host  $lists[$i].Title " in " $Web.Url " has column"
                        }
                    }
                }
                
	  
      }

        $SPSite.Dispose()
    }
}

Write-Host "Site Column Tite is referenced in " $count " List in all sites and sitecollection"
