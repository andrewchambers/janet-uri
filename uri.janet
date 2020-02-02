# RFC 3986                   URI Generic Syntax

#    URI           = scheme ":" hier-part [ "?" query ] [ "#" fragment ]

#    hier-part     = "//" authority path-abempty
#                  / path-absolute
#                  / path-rootless
#                  / path-empty

#    URI-reference = URI / relative-ref

#    absolute-URI  = scheme ":" hier-part [ "?" query ]

#    relative-ref  = relative-part [ "?" query ] [ "#" fragment ]

#    relative-part = "//" authority path-abempty
#                  / path-absolute
#                  / path-noscheme
#                  / path-empty

#    scheme        = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )

#    authority     = [ userinfo "@" ] host [ ":" port ]
#    userinfo      = *( unreserved / pct-encoded / sub-delims / ":" )
#    host          = IP-literal / IPv4address / reg-name
#    port          = *DIGIT

#    IP-literal    = "[" ( IPv6address / IPvFuture  ) "]"

#    IPvFuture     = "v" 1*HEXDIG "." 1*( unreserved / sub-delims / ":" )

#    IPv6address   =                            6( h16 ":" ) ls32
#                  /                       "::" 5( h16 ":" ) ls32
#                  / [               h16 ] "::" 4( h16 ":" ) ls32
#                  / [ *1( h16 ":" ) h16 ] "::" 3( h16 ":" ) ls32
#                  / [ *2( h16 ":" ) h16 ] "::" 2( h16 ":" ) ls32
#                  / [ *3( h16 ":" ) h16 ] "::"    h16 ":"   ls32
#                  / [ *4( h16 ":" ) h16 ] "::"              ls32
#                  / [ *5( h16 ":" ) h16 ] "::"              h16
#                  / [ *6( h16 ":" ) h16 ] "::"

#    h16           = 1*4HEXDIG
#    ls32          = ( h16 ":" h16 ) / IPv4address
#    IPv4address   = dec-octet "." dec-octet "." dec-octet "." dec-octet
#    dec-octet     = DIGIT                 ; 0-9
#                  / %x31-39 DIGIT         ; 10-99
#                  / "1" 2DIGIT            ; 100-199
#                  / "2" %x30-34 DIGIT     ; 200-249
#                  / "25" %x30-35          ; 250-255

#    reg-name      = *( unreserved / pct-encoded / sub-delims )

#    path          = path-abempty    ; begins with "/" or is empty
#                  / path-absolute   ; begins with "/" but not "//"
#                  / path-noscheme   ; begins with a non-colon segment
#                  / path-rootless   ; begins with a segment
#                  / path-empty      ; zero characters

#    path-abempty  = *( "/" segment )
#    path-absolute = "/" [ segment-nz *( "/" segment ) ]
#    path-noscheme = segment-nz-nc *( "/" segment )
#    path-rootless = segment-nz *( "/" segment )
#    path-empty    = 0<pchar>

#    segment       = *pchar
#    segment-nz    = 1*pchar
#    segment-nz-nc = 1*( unreserved / pct-encoded / sub-delims / "@" )
#                  ; non-zero-length segment without any colon ":"

#    pchar         = unreserved / pct-encoded / sub-delims / ":" / "@"

#    query         = *( pchar / "/" / "?" )

#    fragment      = *( pchar / "/" / "?" )

#    pct-encoded   = "%" HEXDIG HEXDIG

#    unreserved    = ALPHA / DIGIT / "-" / "." / "_" / "~"
#    reserved      = gen-delims / sub-delims
#    gen-delims    = ":" / "/" / "?" / "#" / "[" / "]" / "@"
#    sub-delims    = "!" / "$" / "&" / "'" / "(" / ")"
#                  / "*" / "+" / "," / ";" / "="
(import _uri :prefix "" :export true)

(def- query-grammar ~{
  :main (sequence (opt :query) (not 1))
  :query (sequence :pair (any (sequence "&" :pair)))
  :pair (sequence (cmt (capture :key) ,unescape) "=" (cmt (capture :value) ,unescape))
  :key (any (sequence (not "=") 1))
  :value (any (sequence (not "&") 1))
})

(defn parse-query
  [q]
  "Parse a uri encoded query string returning a table or nil."
  (when-let [matches (peg/match (comptime (peg/compile query-grammar)) q)]
    (table ;matches)))

(defn- named-capture
  [rule &opt name]
  (default name rule)
  ~(sequence (constant ,name) (capture ,rule)))

(defn- exactly # XXX Remove if https://github.com/janet-lang/janet/issues/252 is accepted.
  [count rule]
  ~(between ,count ,count ,rule))

(def- uri-grammar ~{
  :main (sequence :URI-reference (not 1))
  :URI-reference (choice :URI :relative-ref)
  :URI (sequence ,(named-capture :scheme) ":" :hier-part (opt (sequence "?" ,(named-capture :query :raw-query)))  (opt (sequence "#" ,(named-capture :fragment :raw-fragment))))
  :relative-ref (sequence :relative-part (opt (sequence "?" ,(named-capture :query :raw-query)))  (opt (sequence "#" ,(named-capture :fragment :raw-fragment))))
  :hier-part (choice (sequence "//" :authority :path-abempty) :path-absolute :path-rootless :path-empty)
  :relative-part (choice (sequence "//" :authority :path-abempty) :path-absolute :path-noscheme :path-empty)
  :scheme (sequence :a (any (choice :a :d "+" "-" ".")))
  :authority (sequence (opt (sequence ,(named-capture :userinfo) "@")) ,(named-capture :host) (opt (sequence ":" ,(named-capture :port))))
  :userinfo (any (choice :unreserved :pct-encoded :sub-delims ":"))
  :host (choice :IP-literal :IPv4address :reg-name) # TODO ip literals
  :port (any :d)
  :IP-literal (sequence "[" (choice :IPv6address :IPvFuture  ) "]" )
  :IPv4address (sequence :dec-octet "." :dec-octet "." :dec-octet "." :dec-octet)
  :IPvFuture (sequence "v" (at-least 1 :hexdig) "." (at-least 1 (sequence :unreserved :sub-delims ":" )))
  :IPv6address (choice
    (sequence ,(exactly 6 ~(sequence :h16 ":")) :ls32)
    (sequence "::" ,(exactly 5 ~(sequence :h16 ":")) :ls32)
    (sequence (opt :h16) "::" ,(exactly 4 ~(sequence :h16 ":")) :ls32)
    (sequence (opt (sequence (at-most 1 (sequence :h16 ":")) :h16)) "::" ,(exactly 3 ~(sequence :h16 ":")) :ls32)
    (sequence (opt (sequence (at-most 2 (sequence :h16 ":")) :h16)) "::" ,(exactly 2 ~(sequence :h16 ":")) :ls32)
    (sequence (opt (sequence (at-most 3 (sequence :h16 ":")) :h16)) "::" (sequence :h16 ":") :ls32)
    (sequence (opt (sequence (at-most 4 (sequence :h16 ":")) :h16)) "::" :ls32)
    (sequence (opt (sequence (at-most 5 (sequence :h16 ":")) :h16)) "::" :h16)
    (sequence (opt (sequence (at-most 6 (sequence :h16 ":")) :h16)) "::"))
  :h16 (between 1 4 :hexdig)
  :ls32 (choice (sequence :h16 ":" :h16) :IPv4address)
  :dec-octet (choice (sequence "25" (range "05")) (sequence "2" (range "04") :d) (sequence "1" :d :d) (sequence (range "19") :d) :d)
  :reg-name (any (choice :unreserved :pct-encoded :sub-delims))
  :path (choice :path-abempty :path-absolute :path-noscheme :path-rootless :path-empty)
  :path-abempty  ,(named-capture ~(any (sequence "/" :segment)) :raw-path)
  :path-absolute ,(named-capture ~(sequence "/" (opt (sequence :segment-nz (any (sequence "/" :segment))))) :raw-path)
  :path-noscheme ,(named-capture ~(sequence :segment-nz-nc (any (sequence "/" :segment))) :raw-path)
  :path-rootless ,(named-capture ~(sequence :segment-nz (any (sequence "/" :segment))) :raw-path)
  :path-empty (not :pchar)
  :segment (any :pchar)
  :segment-nz (some :pchar)
  :segment-nz-nc (some (choice :unreserved :pct-encoded :sub-delims "@" ))
  :pchar (choice :unreserved :pct-encoded :sub-delims ":" "@")
  :query (any (choice :pchar (set "/?")))
  :fragment (any (choice :pchar (set "/?")))
  :pct-encoded (sequence "%" :hexdig :hexdig)
  :unreserved (choice :a :d  (set "-._~"))
  :gen-delims (set ":/?#[]@")
  :sub-delims (set "!$&'()*+,;=")
  :hexdig (choice :d (range "AF") (range "af"))
})

(defn parse-raw
  "Parse a uri-reference following rfc3986.

   Returns a table with elements that may include:

   :scheme :host :port :userinfo
   :raw-path :raw-query :raw-fragment

   The returned elements are not normalized or decoded.
   The returned elements are always strings.
   returns nil if the input is not a valid uri.
  "
  [u &keys {:parse-query parse-query :unescape do-unescape}]
  (when-let [matches (peg/match (comptime (peg/compile uri-grammar)) u)]
    (table ;matches)))

(defn parse
  "Parse a uri-reference following rfc3986.

   Returns a table with elements that may include:

   :scheme :host :port :userinfo :raw-path :path
   :raw-query :query :raw-fragment :fragment

   The path, and fragment are uri unescaped.
   The query is parsed into a table.
   The rest of the returned values are strings.
   returns nil if the input is not a valid uri.
  "
  [u]
  (when-let [u (parse-raw u)]
    (when-let [p (u :raw-path)]
      (put u :path (unescape p)))
    (when-let [f (u :raw-fragment)]
      (put u :fragment (unescape f)))
    (when-let [q (u :raw-query)]
      (put u :query (parse-query q)))
    u))

