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

(defn- named-capture
  [rule &opt name]
  (default name rule)
  ~(sequence (constant ,name) (capture ,rule)))

(def- grammar ~{
  :main (sequence :URI-reference (not 1))
  :URI-reference (choice :URI :relative-ref)
  :URI (sequence ,(named-capture :scheme) ":" :hier-part (opt (sequence "?" ,(named-capture :query)))  (opt (sequence "#" ,(named-capture :fragment))))
  :relative-ref (sequence :relative-part (opt (sequence "?" ,(named-capture :query)))  (opt (sequence "#" ,(named-capture :fragment))))
  :hier-part (choice (sequence "//" :authority :path-abempty) :path-absolute :path-rootless :path-empty)
  :relative-part (choice (sequence "//" :authority :path-abempty) :path-absolute :path-noscheme :path-empty)
  :scheme (sequence :a (any (choice :a :d "+" "-" ".")))
  :authority (sequence (opt (sequence ,(named-capture :userinfo) "@")) ,(named-capture :host) (opt (sequence ":" ,(named-capture :port))))
  :userinfo (any (choice :unreserved :pct-encoded :sub-delims ":"))
  :host (choice :IPv4address :reg-name) # TODO ip literals
  :port (any :d)
  # XXX todo ip6 literals...
  :IPv4address (sequence :dec-octet "." :dec-octet "." :dec-octet "." :dec-octet)
  :dec-octet (choice (sequence "25" (range "05")) (sequence "2" (range "04") :d) (sequence "1" :d :d) (sequence (range "19") :d) :d)
  :reg-name (any (choice :unreserved :pct-encoded :sub-delims))
  :path (choice :path-abempty :path-absolute :path-noscheme :path-rootless :path-empty)
  :path-abempty  ,(named-capture ~(any (sequence "/" :segment)) :path)
  :path-absolute ,(named-capture ~(sequence "/" (opt (sequence :segment-nz (any (sequence "/" :segment))))) :path)
  :path-noscheme ,(named-capture ~(sequence :segment-nz-nc (any (sequence "/" :segment))) :path)
  :path-rootless ,(named-capture ~(sequence :segment-nz (any (sequence "/" :segment))) :path)
  :path-empty (not :pchar)
  :segment (any :pchar)
  :segment-nz (some :pchar)
  :segment-nz-nc (some (choice :unreserved :pct-encoded :sub-delims "@" ))
  :pchar (choice :unreserved :pct-encoded :sub-delims ":" "@")
  :query (any (choice :pchar "/" "?"))
  :fragment (any (choice :pchar "/" "?"))
  :pct-encoded (sequence "%" :hexdig :hexdig)
  :unreserved (choice :a :d  "-" "." "_" "~")
  :reserved (choice :gen-delims :sub-delims)
  :gen-delims (choice ":" "/" "?" "#" "[" "]" "@")
  :sub-delims (choice "!" "$" "&" "'" "(" ")" "*" "+" "," ";" "=")
  :hexdig (choice :d (range "AF") (range "af"))
})

(defn parse
  "Parse a uri-reference following rfc3986.
   Possible returned table elements include:

   :scheme :host :port :userinfo :path :query :fragment

   The returned elements are not normalized or decoded.
  "
  [u]
  (when-let [matches (peg/match (comptime (peg/compile grammar)) u)]
    (table ;matches)))