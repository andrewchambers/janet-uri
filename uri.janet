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

(def uri-peg ~{
    :URI (sequence :scheme ":" :heir-part (opt (sequence "?" :query)) (opt (sequence "#" :fragment)))
    :hier-part (choice (sequence "//" :authority :path-abempty) :path-absolute :abs-rootless :path-empty)
    :absolute-URI  (sequence :scheme ":" :hier-part (opt (sequence  "?" :query ))
    :relative-part (choice (sequence "//" :authority :path-abempty) :path-absolute :path-noscheme :path-empty)
    :scheme (sequence :a (any (choice :a :d "+" "-" ".")))
    :authority (sequence (opt (sequence :userinfo "@")) :host (opt (sequence ":" :port)))
    :userinfo (any (choice :unreserved :pct-encoded :sub-delims ":"))
    :host (choice reg-name) # TODO ip literals
    :port (any :d)
    # XXX todo ip literals...
    :reg-name (any (sequence :unreserved :pct-encoded :sub-delims ))
    :path (choice :path-abempty :path-absolute :path-noscheme :path-rootless :path-empty)
    :path-abempty (any (sequence "/" :segment))
    :path-absolute (sequence "/" (opt (sequence :segment-nz (any (sequence "/" :segment)))))
    :path-noscheme (sequence :segment-nz-nc (any (sequence "/" :segment)))
    :path-rootless (sequence :segment-nz (any (sequence "/" :segment)))
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
    :hexdig (choice :d (range "AF"))
  })