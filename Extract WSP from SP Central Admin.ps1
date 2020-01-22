$farm = Get-SPFarm
$file = $farm.Solutions.Item("<WSP_Name>.wsp").SolutionFile
$file.SaveAs("C:\SP2010\WSPs\<WSP_Name>.wsp")
