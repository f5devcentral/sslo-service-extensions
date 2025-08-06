#!/bin/bash
# Author: kevin-at-f5-dot-com
# Version: 20250806-1
# Installs the DoH Guardian SSL Orchestrator Service Extension

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

## Install doh-guardian-rule iRule
echo "..Creating the doh-guardian-rule iRule"
curl -sk "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/doh-guardian/doh-guardian-rule" -o doh-guardian-rule.in
python3 rule-converter.py doh-guardian-rule.in
rule=$(cat doh-guardian-rule.out)
data="{\"name\":\"doh-guardian-rule-1\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null


## Create SSLO DoH-Guardian Inspection Service
echo "..Creating the SSLO doh-guardian inspection service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/doh-guardian/doh-guardian-service)" \
https://localhost/mgmt/shared/iapp/blocks -o /dev/null


## Sleep for 15 seconds to allow SSLO inspection service creation to finish
echo "..Sleeping for 15 seconds to allow SSLO inspection service creation to finish"
sleep 15


## Modify SSLO DoH-Guardian Service (remove tenant-restrictions iRule)
echo "..Modifying the SSLO doh-guardian service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-X PATCH \
-d '{"rules":["/Common/doh-guardian-rule"]}' \
https://localhost/mgmt/tm/ltm/virtual/ssloS_F5_DoH.app~ssloS_F5_DoH-t-4 -o /dev/null


echo "..Cleaning up temporary files"
rm -f rule-converter.py doh-guardian-rule.in doh-guardian-rule.out


echo "..Done"
