# SSL Orchestrator User Coaching

User coaching is an F5 SSL Orchestrator **service extension** function intended to either block or coach users away from (potentially) harmful applications. This SSL Orchestrator service extension is invoked at some event (ex. a user accessing a Generative AI tool, based on URL category match) and generates a coaching page that supports simple acknowledgement, justification input, and event logging.

Requires:
* BIG-IP SSL Orchestrator 17.1.x (SSLO 11.1+)
* URLDB subscription -and/or- custom URL category

----

### What is User Coaching?
User Coaching notifies and "coaches" a user when they attempt to access something that may violate local security policy. Some things can be blocked, but it's often useful to coach but then still allow access. For example, enterprise policy may allow access to external generative AI tools, again, like ChatGPT, Copilot, etc., but you want users to be aware that they're treading into potentially dangerous territory. In most cases, when the user sees the coaching page, they'll head back to safer ground knowing that additional scrutiny will be applied if going forward despite the warning.

------

### To implement via installer:
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

4. Add the "user-coaching-ja4t-rule" iRule to the SSL Orchestrator outbound topology interception rule (if the JA4 IDENTIFIER_TYPE is required - see below). In the SSL Orchestrator, select the Interception Rules tab and then click to edit the "-t-4" (and/or -t-6) Interception Rule. In the Resources section, move the **user-coaching-ja4t-rule** to the Selected box, and then Deploy to save changes.

5. Add the resulting "ssloS_F5_UC" inspection service in SSLO to a decrypted traffic service chain. The installer creates a new inspection service named "ssloS_F5_UC". Add this inspection service to any service chain that can receive decrypted HTTP traffic. Service extension services will only trigger on decrypted HTTP, so can be inserted into service chains that may also see TLS intercepts traffic. SSL Orchestrator will simply bypass this service for anything that is not decrypted HTTP.


------
### To customize functionality
The **user-coaching-rule** iRule has a number of editable settings:

* **BLOCKING_CATEGORIES**: Use this array to include any URL categories (subscription or custom) to trigger a blocking page.
* **COACHING_CATEGORIES**: Use this array to include any URL categories (subscription or custom) to trigger a coaching page.
* **CATEGORY_TYPE**: Set this to either "subscription", "custom_only", or "sub_and_custom" to select the category type(s) to query.
* **IDENTIFIER_TYPE**: Set this to specify either JA4 TLS fingerprint or browser (domain) cookie to maintain user agent persistence.
  * The **ja4** method creates a local session table entry (client IP + domain + ja4 fingerprint) to identify a user/browser session, and requires a JA4
    TLS fingerprint iRule on the "-in-t-4/6" SSL Orchestrator interception rule virtual server. This iRule is created automatically with the installer but
    must be added to the interception rule manually.
  * The **cookie** method maintains user/browser session uniqueness with a domain cookie into the browser for each triggered coaching domain.
* **COOKIE_KEY** and **COOKIE_IDENT**: When the cookie IDENTIFIER_TYPE is used, the COOKIE_IDENT contains the value of the "f5se_coaching" domain cookie sent to the browser. If the COOKIE_KEY contains an AES key string, the f5se_coaching cooking is optionally encrypted with this key.
* **SESSION_TIMER**: When using the JA4 IDENTIFIER_TYPE, use this value to define the timeout for a coaching page. By default a table entry is created for coaching based on client source address + domain portion of the requested URL + JA4 TLS fingerprint. This creates a token that is unique to the user (by source IP), the requested domain, and the specific browser user agent. The default is 3600 seconds (1 hour) of idle time, with no lifetime set.
* **BLOCKING_MESSAGE**: Use this string to indicate the message that will appear on the blocking page. This text will be injected into the blocking page dynamically. The "THISHOST" variable is replaced at runtime with the actual HTTP Host value.
* **COACHING_MESSAGE**: Use this string to indicate the message that will appear on the coaching page. This text will be injected into the coaching page dynamically. The "THISHOST" variable is replaced at runtime with the actual HTTP Host value.
* **REQUIRE_JUSTIFICATION**: Use this Boolean option to enable and require a justification in the coaching page. Enter a 1 to enable a justification form post in the coaching page. The (default) coaching page will add a justification text box that must contain a value to submit the page. That justification text will be inserted into the event log.
* **LOG_ENABLED**: Use this Boolean option to enable/disable logging of coaching page access. A value of 0 disables, a value of 1 enables. In its current state the iRule logs  to local0. in the JUSTIFICATION proc, but that can be updated to point to an HSL and/or other remote logging facility. Logging creates the following message, where "data" is the supplied justification text.
  ```
  ALERT-COACHING-TRIGGER::${timestr}::client=[IP::client_addr]::host=${host}::${data}
  ```
* **LOG_POOL**: To send logs to a remote Syslog, create an HSL pool and enter that pool name here.

The **user-coaching-html** and **user-blocking-html** iFiles are also completely customizable based on your local needs. In the BIG-IP UI, under System -> File Management -> iFile List, select Import, choose a new HTML file, select Overwrite Existing, and select either the user-coaching-html or user-blocking-html to replace each one.

------
### To implement manually:
In the event that the installer cannot be used to create all of the objects, please follow the below steps to create manually.

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
9. Add the "user-coaching-ja4t-rule" iRule to the SSLO outbound topology interception rule if the JA4 IDENTIFIER_TYPE is required.
10. Add the user coaching inspection service in SSLO to a decrypted traffic service chain


------
### To Remove:

1. Remove the ssloS_F5_UC service from any SSLO service chain
2. Delete the ssloS_F5_UC service
3. Remove the user-coaching-ja4t-rule iRule from the SSLO interception rule
4. Delete the user-coaching-ja4t-rule and user-coaching-rule iRules
5. Delete the user-coaching iFile (LTM and system)
6. Delete the user-blocking iFile (LTM and system)

------
### Sample user-coaching and user-blocking pages
![sslo-user-blocking-sample](https://github.com/user-attachments/assets/0a63852e-0c09-453d-b0ea-660d7fe078dd)

![sslo-user-coaching-sample](https://github.com/user-attachments/assets/c3007f38-0fab-4d64-8d04-f4bac1588dc7)

![sslo-user-coaching-justification-sample](https://github.com/user-attachments/assets/7ac81fb9-6faa-418e-a956-a304cf4791ae)

