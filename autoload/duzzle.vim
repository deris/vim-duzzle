" vim-duzzle - This is vim puzzle game produced by deris0126
" Version: 0.1.0
" Copyright (C) 2013-2016 deris0126
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

let s:V = vital#of('vim_duzzle')
let s:P = s:V.import('Prelude')
let s:O = s:V.import('OptionParser')
let s:parser = s:O.new()
let s:LM = s:V.import('Locale.Message')
let s:VM = s:V.import('Vim.Message')
let s:message_path = 'message/%s.txt'
let s:message = s:LM.new(s:message_path)
let s:start_message = s:message.get('start_message')
if s:P.is_string(s:start_message) &&
  \s:start_message ==# 'start_message'
  call s:message.load(get(g:, 'duzzle_language', 'en'))
endif

function! s:complete_experiment(optlead, cmdline, cursorpos)
  return filter(duzzle#experiment_names(),
    \ 'a:optlead == "" || v:val =~# a:optlead')
endfunction

function! duzzle#complete(arglead, cmdline, cursorpos)
  return s:parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

call s:parser.on('--experiment=VALUE', 'specifiy experiment name, has short option',
  \ {
  \   'short' : '-e',
  \   'completion' : function('s:complete_experiment'),
  \ })
call s:parser.on('--num-room=VALUE', 'specifiy number of room, has short option',
  \ {
  \   'short' : '-n',
  \   'pattern' : '^[1-9]\d*$',
  \ })


" Public API {{{
function! duzzle#start(args) " {{{
  let args = s:parse_args(a:args)

  if empty(args)
    return
  endif

  let s:current_experiment = s:experiments[args['experiment']]
  let s:current_puzzle_number = args['num-room'] - 1
  let s:current_puzzle = s:current_experiment[s:current_puzzle_number]

  " TODO: customize to change window create command
  tabnew [duzzle]
  if !s:puzzle_started
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
    call s:died_and_go_room_with_message(s:message.get('died_message_when_out_of_area'))
    return 1
  endif
  if s:is_goal_under_cursor()
    call s:go_next_room()
    return 1
  elseif s:is_wall_under_cursor()
    call s:died_and_go_room_with_message(s:message.get('died_message_when_touch_the_wall'))
    return 1
  endif

  return 0
endfunction
" }}}

function! duzzle#add_puzzle(experiment_name, puzzle) " {{{
  let s:experiments[a:experiment_name] = get(s:experiments, a:experiment_name, [])
  call add(s:experiments[a:experiment_name], a:puzzle)
endfunction
" }}}

function! duzzle#puzzle_list(experiment_name) " {{{
  return deepcopy(get(s:experiments, a:experiment_name, []))
endfunction
" }}}

function! duzzle#experiment_names() " {{{
  return keys(s:experiments)
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

let s:experiments = {}
let s:current_experiment_name = s:default_experiment_name
let s:current_experiment = []
let s:current_puzzle_number = 0
let s:current_puzzle = {}
let s:duzzle_dir = split(globpath(&runtimepath, 'autoload/duzzle'), '\n')
let s:puzzle_files = split(glob(s:duzzle_dir[0].'/*.vim'), '\n')
for s:puzzle_file in s:puzzle_files
  execute 'source ' . s:puzzle_file
endfor
unlet s:puzzle_file
unlet s:puzzle_files
unlet s:duzzle_dir

let s:current_key_limit = {}
let s:puzzle_started = 0

function! s:parse_args(args) " {{{
  try
    let args = s:parser.parse(a:args)
  catch /vital: OptionParser: parameter doesn't match pattern: num-room/
    let value = match(v:exception, 'match pattern: num-room \zs.*')
    call s:EchoError("Error:room number '%s' doesn't exists.", value)
    call s:EchoError(s:parser.help())
    return {}
  catch
    call s:EchoError(v:exception)
    call s:EchoError(s:parser.help())
    return {}
  endtry

  let unknown_args = get(args, '__unknown_args__', [])

  if len(unknown_args) > 2
    call s:EchoError('Error:unnamed parameter must be less than or equal to 2')
    return {}
  endif

  if len(unknown_args) == 1
    let args['num-room'] = get(args, 'num-room', unknown_args[0])
  elseif len(unknown_args) == 2
    let args['experiment'] = get(args, 'experiment', unknown_args[0])
    let args['num-room']   = get(args, 'num-room', unknown_args[1])
  endif
  if !has_key(args, 'experiment')
    let args['experiment'] = g:duzzle_default_experiment_name
  endif
  if !has_key(args, 'num-room')
    let args['num-room'] = g:duzzle_default_room_number
  endif

  if !s:exist_experiment(args['experiment'])
    call s:EchoError('Error:No such experiment:experiment=%s', args['experiment'])
    return {}
  endif
  if args['num-room'] !~ '^[1-9]\d*$'
    call s:EchoError('Error:room number must be positive integer:num-room=%s', args['num-room'])
    return {}
  endif

  if !s:exist_puzzle(args['experiment'], args['num-room'])
    call s:EchoError('Error:No such puzzle:experiment=%s, num-room=%s', args['experiment'], args['num-room'])
    return {}
  endif

  return args
endfunction
" }}}

function! s:init_puzzle() " {{{
  call s:init_options()
  setfiletype duzzle
  let @/ = ''
  call s:set_puzzle_options()
endfunction
" }}}

function! s:init_options() " {{{
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nolist
  setlocal nonumber
  setlocal buftype=nofile
  setlocal matchpairs=(:),{:},[:]
  setlocal colorcolumn=
  setlocal nocursorcolumn
  setlocal nocursorline
  setlocal nospell
  nohlsearch
endfunction
" }}}

function! s:set_puzzle_options() " {{{
  for option in get(s:current_puzzle, 'options', [])
    execute option
  endfor
endfunction
" }}}

function! s:show_start_message() " {{{
  call s:disable_allkey()
  call s:enable_keys(s:default_enable_keys)

  call s:init_options()
  nnoremap <silent><buffer> <CR>  :<C-u>call <SID>go_room_if_press_start()<CR>

  call s:draw_lines(s:message.get('start_message'))
endfunction
" }}}

function! s:go_room_if_press_start() " {{{
  if line('.') != line('$')
    return
  endif

  let s:puzzle_started = 1
  call s:go_room()
endfunction
" }}}

function! s:go_next_room() " {{{
  if s:is_last_puzzle()
    call s:go_ending()
    return
  endif

  let s:current_puzzle_number += 1
  let s:current_puzzle = s:current_experiment[s:current_puzzle_number]
  call s:go_room()
endfunction
" }}}

function! s:go_ending() " {{{
  call s:show_ending_message()
  call s:enable_allkey()
endfunction
" }}}

function! s:show_ending_message() " {{{
  setlocal filetype=
  call s:draw_lines(s:message.get('ending_message'))
endfunction
" }}}

function! s:died_and_go_room_with_message(message) " {{{
  let s:died_times += 1
  call s:go_room()
  call s:EchoWarning(a:message, s:died_times)
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
  call s:init_puzzle()
endfunction
" }}}

function! s:init_keys() " {{{
  call s:disable_allkey()
  call s:enable_puzzle_key()
  call s:enable_keys_with_limit()
  call s:set_puzzle_key_count()
endfunction
" }}}

function! s:enable_puzzle_key() " {{{
  call s:enable_keys(
    \ get(s:current_puzzle, 'enable_keys', s:default_enable_keys))
endfunction
" }}}

function! s:set_puzzle_key_count() " {{{
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
    " TODO: exception
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
    call s:add_line(s:current_puzzle['room'])
    call s:add_line('')
    call s:add_line(s:message.get('room_title'))
    call s:add_line(get(s:current_puzzle, 'name', s:message.get('unknown_room_name')))
    call s:add_line('')
    call s:add_line(s:message.get('rule_of_room'))
    call s:print_enable_keys(
      \ get(s:current_puzzle, 'enable_keys', s:default_enable_keys))
    call s:print_limit_key_use(
      \ get(s:current_puzzle, 'limit_key_use', {}))

    call s:add_line('')
    if get(s:current_puzzle,  'disable_key_count', 0)
      call s:add_line(s:message.get('disable_command_count'))
    else
      call s:add_line(s:message.get('enable_command_count'))
    endif
  finally
    let &l:modifiable = s:save_modifiable
  endtry
endfunction
" }}}

function! s:print_enable_keys(keys) " {{{
  let keydict = s:build_keydict(a:keys)
  let enable_command = s:message.get('enable_command')

  call s:add_line(s:message.get('available_normal_command'))
  for key in get(keydict, 'n', [])
    call s:add_line(enable_command['n'][key])
  endfor

  if has_key(keydict, 'o')
    call s:add_line('')
    call s:add_line(s:message.get('available_operator_command'))
    for key in keydict['o']
      call s:add_line(enable_command['o'][key])
    endfor
  endif
endfunction
" }}}

function! s:print_limit_key_use(limit_key_use) " {{{
  if empty(a:limit_key_use)
    return
  endif

  call s:add_line('')
  call s:add_line(s:message.get('limit_of_normal_command_count'))
  for [key, cnt] in items(get(a:limit_key_use, 'n', {}))
    call s:add_line(key.':'.cnt)
  endfor

  if has_key(a:limit_key_use, 'o')
    call s:add_line('')
    call s:add_line(s:message.get('limit_of_operator_command_count'))
    for [key, cnt] in items(get(a:limit_key_use, 'o', {}))
      call s:add_line(key.':'.cnt)
    endfor
  endif
endfunction
" }}}

function! s:draw_lines(lines) " {{{
  let s:save_modifiable = &l:modifiable
  setlocal modifiable
  try
    call s:clear_buffer()
    call s:add_line(a:lines)
  finally
    let &l:modifiable = s:save_modifiable
  endtry
endfunction
" }}}

function! s:enable_keys_with_limit() " {{{
  let s:current_key_limit = deepcopy(get(s:current_puzzle, 'limit_key_use', {}))

  for [mode, keydict] in items(s:current_key_limit)
    for [key, cnt] in items(keydict)
      call s:enable_key_with_limit(key, mode)
    endfor
  endfor
endfunction
" }}}

function! s:enable_key_with_limit(key, mode) " {{{
  if !has_key(s:current_key_limit, a:mode) ||
    \!has_key(s:current_key_limit[a:mode], a:key)
    return
  endif

  call s:noremap_buffer(
    \ a:key,
    \ printf(':<C-u>call <SID>disable_key_if_limit(''%s'', ''%s'')<CR>', a:key, a:mode),
    \ a:mode)
endfunction
" }}}

function! s:disable_key_if_limit(key, mode) " {{{
  if s:current_key_limit[a:mode][a:key] <= 0
    call s:noremap_buffer(a:key, '<Nop>', a:mode)
    return
  endif
  let s:current_key_limit[a:mode][a:key] -= 1

  execute printf('normal! %s%s', (v:count == 0 ? '' : v:count), a:key)
endfunction
" }}}

function! s:exist_experiment(experiment) " {{{
  return has_key(s:experiments, a:experiment)
endfunction
" }}}

function! s:exist_puzzle(experiment, puzzle_number) " {{{
  return s:exist_experiment(a:experiment) &&
    \ a:puzzle_number - 1 < len(s:experiments[a:experiment])
endfunction
" }}}

" Tools {{{2
function! s:add_line(str) " {{{
  let lastline = line('$')
  if lastline == 1
    call setline(1, a:str)
  else
    call setline(lastline+1, a:str)
  endif
endfunction
" }}}

function! s:clear_buffer() " {{{
  %delete
endfunction
" }}}

function! s:char_under_cursor() " {{{
  return getline('.')[col('.')-1]
endfunction
" }}}

function! s:is_goal_under_cursor() " {{{
  return s:char_under_cursor() ==# 'g'
endfunction
" }}}

function! s:is_wall_under_cursor() " {{{
  let cur = s:char_under_cursor()
  return cur ==# '-' ||
    \    cur ==# '|' ||
    \    cur ==# '+'
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
  if s:P.is_string(a:keys) ||
    \s:P.is_list(a:keys)
    return { 'n' : s:split2char_if_str(a:keys) }
  elseif s:P.is_dict(a:keys)
    let keys = {}
    for key in keys(a:keys)
      call extend(keys, { key : s:split2char_if_str(a:keys[key]) })
    endfor
    return keys
  else
    call s:EchoError('Error:Invalid Argument:%s', type(a:keys))
    return {}
  endif
endfunction
" }}}

function! s:split2char_if_str(arg) " {{{
  return s:P.is_string(a:arg) ? split(a:arg, '\zs') : a:arg
endfunction
" }}}

function! s:enable_allkey() " {{{
  let nrkeys = []
  call extend(nrkeys, range(33, 48))
  call extend(nrkeys, range(58, 126))
  for nrkey in nrkeys
    for mode in split('nvo', '\ze')
      call s:enable_key(escape(nr2char(nrkey), '|'), 'nvo')
      call s:enable_key(escape('g'.nr2char(nrkey), '|'), 'nvo')
    endfor
  endfor

  call s:map_quit_key()
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
  call s:noremap_buffer('Q', ':<C-u>bwipeout!<CR>', 'n')
endfunction
" }}}

function! s:noremap_buffer(lhs, rhs, modes) " {{{
  if s:P.is_string(a:modes)
    let modes = split(a:modes, '\zs')
  else
    let modes = a:modes
  endif
  for mode in modes
    execute printf('%snoremap <silent><buffer> %s %s', mode, a:lhs, a:rhs)
  endfor
endfunction
" }}}

function! s:EchoWarning(message, ...) " {{{
  call s:Echo('WarningMsg', a:message, a:000)
endfunction
" }}}

function! s:EchoError(message, ...) " {{{
  call s:Echo('ErrorMsg', a:message, a:000)
endfunction
" }}}

function! s:Echo(level, message, args) " {{{
  redraw!
  let alen = len(a:args)
  if alen == 0
    let message = a:message
  elseif alen == 1
    let message = printf(a:message, a:args[0])
  elseif alen == 2
    let message = printf(a:message, a:args[0], a:args[1])
  else
    echoerr printf('error: s:Echo(level=%s) must be'
      \ 'specified lower equal than 3 argument', level)
  endif
  call s:VM.echomsg(a:level, message)
endfunction
" }}}

" }}}

" }}}


let &cpo = s:save_cpo
unlet s:save_cpo

" __END__ "{{{1
" vim: foldmethod=marker
