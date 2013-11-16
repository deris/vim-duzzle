if exists ("b:current_syntax")
    finish
endif

syntax match   duzzleField  / /      contained
syntax match   duzzleWall   /[-|+]/  contained
syntax match   duzzleStart  /\<s\>/  contained
syntax match   duzzleEnd    /\<g\>/  contained

syntax region DuzzleMap  start=/\%^/ end=/\[ルーム名\]/ contains=duzzleField,duzzleWall,duzzleStart,duzzleEnd

highlight duzzleFieldHi  guibg=#ffccff ctermbg=red
highlight duzzleWallHi   guibg=#666666 ctermbg=green
highlight duzzleStartHi  guibg=blue    ctermbg=blue
highlight duzzleEndHi    guibg=red     ctermbg=yellow

hi def link duzzleField  duzzleFieldHi
hi def link duzzleWall   duzzleWallHi
hi def link duzzleStart  duzzleStartHi
hi def link duzzleEnd    duzzleEndHi

let b:current_syntax = "duzzle"
