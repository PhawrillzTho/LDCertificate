############################################################################################
#
# LDCertificateWinPS - Gather Certificates data and store in WMI for LANDesk Inventory
# Written By: Jacob Tucker
#
############################################################################################

$ErrorActionPreference = "SilentlyContinue"
$CurrentTimeEpoch = [Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

Get-WmiObject LDCertificate -ErrorAction SilentlyContinue | Remove-WmiObject

$CertificatesRoot = Get-ChildItem "Cert:\LocalMachine\Root" -Recurse
$CertificatesCA = Get-ChildItem "Cert:\LocalMachine\CA" -Recurse
$CertificatesTP = Get-ChildItem "Cert:\LocalMachine\TrustedPublisher" -Recurse
$CertificatesMy = Get-ChildItem "Cert:\LocalMachine\My" -Recurse

$Certificates = $CertificatesRoot + $CertificatesCA + $CertificatesTP + $CertificatesMy

$newClass = New-Object System.Management.ManagementClass `
            ("root\cimv2", [String]::Empty, $null); 

       $newClass["__CLASS"] = "LDCertificate"; 
       $newClass.Qualifiers.Add("Static", $true)

$certificateProperties = "Issuer", "NotAfter", "NotBefore", "Subject", "ExpiresInDays", "ScriptLastRan", "Serial", "FriendlyName"

ForEach ($certificateProperty in $certificateProperties) {

       $newClass.Properties.Add($certificateProperty, `
            [System.Management.CimType]::String, $false)
}

       $newClass.Properties.Add("Location", `
            [System.Management.CimType]::String, $false)
       $newClass.Properties["Location"].Qualifiers.Add("Key", $true)

       $newClass.Properties.Add("ThumbPrint", `
            [System.Management.CimType]::String, $false)
       $newClass.Properties["ThumbPrint"].Qualifiers.Add("Key", $true)

       $newClass.Put()

ForEach ($Certificate in $Certificates) {

$NotAfterEpoch = [Math]::Floor([decimal](Get-Date($Certificate.NotAfter).ToUniversalTime()-uformat "%s"))
$NotBeforeEpoch = [Math]::Floor([decimal](Get-Date($Certificate.NotBefore).ToUniversalTime()-uformat "%s"))

$ExpiresInDays = ($Certificate.NotAfter-(Get-Date)).TotalDays
$ExpiresInDays = [int]$ExpiresInDays

$PSParentPath = $Certificate.PSParentPath
$PSParentPath = $PSParentPath -replace ".*::" -replace ",.*"

Set-WMIInstance -Namespace root\cimv2 -class LDCertificate -argument @{

ExpiresInDays = $ExpiresInDays;
ScriptLastRan = $CurrentTimeEpoch;
Location = $PSParentPath;
FriendlyName = $Certificate.FriendlyName; 
Issuer = $Certificate.Issuer; 
NotAfter = $NotAfterEpoch; 
NotBefore = $NotBeforeEpoch; 
Subject = $Certificate.Subject; 
ThumbPrint = $Certificate.ThumbPrint; 
Serial = $Certificate.SerialNumber

    }
}
