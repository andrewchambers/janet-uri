(import ../uri :as uri)

(def tests [

  ["foo://127.0.0.1"
  @{:scheme "foo" :host "127.0.0.1" :path ""}]

  ["foo://example.com:8042/over/there?name=ferret#nose"
  @{:path "/over/there" :host "example.com" :fragment "nose" :scheme "foo" :port "8042" :query "name=ferret"}]
  
  ["/over/there?name=ferret#nose"
  @{:path "/over/there" :fragment "nose" :query "name=ferret"}]

  ["//"
  @{:path "" :host ""}]

  ["/"
  @{:path "/"}]
  
  [""
  @{}]
])

(each tc tests
  (def r (uri/parse (tc 0)))
  (unless (deep= r (tc 1))
    (eprintf "%p\n!=\n%p" r (tc 1))
    (error "fail")))