if exists("b:duzzle_ftplugin")
  finish
endif
let b:duzzle_ftplugin = 1

augroup duzzle
  autocmd!
  autocmd CursorMoved <buffer>  call duzzle#check_cursor()
  autocmd BufEnter    <buffer>  call duzzle#init_keys()
augroup END

