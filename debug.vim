let pwd = expand('<script>:p:h')

execute $'set runtimepath+={pwd}'
execute $'helptags {pwd}/doc'

" .env
" NAME=*****
" KEY=*****
" SECRET=*****
let s:ENV = {}
for env_value in readfile($'{pwd}/.env')
  let [k, v] = split(env_value, '=')
  let s:ENV[k] = v
endfor

call textra#setup(#{
      \ name: s:ENV.NAME,
      \ key: s:ENV.KEY,
      \ secret: s:ENV.SECRET,
      \ })

let s:display_type = 2
function s:display_result(result) abort
  if s:display_type == 1
    echomsg a:result
  elseif s:display_type == 2
    call popup_atcursor(a:result, {})
  elseif s:display_type == 3
    let bufnr = bufadd('textra_result')
    call bufload(bufnr)
    call appendbufline(bufnr, '$', ['', a:result])
    let winnr = bufwinnr(bufnr)
    if winnr < 0
      new
      execute 'buffer' bufnr
      setlocal buftype=nofile bufhidden=hide noswapfile
      execute winnr('#') 'wincmd w'
    endif
  endif
endfunction

function s:cmd_translate(from_lang, to_lang, reg = '') abort
  echo '[textra] translate ...'
  let src = getreg(a:reg)->substitute('[[:space:]]\+', ' ', 'g')
  let dst = textra#translate(src, a:from_lang, a:to_lang)
  redraw!
  call s:display_result(dst)
endfunction

command! -nargs=+ Textra call s:cmd_translate(<f-args>)
