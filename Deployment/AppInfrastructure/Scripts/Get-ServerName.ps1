Param (
	[Parameter(Mandatory)][String] $ApiUserName,
    [Parameter(Mandatory)][String] $ApiUserPassword
)

if(-not ($env:systemId -and $env:environmentId -and $env:ServerList))
{
	Write-Output "You must set the following environment variables to test this script interactively."
	'$env:systemId - Identificator of the system should be a combination of the system and the environment'
	'$env:environmentId - Azure subscription where the server is being created Posible values'
	'						US Preprod: USAZUAUDDE'
	'						US Prod: USAZUAUD'
	'						Europe Preprod: EUAZUAUDDE'
	'						Europe Prod: EUAZUAUD'
	'						Asia Pacific Preprod: APAZUAUDDE'
	'						Asia Pacific Prod: APAZUAUD'
	'$env:ServerList - List of the servers and the types on the form of "WEB" = "2";"APP" = "1"; "DB" = "1"'
	exit 1
}

$systemId = $env:systemId
$environmentId = $env:environmentId

$serverList = $env:ServerList.Replace(";","`n") | ConvertFrom-StringData


Write-Host '------------ SERVER LIST -------------'
$serverList | Format-Table -AutoSize
Write-Host '--------------------------------------'

$serverRequest = ""

foreach($key in $serverList.Keys)
{
	$serverCount = $serverList[$Key]
    if($serverRequest -eq "")
	{
		$serverRequest = @"
		{"componentKey":"$key","numberServers":"$serverCount"}
"@
	}else{
		$serverRequest = @"
		$serverRequest,{"componentKey":"$key","numberServers":"$serverCount"}
"@
	}
}

$jsonBody = @"
{
    "environment":"$environmentId",
    "system":"$systemId",
	"vmAllocationRequest":[$serverRequest]
}
"@



$verb = "POST"
$contentType = "application/json"

$header = @{Authorization=("Basic {0}" -f ([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ApiUserName,$ApiUserPassword)))))} 
$credential = New-Object System.Management.Automation.PSCredential($ApiUserName, (ConvertTo-SecureString $ApiUserPassword -AsPlainText -Force))

$uri = "https://hosting.deloitte.com/api/serverRegistrations"

Write-Output "Body:"
Write-Output $jsonBody
#Write-Output "Headers:"
#Write-Output $Header


try {
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    $response = Invoke-RestMethod -Method $verb -Uri $uri -Headers $header -ContentType $contentType -Body $jsonBody -Credential $credential
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
} catch {
    Write-Host "Unable to get the servers name"
    $_ | Format-List * -Force
	exit 1
}

foreach ($component in $response.components)
{
	$component.componentName
	if ($component.servers -ne $null) {
		$component.servers.Length
	}
	$component.servers
    
	Write-Host("##vso[task.setvariable variable=$($component.componentName)ServerNames]$($component.servers)")
	if ($component.servers -ne $null) {
		Write-Host("##vso[task.setvariable variable=$($component.componentName)ServerCount]$($component.servers.Length)")
	}
	else {
		Write-Host("##vso[task.setvariable variable=$($component.componentName)ServerCount]$(0)")
	}
}
