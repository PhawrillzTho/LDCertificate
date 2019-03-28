#!/bin/bash
############################################################################################
#
# ldcertificatenix - Gather Certificates data and assign them into json structure for LANDesk Inventory
# Written By: Jacob Tucker
#
############################################################################################

target=/etc/ssl/certs
path=/etc/ssl/certs/
cd "$path"
DATE=`date '+%Y-%m-%d %H:%M:%S'`
epochnow=$(date +%s)
certcount=(*.crt);
certcount=${#certcount[@]}

cat <<__CDStruct
{
        "customData": {
                "label": "LDCertificate",
                "containers": [
__CDStruct

shopt -s nullglob
certarray=(*.crt)

for ((c=0; c < $certcount; c++)); do

if [ $c -gt 0 ]
then
        echo "]},"
fi

thumbprint="$(openssl x509 -in "${certarray[$c]}" -fingerprint -noout)"
thumbprint="$(echo $thumbprint | cut -c18-1024)"

issuer="$(openssl x509 -in "${certarray[$c]}" -issuer -noout)"
issuer="$(echo $issuer | cut -c9-1024)"

subject="$(openssl x509 -in "${certarray[$c]}" -subject -noout)"
subject="$(echo $subject | cut -c10-1024)"

serial="$(openssl x509 -in "${certarray[$c]}" -serial -noout)"
serial="$(echo $serial | cut -c8-1024)"

notbefore="$(openssl x509 -in "${certarray[$c]}" -startdate -noout)"
notafter="$(openssl x509 -in "${certarray[$c]}" -enddate -noout)"

location="$(pwd)"

scriptlastran=$(date +%s)

notbefore="$(echo $notbefore | cut -c11-1024)"
notafter="$(echo $notafter | cut -c10-1024)"
notbefore="$(date -d "$notbefore" '+%s')"
notafter="$(date -d "$notafter" '+%s')"

#Set 'ExpiresInDays' field
expiresindays="$(($notafter-$epochnow))"
expiresindays="$(($expiresindays / 86400))"


cat <<__CDLabel

{
                        "label": "(Thumbprint:$thumbprint)",

                        "containers": [
__CDLabel
cat <<__CDProp

{
                        "Thumbprint": "$thumbprint",
                        "Issuer": "$issuer",
                        "Subject": "$subject",
                        "Serial": "$serial",
                        "NotBefore": "$notbefore",
                        "NotAfter": "$notafter",
                        "Location": "$location",
                        "ScriptLastRan": "$scriptlastran",
                        "ExpiresInDays": "$expiresindays"
                        }
__CDProp

done

cat <<__CDLabel
]
                }
__CDLabel


cat <<__CDStruct
]
        }
}
__CDStruct

