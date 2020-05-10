# janet-uri

A uri parser following https://tools.ietf.org/html/rfc3986 implemented in janet.


# Quick examples

```
(uri/parse "https://ac@google.com:123/foo%20bar?a=b#123")
@{:host "google.com" :port "123"
  :userinfo "ac"
  :raw-fragment "123"
  :fragment "123"
  :raw-query "a=b"
  :query @{"a" "b"}
  :path "/foo bar"
  :raw-path "/foo%20bar"
  :scheme "https"}

(uri/escape "abc ")
"abc%20"

(uri/unescape "abc%20")
"abc "

(uri/parse-query "a=b%20")
@{"a" "b "}
```
