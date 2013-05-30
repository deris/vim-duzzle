" vim-duzzle - This is vim puzzle game produced by deris0126
" Version: 0.0.0
" Copyright (C) 2013 deris0126
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

let s:save_cpo = &cpo
set cpo&vim

" Public API {{{
function! duzzle#start(...) " {{{
  " TODO:引数チェック関数化
  if a:0 > 2
    call s:EchoError('Error:Too much Argument.')
    return
  endif

  if a:0 == 0
    " 前回の続き
  elseif a:0 == 1
    if a:1 !~ '^\d\+$'
      call s:EchoError('Error:Invalid Argument:'.a:1)
      return
    endif
    if !s:exist_puzzle(s:current_experiment_name, a:1)
      call s:EchoError('Error:No such puzzle:'.s:current_experiment_name.' '.a:2)
      return
    endif
    let s:current_puzzle_number = a:1
  elseif a:0 == 2
    if a:1 == ''
      call s:EchoError('Error:Invalid Argument:'.a:1)
      return
    endif
    if a:2 !~ '^\d\+$'
      call s:EchoError('Error:Invalid Argument:'.a:2)
      return
    endif
    if !s:exist_experiment(a:1)
      call s:EchoError('Error:No such experiment:'.a:1)
      return
    endif
    if !s:exist_puzzle(a:1, a:2)
      call s:EchoError('Error:No such puzzle:'.a:1.' '.a:2)
      return
    endif
    let s:current_experiment_name = a:1
    let s:current_puzzle_number = a:2
  endif

  let s:current_experiment = s:experiments[s:current_experiment_name]
  let s:current_puzzle = s:current_experiment[s:current_puzzle_number]

  " TODO: ウィンドウ作成コマンドの変更
  new duzzle
  call s:go_room()
endfunction
" }}}

function! duzzle#check_cursor() " {{{
  if s:char_under_cursor() ==# 'g'
    " TODO:Next Puzzle
    call s:go_next_room()
    return 1
  elseif s:char_under_cursor() ==# '-' ||
    \    s:char_under_cursor() ==# '|'
    call s:go_room()
    call s:EchoWarning('You died, and your clone has been created.')
    return 1
  endif

  return 0
endfunction
" }}}

function! duzzle#add_puzzle(experiment_name, puzzle) " {{{
  if !has_key(s:experiments, a:experiment_name)
    let s:experiments[a:experiment_name] = []
  endif
  call add(s:experiments[a:experiment_name], a:puzzle)
endfunction
" }}}

function! duzzle#init_keys() " {{{
  call s:init_keys()
endfunction
" }}}

" }}}


" Private {{{
let s:default_enable_keys = 'hjkl'
let s:default_experiment_name = '_'
let s:experiments = {}
let s:current_experiment_name = s:default_experiment_name
let s:current_experiment = []
let s:current_puzzle_number = 0
let s:current_puzzle = {}
let duzzle_dir = split(globpath(&runtimepath, 'autoload/duzzle'), '\n')
let puzzle_files = split(glob(duzzle_dir[0].'/*.vim'), '\n')
for puzzle_file in puzzle_files
  execute 'source ' . puzzle_file
endfor

let s:current_key_limit = {}


nnoremap <expr> <SID>(count)  v:count ? v:count : ''


function! s:init_options() " {{{
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nolist
  setlocal nonumber
  setlocal buftype=nofile
  setfiletype duzzle
  call s:set_puzzle_options()
endfunction
" }}}

function! s:set_puzzle_options() " {{{
  if !has_key(s:current_puzzle, 'options')
    return
  endif

  for option in s:current_puzzle['options']
    execute option
  endfor
endfunction
" }}}

function! s:go_next_room() " {{{
  if s:is_last_puzzle()
    echo "I'm so sad. This is the last room. See you soon."
    return
  endif

  let s:current_puzzle_number += 1
  let s:current_puzzle = s:current_experiment[s:current_puzzle_number]
  call s:go_room()
endfunction
" }}}

function! s:is_last_puzzle() " {{{
  return s:current_puzzle_number + 1 >= len(s:current_experiment)
endfunction
" }}}

function! s:go_room() " {{{
  call s:draw_room(s:current_puzzle['room'])
  call s:move_start_position()
  call s:init_keys()
  call s:init_options()
endfunction
" }}}

function! s:init_keys() " {{{
  call s:disable_allkey()
  call s:enable_puzzle_key()
  call s:enable_keys_with_limit()
endfunction
" }}}

function! s:enable_puzzle_key() " {{{
  if has_key(s:current_puzzle, 'enable_keys')
    call s:enable_keys(s:current_puzzle['enable_keys'])
  else
    call s:enable_keys(s:default_enable_keys)
  endif
endfunction
" }}}

function! s:move_start_position() " {{{
  let res = search('s', 'w')
  if res == 0
    " TODO:例外処理
    echoerr 'error: there is no start position'
    return
  endif
endfunction
" }}}

function! s:draw_room(room) " {{{
  let s:save_modifiable = &modifiable
  setlocal modifiable
  try
    call s:clear_buffer()
    for line in a:room
      put =line
    endfor
  finally
    let &modifiable = s:save_modifiable
  endtry
endfunction
" }}}

function! s:enable_keys_with_limit() " {{{
  if !has_key(s:current_puzzle, 'limit_key_use')
    return
  endif

  let s:current_key_limit = deepcopy(s:current_puzzle['limit_key_use'])

  for [mode, keydict] in items(s:current_key_limit)
    for [key, cnt] in items(keydict)
      call s:enable_key_with_limit(key, mode)
    endfor
  endfor
endfunction
" }}}

function! s:enable_key_with_limit(key, mode) " {{{
  call s:noremap_buffer(
    \ a:key,
    \ ':<C-u>call <SID>disable_key_if_limit("'.a:key.'", "'.a:mode.'")<CR>'
    \   .'<SID>(count)'.a:key,
    \ a:mode)
endfunction
" }}}

function! s:disable_key_if_limit(key, mode) " {{{
  if !has_key(s:current_key_limit, a:mode) ||
    \!has_key(s:current_key_limit[a:mode], a:key)
    call s:noremap_buffer(a:key, '<Nop>', a:mode)
    return
  endif

  let s:current_key_limit[a:mode][a:key] -= 1
  if s:current_key_limit[a:mode][a:key] <= 0
    call s:noremap_buffer(a:key, '<Nop>', a:mode)
  endif
endfunction
" }}}

function! s:exist_experiment(experiment) " {{{
  return has_key(s:experiments, a:experiment)
endfunction
" }}}

function! s:exist_puzzle(experiment, puzzle_number) " {{{
  return s:exist_experiment(a:experiment) &&
    \ a:puzzle_number < len(s:experiments[a:experiment])
endfunction
" }}}

" Tools {{{2
function! s:clear_buffer() " {{{
  %delete
endfunction
" }}}

function! s:char_under_cursor() " {{{
  return getline('.')[col('.')-1]
endfunction
" }}}

function! s:enable_keys(keys) " {{{
  "let keys = {}
  "if type(a:keys) == type('')
    "let keys = { 'n' : a:keys }
  "elseif type(a:keys) == type([])
    "let keys = { 'n' : a:keys }
  "elseif type(a:keys) == type({})
    "let keys = a:keys
  "else
    "call s:EchoError('Error:Invalid Argument:'.type(a:keys))
    "return
  "endif
  let keydict = s:build_keydict(a:keys)

  for [mode, keylist] in items(keydict)
    for key in keylist
      call s:enable_key(key, mode)
    endfor
  endfor
endfunction
" }}}

function! s:build_keydict(keys)
  if type(a:keys) == type('') ||
    \type(a:keys) == type([])
    return { 'n' : s:split2char_if_str(a:keys) }
  elseif type(a:keys) == type({})
    let keys = {}
    for key in keys(a:keys)
      call extend(keys, { key : s:split2char_if_str(a:keys[key]) })
    endfor
    return keys
  else
    call s:EchoError('Error:Invalid Argument:'.type(a:keys))
    return {}
  endif
endfunction

function! s:split2char_if_str(arg) " {{{
  if type(a:arg) == type('')
    return split(a:arg, '\zs')
  else
    return a:arg
  endif
endfunction
" }}}

function! s:enable_key(lhs, modes) " {{{
  call s:noremap_buffer(a:lhs, a:lhs, a:modes)
endfunction
" }}}

function! s:disable_allkey() " {{{
  let nrkeys = []
  call extend(nrkeys, range(33, 48))
  call extend(nrkeys, range(58, 126))
  for nrkey in nrkeys
    call s:disable_key(escape(nr2char(nrkey), '|'), 'nvo')
  endfor

  call s:map_quit_key()
endfunction
" }}}

function! s:disable_key(lhs, modes) " {{{
  call s:noremap_buffer(a:lhs, '<Nop>', a:modes)
endfunction
" }}}

function! s:map_quit_key() " {{{
  call s:noremap_buffer('Q', ':<C-u>bd!<CR>', 'n')
endfunction
" }}}

function! s:noremap_buffer(lhs, rhs, modes) " {{{
  let modes = split(a:modes, '\zs')
  for mode in modes
    execute mode.'noremap <silent><buffer> '.a:lhs.' '.a:rhs
  endfor
endfunction
" }}}

function! s:EchoWarning(message) " {{{
  redraw!
  echohl WarningMsg
  echo a:message
  echohl None
endfunction
" }}}

function! s:EchoError(message) " {{{
  redraw!
  echohl ErrorMsg
  echomsg a:message
  echohl None
endfunction
" }}}

" }}}

" }}}


let &cpo = s:save_cpo
unlet s:save_cpo

" __END__ "{{{1
" vim: foldmethod=marker
