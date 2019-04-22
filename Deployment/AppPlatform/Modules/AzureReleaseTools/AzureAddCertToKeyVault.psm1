#
# AzureReleaseTools.psm1
#
########################################
## START : Public Functions
########################################
function Add-CertificateToKeyVault {    
	param(
		$Environment,
		$KeyVaultName,
		$CertificatePath,
		$CertificatePassword,
		[string]$secretPrefix = "SPNCert-"
		)

	$secretContentType = 'application/x-pkcs12' 
	$secretName = $secretPrefix + $Environment

	$flag = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable 
	$collection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection 
	$collection.Import($CertificatePath, $CertificatePassword, $flag) 
	$pkcs12ContentType = [System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12 
	$clearBytes = $collection.Export($pkcs12ContentType) 
		
	$fileContentEncoded = [System.Convert]::ToBase64String($clearBytes) 
	$secret = ConvertTo-SecureString -String $fileContentEncoded -AsPlainText -Force

	write-host "Importing certificate into [$KeyVaultName] as [$secretName]"

	try {Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $secretName -SecretValue $Secret -ContentType $secretContentType}
	catch {throw "Could not import certificate - $($_.Exception)"}
}
Export-ModuleMember Add-CertificateToKeyVault
