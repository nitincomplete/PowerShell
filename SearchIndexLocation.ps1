#In order to determine what your actual Search Service Application settings are, simply run the following lines in a PowerShell prompt.
$searchServiceApp = Get-SPServiceApplication -Name "Search Service Application"
$activeTopology = $searchServiceApp.ActiveTopology
Get-SPEnterpriseSearchComponent -SearchTopology $activeTopology

#To find out the default search index location, you can run a different set of PowerShell commands as follows
$ssi = Get-SPEnterpriseSearchServiceInstance
$ssi.Components

#To find the index location:
$essi = Get-SPEnterpriseSearchServiceInstance
$cc = $essi.Components | ? { $_.GetType().Name -eq 'CrawlComponent' }
$cc.IndexLocation
