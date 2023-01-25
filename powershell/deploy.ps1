param($ResourceGroupName, $templatefile, $parameterfile, $namePrefix)
$today=Get-Date -Format "MM-dd-yyyy-hh-mm-ss"
$deploymentName="test_devops"+"$today"
Write-Output "using RG: $ResourceGroupName"
Write-Output "using params: $parameterfile"
Write-Output "nom: $namePrefix"
New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $templatefile -TemplateParameterFile $parameterfile -namePrefix $namePrefix