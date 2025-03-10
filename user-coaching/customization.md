## Customization

### Customizing the User-Coaching iRule

* Category lookup (BLOCKING and COACHING): Use the following command in the BIG-IP shell to get a list of the available subscription URL categories:
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

-----
### Customizing the User-Coaching HTML page

