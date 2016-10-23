syntax enable

let s:V = vital#of('vital')
let s:S = s:V.import('Vim.ScriptLocal')
let sf = s:S.sfuncs('autoload/duzzle.vim')

let s:test_tools = themis#suite('Test for duzzle tools')

function! s:test_tools.__for_buffer__()
  let basic = themis#suite('check for buffer')

  function! basic.before_each()
    new
    silent put! =[
      \ 'test1',
      \ 'test2',
      \ 'test3',
      \ ]
  endfunction

  function! basic.after_each()
    quit!
  endfunction

  function! basic.clear_buffer()
    sf.add_line('add line1')
    sf.add_line('add line2')
    Assert Equals(getline(3), 'test3')
    Assert Equals(getline(4), 'add line1')
    Assert Equals(getline(5), 'add line2')
    Assert Equals(line('$'), 5)
    %delete
    sf.add_line('add line1')
    sf.add_line('add line2')
    Assert Equals(getline(1), 'add line1')
    Assert Equals(getline(2), 'add line2')
    Assert Equals(line('$'), 2)
  endfunction

  function! basic.clear_buffer()
    sf.clear_buffer()
    Assert Equals(getline(1), '')
    Assert Equals(line('$'), 1)
  endfunction

  function! basic.char_under_cursor()
    sf.clear_buffer()
    Assert Equals(getline(1), '')
    Assert Equals(line('$'), 1)
  endfunction

  function! basic.is_goal_under_cursor()
    normal! gg
    Assert False(sf.is_goal_under_cursor())
    normal! rg
    Assert True(sf.is_goal_under_cursor())
  endfunction

  function! basic.is_wall_under_cursor()
    normal! gg
    Assert False(sf.is_wall_under_cursor())
    normal! r-
    Assert True(sf.is_wall_under_cursor())
    normal! r|
    Assert True(sf.is_wall_under_cursor())
    normal! r+
    Assert True(sf.is_wall_under_cursor())
  endfunction

endfunction

