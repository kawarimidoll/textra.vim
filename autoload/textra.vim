let s:time_now = {->strftime("%s")}
let s:token = ''
let s:expire = 0
let s:name = ''
let s:key = ''
let s:secret = ''

let s:BASE_URL = 'https://mt-auto-minhon-mlt.ucri.jgn-x.jp'
let s:AUTH_URL = $'{s:BASE_URL}/oauth2/token.php'
let s:API_URL = $'{s:BASE_URL}/api/'
let s:debug_path = ''
let s:debug_log = {log -> !empty(s:debug_path)
      \ && writefile([string(log)], s:debug_path, 'a')}

function s:echoerr(...) abort
  echohl ErrorMsg
  for str in a:000
    echomsg '[textra]' str
    call s:debug_log($'[textra] {str}')
  endfor
  echohl NONE
endfunction

if !executable('curl')
  call s:echoerr('curl is required')
  finish
endif

function textra#setup(opts) abort
  let s:name = a:opts.name
  let s:key = a:opts.key
  let s:secret = a:opts.secret
  let s:debug_path = get(a:opts, 'debug_path', '')
endfunction

function s:http_post(url, options) abort
  let cmd = ['curl', '-sS', '--request', 'POST', a:url]
  for [k, v] in items(a:options)
    call add(cmd, $'--form {k}={shellescape(v)}')
  endfor
  call s:debug_log(cmd)
  let res = cmd->join(' ')->systemlist()->join('')
  call s:debug_log(res)
  try
    return res->json_decode()
  catch
    let desc = 'not json response'
    if res =~ '<.*>'
      let desc ..= ': ' .. res->substitute('<[^>]\{-}>', ' ', 'g')->trim()
    endif
    return {'error': 'parse error', 'error_description': desc}
  endtry
endfunction

function s:auth() abort
  if empty(s:name) || empty(s:key) || empty(s:secret)
    call s:echoerr('setup is required')
    return
  endif

  let response = s:http_post(s:AUTH_URL, {
        \ 'grant_type': 'client_credentials',
        \ 'client_id': s:key,
        \ 'client_secret': s:secret,
        \ 'urlAccessToken': s:AUTH_URL,
        \ })
  call s:debug_log(response)

  if has_key(response, 'error')
    call s:echoerr(response.error)
    call s:echoerr(response.error_description)
    return
  endif

  let s:token = response.access_token
  let s:expire = s:time_now() + str2nr(response.expires_in)
endfunction

" example
" from_lang: 'en'
" to_lang: 'ja'
function textra#translate(text, from_lang, to_lang) abort
  let api_param = $'generalNT_{a:from_lang}_{a:to_lang}'
  return s:request(a:text, 'mt', api_param)
        \ ->get('result', {})
        \ ->get('text', '')
endfunction

function s:request(text, api_name, api_param = '', options = {}) abort
  if (!s:token || s:expire < s:time_now())
    call s:auth()
  endif

  let body = {
        \ 'access_token': s:token,
        \ 'key': s:key,
        \ 'api_name': a:api_name,
        \ 'name': s:name,
        \ 'type': 'json',
        \ 'text': a:text,
        \ }
  if !empty(a:api_param)
    let body['api_param'] = a:api_param
  endif
  for [k, v] in items(a:options)
    let body[k] = v
  endfor

  let response = s:http_post(s:API_URL, body)
  call s:debug_log(response)

  if has_key(response, 'error')
    call s:echoerr(response.error)
    call s:echoerr(response.error_description)
    return {}
  endif

  return response.resultset
endfunction
