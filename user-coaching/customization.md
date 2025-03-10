## Customization

### Customizing the User-Coaching iRule

* **Category Lookup** (BLOCKING and COACHING): Use the following command in the BIG-IP shell to get a list of the available subscription URL categories:
  ```bash
  tmsh list sys url-db url-category |grep "sys url-db url-category " |awk -F" " '{print $4}'
  ```
  Enter the desired categories into the static::BLOCKING_CATEGORIES and/or static::COACHING_CATEGORIES as required. Example:
  ```
  set static::COACHING_CATEGORIES {
    "/Common/Generative_AI"
    "/Common/Generative_AI_-_Text_&_Code"
    "/Common/Generative_AI_-_Conversation"
    "/Common/Generative_AI_-_Multimedia"
  }
  ```

* **Category Type**: Use one of the following options in the static::CATEGORY_TYPE value:
  * "subscription": Search only the subscription URLDB categories
  * "custom_only": Search only the custom categories
  * "sub_and_custom": Search both subscription and custom categories
 
* **Identifier Type**: Use one of the following options in the static::IDENTIFIER_TYPE value:
  * "cookie": Use this option to inject a domain cookie into the client browser for user-agent uniqueness.
  * "ja4": Use this option to maintain a local session table with source ip + domain host + ja4 TLS fingerprint.

* **Cookie Key and Cookie Ident**: If using the cookie identifier type, the static::COOKIE_IDENT contains the value for the f5se_coaching cookie sent to the browser. If an AES 128-bit key string is applied to the static::COOKIE_KEY value, the cookie value will be optionally AES encrypted.

* **Session Timer**: If using the ja4 identifier type, the static::SESSION_TIMER contains the value in seconds to maintain the state table entry. The default is 3600 seconds.

* **Blocking Message**: The static::BLOCKING_MESSAGE value contains the dynamic text that will be inserted into the blocking page HTML (see "Customizing the Blocking HTML page" below).

* **Coaching Message**: The static::COACHING_MESSAGE value contains the dynamic text that will be inserted into the coaching page HTML (see "Customizing the User-Coachimg HTML page" below).

* **Require Justification**: The static::REQUIRE_JUSTIFICATION value is a Boolean (0 == off, 1 == on) that enables or disables a justification prompt in the default user-coaching page.

* **Log Enabled**: The static::LOG_ENABLED value is a Boolean (0 == off, 1 == on) that enables or disables logging of the 

-----
### Customizing the User-Coaching HTML page

