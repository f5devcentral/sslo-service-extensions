
# SSL Orchestrator SaaS Tenant Isolation
SaaS Tenant Isolation is an F5 SSL Orchestrator **service extension** function for managing tenant isolation (aka. restrictions) for several SaaS applications in a corporate environment. Tenant isolation is a way for corporate entities to control access to non-corporate SaaS endpoints, typically to defend against misuse and sensitive data exfiltration. For example, an enterprise user may have Office365 accounts from multiple organizations. Tenant isolation prevents that user from copying data from their company Sharepoint to an Office365 endpoint in another organization. This service extension enhances the SSL Orchestrator built-in Office365 Tenant Restrictions service, providing for additional SaaS property controls:

* Office365 Tenant Restrictions v1
* Office365 Tenant Restrictions v2
* Webex
* Google GCloud
* Dropbox
* Youtube
* Slack
* Zoom
* Github
* ChatGPT

Requires:
* BIG-IP SSL Orchestrator 17.1.x (SSLO 11.1+)

### To implement via installer:
1. Run the following from the BIG-IP shell to get the installer:
  ```bash
  curl -sk https://raw.githubusercontent.com/f5devcentral/sslo-service-extensions/refs/heads/main/saas-tenant-isolation/saas-tenant-isolation-installer.sh -o saas-tenant-isolation-installer.sh
  chmod +x saas-tenant-isolation-installer.sh
  ```

2. Export the BIG-IP user:pass:
  ```bash
  export BIGUSER='admin:password'
  ```

3. Run the script to create all of the SaaS Tenant Isolation objects
  ```bash
  ./saas-tenant-isolation-installer.sh
  ```

4. The installer creates a new inspection service named "ssloS_F5_SaaS-Tenant-Isolation". Add this inspection service to any service chain that can receive decrypted HTTP traffic. Service extension services will only trigger on decrypted HTTP, so can be inserted into service chains that may also see TLS bypass traffic (not decrypted). SSL Orchestrator will simply bypass this service for anything that is not decrypted HTTP.

------
### To customize functionality
The **saas-tenant-rule** has a set of editable configuration blocks for each SaaS. For example:
* **USE_OFFICE365_V1**: <br />Enables or disables tenant control for this SaaS endpoint.
* **SAAS_OFFICE365_V1_HEADERS**: <br />Defines the header(s) to be be injected for this SaaS endpoint. Each line in the list consists of two values:
  * **Header Name**: (ex. Restrict-Access-To-Tenants)
  * **Header Value**: Typically and organization ID. The *Ref:* field in the comment block points to a resource that explains how this field muct be populated.

------
### Testing Header Injection

For testing purposes, a separate "TESTING" control has also been included, hardcoding a set of headers, and **httpbin.org** as the trigger URL. To test, ensure that the **USE_TESTING** variable is enabled (set to 1), and then from a Curl client or browser, navigate to https://httbin.org/headers. If successful, httpbin.org will mirror the headers sent to it:

```bash
{
  "headers": {
    "Accept": "*/*", 
    "Host": "httpbin.org", 
    "User-Agent": "curl/7.68.0", 
    "X-Amzn-Trace-Id": "Root=1-68d6d4f4-4bf65c9e4318a6db3cdf0928", 
    "X-Test-Header-1": "test-value-a", 
    "X-Test-Header-2": "test-value-b"
  }
}
```
The two "X-Test-Header-" headers are injected by the iRule.






