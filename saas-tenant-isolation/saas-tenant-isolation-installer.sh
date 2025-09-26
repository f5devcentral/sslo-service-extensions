#!/bin/bash
# Author: kevin-at-f5-dot-com
# Version: 20250926-1
# Installs the SaaS Tenant Isolation Service Extension

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

## Install saas-tenant iRule
echo "..Creating the saas-tenant-rule iRule"
curl -sk "https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/saas-tenant-isolation/saas-tenant-isolation-rule" -o saas-tenant-rule.in
python3 rule-converter.py saas-tenant-rule.in
rule=$(cat saas-tenant-rule.out)
data="{\"name\":\"saas-tenant-rule\",\"apiAnonymous\":\"${rule}\"}"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "${data}" \
https://localhost/mgmt/tm/ltm/rule -o /dev/null


## Create SSLO SaaS Tenant Isolation Inspection Service
echo "..Creating the SSLO saas-tenant-isolation inspection service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-d "$(curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/saas-tenant-isolation/saas-tenant-isolation-service)" \
https://localhost/mgmt/shared/iapp/blocks -o /dev/null


## Sleep for 15 seconds to allow SSLO inspection service creation to finish
echo "..Sleeping for 15 seconds to allow SSLO inspection service creation to finish"
sleep 15


## Modify SSLO SaaS Tenant Isolation Service (remove tenant-restrictions iRule)
echo "..Modifying the SSLO saas-tenant-isolation service"
curl -sk \
-u ${BIGUSER} \
-H "Content-Type: application/json" \
-X PATCH \
-d '{"rules":["/Common/saas-tenant-rule"]}' \
https://localhost/mgmt/tm/ltm/virtual/ssloS_F5_SaaS-Tenant-Isolation.app~ssloS_F5_SaaS-Tenant-Isolation-t-4 -o /dev/null


echo "..Cleaning up temporary files"
rm -f rule-converter.py saas-tenant-isolation-rule.in saas-tenant-isolation-rule.out


echo "..Done"
