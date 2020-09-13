function! leaderf#duzzle#source(args) abort "{{{
	let l:duzzles = []
	for l:duzzle_puzzle in duzzle#puzzle_list('_')
		let l:duzzles += [matchstr(l:duzzle_puzzle['name'], '\d\+')]
	endfor
	return l:duzzles
endfunction "}}}

function! leaderf#duzzle#accept(line, args) abort "{{{
	execute 'DuzzleStart ' . a:line
endfunction "}}}
