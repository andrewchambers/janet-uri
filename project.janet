(declare-project
  :name "uri"
  :author "Andrew Chambers"
  :license "MIT"
  :url "https://github.com/andrewchambers/janet-uri"
  :repo "git+https://github.com/andrewchambers/janet-uri.git")

(declare-source
  :source ["uri.janet"])

(declare-native
  :name "_uri"
  :source ["uri.c"])
