" duzzle.vim source for unite.vim
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


scriptencoding utf-8

" define source
function! unite#sources#duzzle#define()
  return s:source
endfunction

" source
let s:source = {
  \ 'name': 'duzzle',
  \ 'action_table': {},
  \ }

function! s:source.gather_candidates(args, context)
  let result = []

  let experiment = get(a:args, 0, '_')
  let puzzles = duzzle#puzzle_list(experiment)
  let i = 1
  for puzzle in puzzles
    call add(result, {
      \ 'word': get(puzzle, 'name', string(i)),
      \ 'kind': 'command',
      \ 'source': 'duzzle',
      \ 'action__command': "call duzzle#start('".experiment." ".string(i)."')",
      \ })
    let i += 1
  endfor

  return result
endfunction

function! s:source.complete(args, context, arglead, cmdline, cursorpos)
  let experiments = duzzle#experiment_names()

  return filter(experiments, "stridx(v:val, '".a:arglead."') == 0")
endfunction

" vim: foldmethod=marker
