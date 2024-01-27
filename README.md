# textra.vim

**textra** は「みんなの自動翻訳＠TexTra」を使用した翻訳プラグインです。
https://mt-auto-minhon-mlt.ucri.jgn-x.jp/

Vim および Neovim で動作します。

https://github.com/kawarimidoll/textra.vim/assets/8146876/161be722-5655-4bdb-9b20-5c0b32326c6a

## REQUIREMENTS

TexTraのユーザー登録が必要です。

また、 HTTP リクエストを行うため、 `curl` が必要です。

## EXAMPLE

設定の例を示します。

```vim
call textra#setup({
    \ 'name': 'your_name',
    \ 'key': 'your_key',
    \ 'secret': 'your_secret'
    \ })

function s:display_result(result) abort
  echomsg a:result
endfunction

function s:cmd_translate(from_lang, to_lang, reg = '') abort
  echo '[textra] translate ...'
  let src = getreg(a:reg)->substitute('[[:space:]]\+', ' ', 'g')
  let dst = textra#translate(src, a:from_lang, a:to_lang)
  call s:display_result(dst)
endfunction

command! -nargs=+ Textra call s:cmd_translate(<f-args>)
```
