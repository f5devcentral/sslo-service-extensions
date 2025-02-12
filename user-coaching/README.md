# SSLO User Coaching Implementation

Requires:
* BIG-IP SSL Orchestrator 17.1.x (SSLO 11.1+)
* URLDB subscription -or- custom URL category

To implement via installer:
1. Run the following from the BIG-IP shell to get the installer:
  ```bash
  curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/user-coaching/user-coaching-installer.sh -o user-coaching-installer.sh
  chmod +x user-coaching-installer.sh
  ```

2. Export the BIG-IP user:pass:
  ```bash
  export BIGUSER='admin:password'
  ```

3. Run the script to create all of the User Coaching objects
  ```bash
  ./user-coaching-installer.sh
  ```

4. Add the "user-coaching-ja4t-rule" iRule to the SSLO outbound topology interception rule

5. Add the resulting "ssloS_F5_UC" inspection service in SSLO to a decrypted traffic service chain


------
To implement manually:

1. Create the iFile system object by importing the **user-coaching-html** file.
2. Create the iFile LTM object, selecting above iFile system object. Use "user-coaching-html" as name.
3. Create the iFile system object by importing the **user-blocking-html** file.
4. Create the iFile LTM object, selecting above iFile system object. Use "user-blocking-html" as name.
5. Import the **user-coaching-rule** iRule.
6. Import the **user-coaching-ja4t-rule** iRule.
7. Create the SSL Orchestrator inspection service for UC:
   a. Type: Office 365 Tenant Restrictions
   b. Name: Provide a name (ex. F5_UC)
   c. Restrict Access to Tenant: anything...(doesn't matter)
   d. Restrict Access Context: anything...(doesn't matter)
   e. iRules: select the **user-coaching-rule** iRule
   f. Deploy
8. Update the user coaching service virtual server (Local Traffic -> Virtual Servers): Remove the built-in tenant restrictions iRule.
9. Add the "user-coaching-ja4t-rule" iRule to the SSLO outbound topology interception rule
10. Add the user coaching inspection service in SSLO to a decrypted traffic service chain


------
To Remove:
1. Remove the ssloS_F5_UC service from any SSLO service chain
2. Delete the ssloS_F5_UC service
3. Remove the user-coaching-ja4t-rule iRule from the SSLO interception rule
4. Delete the user-coaching-ja4t-rule and user-coaching-rule iRules
5. Delete the user-coaching iFile (LTM and system)
6. Delete the user-blocking iFile (LTM and system)




