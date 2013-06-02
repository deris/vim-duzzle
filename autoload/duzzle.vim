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
  if s:is_first_start()
    call s:show_start_message()
  else
    call s:go_room()
  endif
endfunction
" }}}

function! duzzle#check_cursor() " {{{
  if !s:puzzle_started
    return 0
  endif
  if line('.') > len(s:current_puzzle['room'])
    call s:died_and_go_room_with_message("You can't move this area. So you died %s times, and your new clone has been created.")
    return 1
  endif
  if s:char_under_cursor() ==# 'g'
    call s:go_next_room()
    return 1
  elseif s:char_under_cursor() ==# '-' ||
    \    s:char_under_cursor() ==# '|'
    call s:died_and_go_room_with_message('You died %s times, and your new clone has been created.')
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
let s:died_times = 0
let s:default_enable_keys = 'hjkl'
let s:default_experiment_name = '_'
let s:default_puzzle_message = [
  \ '[ルール]',
  \ '出口(g)まで移動してください。',
  \ '壁(|)or(-)に当たると死にます',
  \ '',
  \ ]
let s:default_puzzle_option_message = [
  \ '[この部屋で使えるコマンド]',
  \ 'h:左に進む',
  \ 'j:下に進む',
  \ 'k:上に進む',
  \ 'l:右に進む',
  \ ]
let s:default_disable_key_count_message = [
  \ '[カウント指定無効部屋]',
  \ 'この部屋はコマンド実行前に数値を入力することで',
  \ 'その回数コマンドを実行するカウント指定を利用することができません',
  \ ]

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
let s:puzzle_started = 0
let s:start_message = [
  \ "おめでとうございます",
  \ "あなたは実験の被験者に選ばれました",
  \ "",
  \ "さぁ、ゲームを始めましょう",
  \ "あなたは壁で囲まれた部屋の中に閉じ込められました",
  \ "あなたに課されたことはただひとつ",
  \ "部屋ごとに存在するゴールまでたどり着くことです",
  \ "",
  \ "ルールは部屋それぞれですが、以下のルールは基本的にすべての部屋共通です",
  \ "* 部屋にはスタート地点がある",
  \ "* 部屋には出口がある",
  \ "* 部屋の壁にさわると死にスタート地点に戻る",
  \ "* スタート地点に戻るコマンド(通常は's')がある",
  \ "",
  \ "まぁやっていくうちにわかっていくでしょう",
  \ "あなたが間違った選択をすると死ぬこともあるのでご注意を",
  \ "なお、どうしても現実に戻りたい場合、'Q'を押下することで",
  \ "強制的に現実に戻ることができます",
  \ "",
  \ "それでは実験を開始してください",
  \ "",
  \ "[開始する] [逃げる]",
  \ ]


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

function! s:is_first_start() " {{{
  return s:puzzle_started == 0
endfunction
" }}}

function! s:show_start_message() " {{{
  call s:disable_allkey()
  call s:enable_keys(s:default_enable_keys)

  " TODO: dont set puzzle options if start
  call s:init_options()
  nnoremap <buffer> <CR>  :<C-u>call <SID>go_room_if_press_start()<CR>

  call s:draw_lines(s:start_message)
endfunction
" }}}

function! s:go_room_if_press_start() " {{{
  let line = getline('.')

  if line !~ '\[開始する\]'
    return
  endif

  let s:puzzle_started = 1
  " TODO: only [開始する] under cursor
  call s:go_room()
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

function! s:died_and_go_room_with_message(message) " {{{
  let s:died_times += 1
  call s:go_room()
  call s:EchoWarning(printf(a:message, s:died_times))
endfunction
" }}}

function! s:is_last_puzzle() " {{{
  return s:current_puzzle_number + 1 >= len(s:current_experiment)
endfunction
" }}}

function! s:go_room() " {{{
  call s:draw_room()
  call s:move_start_position()
  call s:init_keys()
  call s:init_options()
endfunction
" }}}

function! s:init_keys() " {{{
  call s:disable_allkey()
  call s:enable_puzzle_key()
  call s:enable_keys_with_limit()
  call s:disable_puzzle_key_count()
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

function! s:disable_puzzle_key_count() " {{{
  for key in split('123456789', '\zs')
    if get(s:current_puzzle, 'disable_key_count', 0)
      call s:disable_key(key, 'n')
    else
      call s:enable_key(key, 'n')
    endif
  endfor
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

function! s:draw_room() " {{{
  let s:save_modifiable = &l:modifiable
  setlocal modifiable
  try
    call s:clear_buffer()
    call setline(1, s:current_puzzle['room'])
    call setline(line('$')+1, '')
    call setline(line('$')+1, s:default_puzzle_message)
    if has_key(s:current_puzzle, 'enable_keys')
      call s:print_enable_keys(s:current_puzzle['enable_keys'])
    else
      call s:print_enable_keys(s:default_enable_keys)
    endif

    call setline(line('$')+1, '')
    if get(s:current_puzzle,  'disable_key_count', 0)
      call setline(line('$')+1, s:default_disable_key_count_message)
    endif
  finally
    let &l:modifiable = s:save_modifiable
  endtry
endfunction
" }}}

let s:enable_key_message = {
  \ 'n' : {
  \   'h' : 'h:左に進む',
  \   'j' : 'j:下に進む',
  \   'k' : 'k:上に進む',
  \   'l' : 'l:右に進む',
  \   'w' : 'w:1単語前方に進む',
  \   'b' : 'b:1単語後方に進む',
  \   'e' : 'e:1単語前方の単語の終わりに進む',
  \   'ge': 'ge:1単語後方の単語の終わりに進む',
  \   'f' : 'f:続いて文字を入力することで左に向かって入力文字まで移動する',
  \   'F' : 'F:続いて文字を入力することで右に向かって入力文字まで移動する',
  \   't' : 't:続いて文字を入力することで左に向かって入力文字の手前まで移動する',
  \   'T' : 'T:続いて文字を入力することで右に向かって入力文字の手前まで移動する',
  \   ';' : ';:右に向かって一個前にf,F,t,Tの後に入力した文字まで移動する',
  \   ',' : ',:左に向かって一個前にf,F,t,Tの後に入力した文字まで移動する',
  \   '^' : '^:その行の最初の非空白文字に移動する',
  \   '0' : '0:その行の最初に移動する',
  \   '$' : '$:その行の最後に移動する',
  \   'g_': 'g_:その行の最後の非空白文字に移動する',
  \   '{' : '{:上方向に空行が出てくる位置まで移動(段落後方に)',
  \   '}' : '}:下方向に空行が出てくる位置まで移動(段落前方に)',
  \   '/' : '/:前方検索する',
  \   '?' : '?:後方検索する',
  \   '*' : '*:カーソル位置の単語を前方検索する',
  \   '#' : '#:カーソル位置の単語を後方検索する',
  \   'n' : 'n:最後の検索を繰り返す',
  \   'N' : 'N:最後の逆方向に検索を繰り返す',
  \   '%' : '%:対応する括弧に移動する',
  \   'd' : 'd:続けて入力したコマンドの位置まで削除する',
  \ },
  \ 'o' : {
  \   'f' : 'f:続いて文字を入力することで左に向かって入力文字まで移動する',
  \   't' : 't:続いて文字を入力することで左に向かって入力文字の手前まで移動する',
  \ },
  \ }

function! s:print_enable_keys(keys)
  let keydict = s:build_keydict(a:keys)

  call setline(line('$')+1, '[この部屋で使えるコマンド]')
  for key in get(keydict, 'n', [])
    call setline(line('$')+1, s:enable_key_message['n'][key])
  endfor

  if has_key(keydict, 'o')
    call setline(line('$')+1, '')
    call setline(line('$')+1, '[この部屋でdの後に許されているコマンド]')
    for key in keydict['o']
      call setline(line('$')+1, s:enable_key_message['o'][key])
    endfor
  endif
endfunction


function! s:draw_lines(lines) " {{{
  let s:save_modifiable = &l:modifiable
  setlocal modifiable
  try
    call s:clear_buffer()
    call setline(1, a:lines)
  finally
    let &l:modifiable = s:save_modifiable
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
  let keydict = s:build_keydict(a:keys)

  for [mode, keylist] in items(keydict)
    for key in keylist
      call s:enable_key(key, mode)
    endfor
  endfor
endfunction
" }}}

function! s:build_keydict(keys) " {{{
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
" }}}

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
    call s:disable_key(escape('g'.nr2char(nrkey), '|'), 'nvo')
  endfor

  call s:disable_mouse()
  call s:map_quit_key()
endfunction
" }}}

function! s:disable_mouse() " {{{
  let mouses = [
    \ '<LeftMouse>',
    \ '<LeftDrag>',
    \ '<LeftRelease>',
    \ '<2-LeftMouse>',
    \ '<2-LeftDrag>',
    \ '<2-LeftRelease>',
    \ '<3-LeftMouse>',
    \ '<3-LeftDrag>',
    \ '<3-LeftRelease>',
    \ '<4-LeftMouse>',
    \ '<4-LeftDrag>',
    \ '<4-LeftRelease>',
    \ '<C-LeftMouse>',
    \ '<C-LeftDrag>',
    \ '<C-LeftRelease>',
    \ '<2-C-LeftMouse>',
    \ '<2-C-LeftDrag>',
    \ '<2-C-LeftRelease>',
    \ '<3-C-LeftMouse>',
    \ '<3-C-LeftDrag>',
    \ '<3-C-LeftRelease>',
    \ '<4-C-LeftMouse>',
    \ '<4-C-LeftDrag>',
    \ '<4-C-LeftRelease>',
    \ '<S-LeftMouse>',
    \ '<S-LeftDrag>',
    \ '<S-LeftRelease>',
    \ '<2-S-LeftMouse>',
    \ '<2-S-LeftDrag>',
    \ '<2-S-LeftRelease>',
    \ '<3-S-LeftMouse>',
    \ '<3-S-LeftDrag>',
    \ '<3-S-LeftRelease>',
    \ '<4-S-LeftMouse>',
    \ '<4-S-LeftDrag>',
    \ '<4-S-LeftRelease>',
    \ '<M-LeftMouse>',
    \ '<M-LeftDrag>',
    \ '<M-LeftRelease>',
    \ '<2-M-LeftMouse>',
    \ '<2-M-LeftDrag>',
    \ '<2-M-LeftRelease>',
    \ '<3-M-LeftMouse>',
    \ '<3-M-LeftDrag>',
    \ '<3-M-LeftRelease>',
    \ '<4-M-LeftMouse>',
    \ '<4-M-LeftDrag>',
    \ '<4-M-LeftRelease>',
    \ ]

  for mouse in mouses
    call s:disable_key(mouse, 'nvoi')
  endfor
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
  if type(a:modes) == type('')
    let modes = split(a:modes, '\zs')
  else
    let modes = a:modes
  endif
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
