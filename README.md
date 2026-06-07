# 4-ZERO-3 · 2026 Edition

**403/401 bypass automation — updated payloads, new modules, modern User-Agents**

Original tool by [@me_dheeraj](https://github.com/Dheerajmadhukar/4-ZERO-3) · 2026 rewrite adds Cloudflare/CDN bypass, API gateway attacks, method override headers, UA rotation, rate-limit delay, and output logging.

---

## What it does

You hit a 403 or 401. The resource is there — the server is just refusing you. This script runs through every common technique to change that: header injection, protocol manipulation, path encoding tricks, HTTP method fuzzing, User-Agent rotation, WAF-specific bypasses for Cloudflare/Akamai/Fastly, and API gateway attacks.

One URL, one flag, and it fires every technique in that category. If something works, it prints the exact curl command you need to reproduce it.

> **NOTE:** If you see multiple 200s, check Content-Length first. Identical lengths across different payloads usually means a redirect or catch-all — not a real bypass.

---

## Install

```bash
git clone https://github.com/Dheerajmadhukar/4-ZERO-3.git
cd 4-ZERO-3
chmod +x 403-bypass.sh
```

No dependencies beyond `bash` and `curl`.

---

## Usage

```
403-bypass.sh -u <URL> [MODE] [OPTIONS]
```

`-u` / `--url` takes a full URL including the restricted path:

```bash
bash 403-bypass.sh -u https://target.com/admin --exploit
```

The path is parsed automatically from the URL. Pass the deepest path you're trying to reach — not just the domain root.

---

## Modes

Each mode targets a different class of bypass technique. Run them individually to stay focused, or use `--exploit` to run everything at once.

---

### `--header`
**HTTP header injection**

Tries every known IP-spoofing and routing header that WAFs and reverse proxies commonly trust. Covers `X-Forwarded-For`, `X-Real-Ip`, `X-Custom-IP-Authorization`, `CF-Connecting-IP`, `True-Client-IP`, `Fastly-Client-IP`, `X-Azure-ClientIP`, and ~40 others — each tested with multiple IP values including `127.0.0.1`, `0.0.0.0`, `::1`, `localhost`, octal/hex/decimal representations of loopback, and internal RFC1918 ranges.

Also tests URL override headers (`X-Original-URL`, `X-Rewrite-URL`), Host header spoofing, combo attacks (XFF + XFH together), and cache-poisoning style header pairs.

```bash
bash 403-bypass.sh -u https://target.com/admin --header
```

---

### `--protocol`
**Protocol and scheme manipulation**

Switches between `http://` and `https://`, injects `X-Forwarded-Scheme`, `X-Forwarded-Proto`, tries HTTP/1.0 downgrade and HTTP/2 force. Useful when the restriction lives at the load balancer layer and the origin doesn't care about scheme.

```bash
bash 403-bypass.sh -u https://target.com/admin --protocol
```

---

### `--port`
**Port header spoofing**

Injects `X-Forwarded-Port` with 15 different values: 80, 443, 4443, 8080, 8443, 8000, 8008, 8888, 9000, 9090, 9443, 3000, 5000, 7443, 10443. Some ACLs key off the forwarded port rather than the actual port.

```bash
bash 403-bypass.sh -u https://target.com/admin --port
```

---

### `--HTTPmethod`
**HTTP verb fuzzing**

Tests 19 HTTP methods including the obvious ones (GET, POST, HEAD, OPTIONS) and the obscure ones (PROPFIND, PROPPATCH, MKCOL, SEARCH, PURGE, TRACK). Also tries method override via `X-HTTP-Method-Override`, `X-Method-Override`, `X-HTTP-Method`, and `_method` headers — useful when the ACL only restricts the actual HTTP method but the app trusts these headers.

```bash
bash 403-bypass.sh -u https://target.com/admin --HTTPmethod
```

---

### `--encode`
**URL encoding and path normalization**

The largest module. Appends or substitutes path characters that parsers handle inconsistently between the WAF and the origin. Covers:

- Suffix injection (`/`, `//`, `/;`, `/.`, `#?`, `%09`, `%20`, `..;/`, `~`)
- Double encoding (`%252f`, `%252f%252f`)
- Partial encoding (`%2f`, `%2e`, `%3b` and combinations)
- Overlong UTF-8 slash (`%c0%af`, `%e0%80%af`)
- Double-slash prefix, dot-slash prefix, `%2f` prefix
- Semicolon injection into path segments
- Uppercase and mixed-case path variants
- Null byte (`%00`, `%00.html`)
- Extension confusion (`.json`, `.css`, `.html`, `.js`)
- Query string confusion (`?cb=1`, `?debug=1`, `?format=json`)

```bash
bash 403-bypass.sh -u https://target.com/admin --encode
```

---

### `--SQLi`
**mod_security / libinjection bypass**

Tries SQL-like payloads in the path that confuse WAFs relying on libinjection for detection. The original `1.e()` payloads are kept, with 10 new patterns added for 2026 WAF rulesets including time-based, UNION-based, stacked query, and double-quoted variants.

This isn't SQL injection against the app — it's WAF rule evasion. The goal is to get a request through that looks malformed enough to confuse the WAF but is actually valid.

```bash
bash 403-bypass.sh -u https://target.com/admin --SQLi
```

---

### `--useragent`
**User-Agent rotation**

Cycles through ~21 User-Agent strings: modern browsers (Chrome 131, Firefox 132, Edge, iOS 18, Android 15), crawlers (Googlebot, bingbot, YandexBot, DuckDuckBot), HTTP libraries (curl, Python requests, Go, Java 21, axios, node-fetch), and degenerate values (empty string, `null`, `.`, `-`).

Some endpoints restrict access based on UA fingerprint rather than auth. Crawlers in particular are often whitelisted to allow indexing.

```bash
bash 403-bypass.sh -u https://target.com/admin --useragent
```

---

### `--cloudflare`
**Cloudflare / CDN-specific bypass** *(new in 2026)*

Built for targets sitting behind Cloudflare, Fastly, Akamai, or AWS CloudFront. Tests:

- CF headers: `CF-Connecting-IP`, `CF-Worker`, `CF-IPCountry`, `CF-Ray` (spoofed), `CDN-Loop`
- Fastly: `Fastly-Client-IP`, `Fastly-FF`
- Akamai: `Akamai-Origin-Hop`, `X-Akamai-Debug`
- CloudFront: `CloudFront-Viewer-Country`, `X-Amz-Cf-Id`
- Content-Type variations (some WAF rules key off content type)
- `Accept-Encoding: gzip, deflate, br`
- Resolve override to test whether the origin accepts requests without CDN routing

```bash
bash 403-bypass.sh -u https://target.com/admin --cloudflare
```

---

### `--api`
**API gateway / versioning bypass** *(new in 2026)*

Targets REST APIs and API gateways specifically. Tries:

- Version prefix path substitution: `/v1/`, `/v2/`, up to `/v5/`, plus `/api/v1`, `/api/v2`, `/rest`
- Dummy auth headers with null/undefined/empty values (`X-Api-Key`, `Authorization: Bearer null`, etc.)
- GraphQL endpoint probing with a minimal `{__typename}` query
- Extension confusion (`.json`, `.xml`)
- JSONP callback injection (`?callback=bypass`)
- Accept header negotiation
- Internal trust headers: `X-Internal-Request: true`, `X-Admin: true`, `X-Service-ID: internal`, `X-Debug: 1`, `X-Auth-Token: bypass`

```bash
bash 403-bypass.sh -u https://target.com/admin --api
```

---

### `--exploit`
**Run everything**

Fires all nine modules back to back. Long. Use this when you want full coverage and aren't worried about noise or rate limits.

```bash
bash 403-bypass.sh -u https://target.com/admin --exploit
```

---

## Options

### `--delay <seconds>`
Sleep N seconds between requests. Use this when the target rate-limits or when you want to stay quieter.

```bash
bash 403-bypass.sh -u https://target.com/admin --exploit --delay 1
```

---

### `--output <file>`
Write results to a file. Hits (2xx) are always logged. Non-hits are logged too unless you combine this with `--hits-only`.

```bash
bash 403-bypass.sh -u https://target.com/admin --exploit --output results.txt
```

---

### `--hits-only`
Suppress 3xx/4xx/5xx output — only print 2xx responses to the terminal. Useful when running `--exploit` against a noisy target and you want to see wins without scrolling.

```bash
bash 403-bypass.sh -u https://target.com/admin --exploit --hits-only
```

---

## Output colours

| Colour | Meaning |
|--------|---------|
| 🟢 Green | 2xx — potential bypass |
| 🟡 Yellow | 3xx — redirect |
| 🔴 Red | 4xx — still blocked |
| 🔵 Cyan | 5xx — server error |

When a 2xx is found, the script prints the exact curl command to reproduce it:

```
╭──────────────────────────────────────────────────────╮
 ╰─> PAYLOAD : curl -ks -H 'X-Forwarded-For: 127.0.0.1' -X GET 'https://target.com/admin'
╰──────────────────────────────────────────────────────╯
```

A summary at the end shows total checks run and total 2xx hits.

---

## Examples

```bash
# Header bypass only
bash 403-bypass.sh -u https://target.com/secret --header

# Cloudflare target, hits only, log to file
bash 403-bypass.sh -u https://target.com/secret --cloudflare --hits-only --output cf-results.txt

# Full scan with 1 second delay between requests
bash 403-bypass.sh -u https://target.com/secret --exploit --delay 1 --output full-scan.txt

# API endpoint
bash 403-bypass.sh -u https://api.target.com/v1/internal/users --api

# Path encoding tricks
bash 403-bypass.sh -u https://target.com/admin/dashboard --encode
```

---

## False positives

A 200 response means nothing on its own. Before reporting or treating something as a bypass:

1. Check the Content-Length. If every 2xx hit returns the same byte count, the server is probably returning a generic error page with a 200 status — not the actual restricted content.
2. Read the response body. A 200 with "Access Denied" in the HTML is not a bypass.
3. Compare content to a known-good response from a path you can access legitimately.

The script flags potential bypasses. Confirming them is on you.
