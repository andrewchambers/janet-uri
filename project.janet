(declare-project
  :name "uri"
  :description "A uri parser following rfc3986 implemented in Janet."
  :author "Andrew Chambers"
  :license "MIT"
  :url "https://github.com/andrewchambers/janet-uri"
  :repo "git+https://github.com/andrewchambers/janet-uri.git")

(declare-source
  :source ["uri.janet"])

(declare-native
  :name "_uri"
  :source ["uri.c"])
