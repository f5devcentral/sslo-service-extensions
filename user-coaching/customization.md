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

* **Blocking Message**: The static::BLOCKING_MESSAGE value contains the dynamic text that will be inserted into the blocking page HTML (see "Customizing the User-Blocking HTML page" below).

* **Coaching Message**: The static::COACHING_MESSAGE value contains the dynamic text that will be inserted into the coaching page HTML (see "Customizing the User-Coachimg HTML page" below).

* **Require Justification**: The static::REQUIRE_JUSTIFICATION value is a Boolean (0 == off, 1 == on) that enables or disables a justification prompt in the default user-coaching page.

* **Log Enabled**: The static::LOG_ENABLED value is a Boolean (0 == off, 1 == on) that enables or disables logging of the blocking and coaching events.

* **Log Pool**: The static::LOG_POOL value defines a local high-speed logging (HSL) pool. If defined, and LOG_ENABLED is also on, the log events are sent to the HSL instead of local Syslog.

-----
### Customizing the User-Coaching HTML page

The default coaching HTML page contains three variables that are defined and inserted by the user-coaching iRule:
* **receive_host**: Contains the HTTP host value. 
* **receive_uri**: Contains the base64-encoded full HOST and URL path of the original request. Together with the receive_host, a Javascript button action in the HTML redirects the user to the same page but with a "/f5_handler_coaching?uri=" path, followed by the encoded origin URL (host and path).
* **receive_msg**: Contains the message provided by the static::COACHING_MESSAGE value.
* **receive_justify**: If static::REQUIRE_JUSTIFICATION is enabled, the receive_justify variable is set to "enabled" allowing the Javascript in the HTML page to display a form with a justification string  as input. The justification string is required (if enabled), requires a minimum of 5 characters, maximum of 100 characters, and the following (alphanumeric) submission pattern: ```[A-Za-z0-9\\s]+```.

This dynamic value insertion is made possible by the following iRule command to get the iFile contents:
```
HTTP::respond 200 content [subst -nocommands -nobackslashes [ifile get user-coaching-html]]
```

The user-coaching page also includes a set of gradient backgrounds that can be selected in the <div class="page-wrapper"...> block directly below the <body> tag.
* bg-gra-gold-brown
* bg-gra-light-dark-blue
* bg-gra-red-black
* bg-gra-red-blue
* bg-gra-orange-purple
* bg-gra-light-dark-red
* bg-gra-light-dark-grey

Refer to https://uigradients.com/ for additional gradient options.

-----
### Customizing the User-Blocking HTML page

The default blocking HTML page contains one variable that is defined and inserted by the user-coaching iRule:
* **receive_msg**: Contains the message provided by the static::BLOCKING_MESSAGE value.

The user-blocking page also includes a set of gradient backgrounds that can be selected in the <div class="page-wrapper"...> block directly below the <body> tag.

