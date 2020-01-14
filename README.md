# janet-uri

A uri parser following https://tools.ietf.org/html/rfc3986 implemented in janet.


# Quick examples

```
(uri/parse "https://ac@google.com:123/foo?a=b#123")
@{:userinfo "ac" :path "/foo" :host "google.com" :fragment "123" :scheme "https" :port "123" :query "a=b"}
```