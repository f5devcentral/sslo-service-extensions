#!/bin/bash
# Author: kevin-at-f5-dot-com
# Version: 20260209-1
# Installs the User Coaching Service Extension

if [[ -z "${BIGUSER}" ]]
then
    echo 
    echo "The user:pass must be set in an environment variable. Exiting."
    echo "   export BIGUSER='admin:password'"
    echo 
    exit 1
fi

## Create temporary Python converter
cat > "rule-converter.py" << 'EOF'
import sys

filename = sys.argv[1]

with open(filename, "r") as file:
    lines = file.readlines()

escape_chars = {
    '\\': '\\\\',
    '"': '\\"',
    '\n': '\\n',
    '\[': '\\[',
    '\]': '\\]',
    '\.': '\\.',
    '\d': '\\d',
}

one_line = "".join(lines)
for old, new in escape_chars.items():
    one_line = one_line.replace(old, new)

output_filename = filename.split(".")[0] + ".out"
with open(output_filename, "w") as f:
    f.write(one_line)
EOF

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

## Install user-coaching iRule
echo "..Creating the user-coaching-rule iRule"
curl -sk "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-html" -o user-coaching-rule.in
python3 rule-converter.py user-coaching-rule.in
rule=$(cat user-coaching-rule.out)
data="{\"name\":\"user-coaching-rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null

## Install user-coaching-ja4t-rule iRule
echo "..Creating the user-coaching-ja4t-rule iRule"
curl -sk "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-ja4-rule" -o user-coaching-ja4t-rule.in
python3 rule-converter.py user-coaching-ja4t-rule.in
rule=$(cat user-coaching-ja4t-rule.out)
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

echo "..Cleaning up temporary files"
rm -f rule-converter.py user-coaching-ja4t-rule.in user-coaching-ja4t-rule.out user-coaching-rule.in user-coaching-rule.out

echo "..Done"
