if exists ("b:current_syntax")
    finish
endif

syntax match   duzzleField  / /      contained
syntax match   duzzleWall   /[-|+]/  contained
syntax match   duzzleStart  /\<s\>/  contained
syntax match   duzzleEnd    /\<g\>/  contained

syntax region DuzzleMap  start=/\%^/ end=/\ze\[ルーム名\]/ contains=duzzleField,duzzleWall,duzzleStart,duzzleEnd

highlight duzzleFieldHi  guibg=lightcyan ctermbg=lightcyan
highlight duzzleWallHi   guibg=dimgray   ctermbg=gray
highlight duzzleStartHi  guibg=blue      ctermbg=blue
highlight duzzleEndHi    guibg=red       ctermbg=red

hi def link duzzleField  duzzleFieldHi
hi def link duzzleWall   duzzleWallHi
hi def link duzzleStart  duzzleStartHi
hi def link duzzleEnd    duzzleEndHi

let b:current_syntax = "duzzle"
