#!/bin/bash

if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

## Create iFile System object (user-coaching-html)
echo "..Creating the iFile system object for the user-coaching-html"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d '{"name": "user-coaching-html", "source-path": "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-html"}' \
https://localhost/mgmt/tm/sys/file/ifile/ -o /dev/null

# ## Create iFile LTM object (user-coaching-html)
echo "..Creating the iFile LTM object for the user-coaching-html"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d '{"name":"user-coaching-html", "file-name": "user-coaching-html"}' \
https://localhost/mgmt/tm/ltm/ifile -o /dev/null

## Create iFile System object (user-blocking-html)
echo "..Creating the iFile system object for the user-blocking-html"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d '{"name": "user-blocking-html", "source-path": "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-blocking-html"}' \
https://localhost/mgmt/tm/sys/file/ifile/ -o /dev/null

# ## Create iFile LTM object (user-blocking-html)
echo "..Creating the iFile LTM object for the user-blocking-html"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d '{"name":"user-blocking-html", "file-name": "user-blocking-html"}' \
https://localhost/mgmt/tm/ltm/ifile -o /dev/null

# ## Install user-coaching-rule iRule
echo "..Creating the user-coaching-rule iRule"
rule=$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-rule | awk '{printf "%s\\n", $0}' | sed -e 's/\"/\\"/g;s/\x27/\\'"'"'/g')
data="{\"name\":\"user-coaching-rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null

# ## Install user-coaching-ja4t-rule iRule
echo "..Creating the user-coaching-ja4t-rule iRule"
rule=$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-ja4-rule | awk '{printf "%s\\n", $0}' | sed -e 's/\"/\\"/g;s/\x27/\\'"'"'/g')
data="{\"name\":\"user-coaching-ja4t-rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null

## Create SSLO User-Coaching Inspection Service
echo "..Creating the SSLO user-coaching inspection service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-service)" \
https://localhost/mgmt/shared/iapp/blocks -o /dev/null

## Sleep for 15 seconds to allow SSLO inspection service creation to finish
echo "..Sleeping for 15 seconds to allow SSLO inspection service creation to finish"
sleep 15

## Modify SSLO User-Coaching Service (remove tenant-restrictions iRule)
echo "..Modifying the SSLO user-coaching service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-X PATCH \
-d '{"rules":["/Common/user-coaching-rule"]}' \
https://localhost/mgmt/tm/ltm/virtual/ssloS_F5_UC.app~ssloS_F5_UC-t-4 -o /dev/null

echo "..Done"
