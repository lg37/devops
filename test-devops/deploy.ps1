param($ResourceGroupName, $templatefile, $parameterfile)
$today=Get-Date -Format "MM-dd-yyyy"
$deploymentName="test_devops"+"$today"
Write-Output "using RG: $ResourceGroupName"
Write-Output "using params: $parameterfile"
New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $PSScriptRoot\$templatefile -TemplateParameterFile $PSScriptRoot\$parameterfile