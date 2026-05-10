*** Settings ***
Documentation    Reusable lists of invalid / malicious inputs for negative
...              testing. Intentionally project-agnostic: no references to
...              specific apps, domains, or usernames.


*** Variables ***
# -----------------------------------------------------------------------------
# Malformed email addresses (20+). Covers: missing local part, missing domain,
# missing TLD, illegal characters, dot-rules violations, malformed IP-literal,
# injection probes.
# -----------------------------------------------------------------------------
@{INVALID_EMAILS}
...    plainaddress
...    @missingusername.com
...    missing@domain
...    missing.tld@domain
...    spaces in@email.com
...    double@@domain.com
...    trailing.dot.@domain.com
...    .leading.dot@domain.com
...    consecutive..dots@domain.com
...    missing@.dot.com
...    user@
...    @domain.com
...    user@domain..com
...    user@-dash.com
...    user@dash-.com
...    user@domain.c
...    user@[1234:5678]
...    user@192.168.1.300
...    email@123.456.789.012
...    <script>@evil.com
...    user"name@domain.com
...    user\\@name@domain.com
...    "user@"@domain.com

# -----------------------------------------------------------------------------
# Common SQL-injection probes. Use these when testing that an input field
# sanitises / parameterises queries. A field that crashes or exposes data
# when any of these is submitted has a sanitisation bug.
# -----------------------------------------------------------------------------
@{SQL_INJECTION_STRINGS}
...    ' OR '1'='1
...    ' OR 1=1--
...    ' OR 1=1/*
...    admin'--
...    admin' #
...    '; DROP TABLE users; --
...    1' UNION SELECT NULL, NULL--
...    ') OR ('1'='1
...    " OR ""="
...    %27%20OR%201=1
...    1=1
...    '; EXEC xp_cmdshell('dir'); --

# -----------------------------------------------------------------------------
# Common reflected-XSS probes. Submit these into any field whose value is
# rendered back into the page; if the alert fires, the rendering path is
# unsafe.
# -----------------------------------------------------------------------------
@{XSS_STRINGS}
...    <script>alert('XSS')</script>
...    <img src=x onerror=alert(1)>
...    javascript:alert(1)
...    <svg onload=alert(1)>
...    "><script>alert('XSS')</script>
...    <iframe src=javascript:alert(1)></iframe>
...    <body onload=alert(1)>
...    <input onfocus=alert(1) autofocus>
...    <select onfocus=alert(1) autofocus>
...    <textarea onfocus=alert(1) autofocus>
...    <a href="javascript:alert(1)">click</a>
...    <details open ontoggle=alert(1)>
