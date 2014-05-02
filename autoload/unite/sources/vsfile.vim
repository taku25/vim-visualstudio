let s:save_cpo = &cpo
set cpo&vim

let s:unite_source = {
      \ 'name': 'vsfile',
      \ }

function! s:unite_source.gather_candidates(args, context)
  return map(unite#sources#vsfile#vsfiles(), '{
        \ "word": v:val,
        \ "source": "vsfile",
        \ "kind": "file",
        \ "action__path": v:val,
        \ }')
endfunction

function! unite#sources#vsfile#vsfiles()
    let files =  visualstudio#get_all_files()
    return files
endfunction

function! unite#sources#vsfile#define()
  return  s:unite_source
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

