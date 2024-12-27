# Stopping the Gateway service
Stop-Service -Name TSGateway

# Define the path for the .cer file and the RDS Gateway server name
$cerFilePath = "C:\ExportFolder\certGW.cer"
$rdGatewayServer = "gwrdp.domain.tld"

# Get the most recent certificate from the LocalMachine\My (Personal) store
$cert = Get-ChildItem -Path Cert:\LocalMachine\My | Sort-Object -Property NotBefore -Descending | Select-Object -First 1

# Export the certificate to a .cer file
try {
    Export-Certificate -Cert $cert -FilePath $cerFilePath -Type CERT
    Write-Host "Certificate exported to $cerFilePath successfully."
} catch {
    Write-Error "Failed to export the certificate."
    return
}

# Import the .cer file into the certificate store (LocalMachine\My)
try {
    Import-Certificate -FilePath $cerFilePath -CertStoreLocation Cert:\LocalMachine\My
    Write-Host "Certificate imported to the certificate store successfully."
} catch {
    Write-Error "Failed to import the certificate."
    return
}

# Update the RDS Gateway configuration with the new certificate thumbprint
$thumbprint = $cert.Thumbprint
$gatewayRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\TSGateway"

if (-not (Test-Path $gatewayRegPath)) {
    Write-Error "RDS Gateway registry path not found. Ensure RDS Gateway is installed."
    return
}

Set-RDGWCertificate -Thumbprint $thumbprint

#Set-ItemProperty -Path $gatewayRegPath -Name "SSLCertificateSHA1Hash" -Value $thumbprint

# Restart the RDS Gateway service to apply the changes
Start-Service -Name TSGateway

Write-Host "Certificate exported, imported, and applied to RDS Gateway successfully."
