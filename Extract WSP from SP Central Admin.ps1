$farm = Get-SPFarm
$file = $farm.Solutions.Item("FHN.MarginNet.Web.wsp").SolutionFile
$file.SaveAs("C:\SP2010\WSPs\FHN.MarginNet.Web.wsp")
