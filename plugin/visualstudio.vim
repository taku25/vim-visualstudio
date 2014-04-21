
if exists('g:loaded_visualstudio')
  finish
elseif v:version < 702
  echoerr 'visualstudio.vim does not work this version of Vim "' . v:version . '".'
  finish
endif
let g:loaded_visualstudio = 1

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

" Global options definition."{{{
let g:visualstudio_controllerpath =
      \ get(g:, 'visualstudio_controllerpath', 'VisualStudioController.exe')

let g:visualstudio_outputfilepath =
      \ get(g:, 'visualstudio_outputfilepath', expand($TEMP).'/vs_output.vstxt')

let g:visualstudio_findresultfilepath =
      \ get(g:, 'visualstudio_findresultfilepath', expand($TEMP).'/vs_findresult.vstxt')

let g:visualstudio_getfileresultfilepath =
      \ get(g:, 'visualstudio_getfileresultfilepath', expand($TEMP).'/vs_getfileresult.vstxt')

let g:visualstudio_quickfixheight =
      \ get(g:, 'visualstudio_quickfixheight', 30)

let g:visualstudio_errorformat =
      \ get(g:, 'visualstudio_errorformat', '%f\(%l\):\ %m')

let g:visualstudio_findformat =
      \ get(g:, 'visualstudio_findformat', '%f\(%l\):%m')

let g:visualstudio_autoshowoutput =
      \ get(g:, 'visualstudio_autoshowoutput', 1)

let g:visualstudio_enableerrormarker =
      \ get(g:, 'visualstudio_enableerrormarker', 0)

let g:visualstudio_enablevimproc =
      \ get(g:, 'visualstudio_enablevimproc', 1)

"}}}

" vim-visualstudio functions {{{

"compile & build {{{
"command! VSCompile :call <SID>visualstudio_compile_file(1)
"command! VSCompileNoWait :call <SID>visualstudio_compile_file(0)
"command! VSBuild :call <SID>visualstudio_build_solution(1)
"command! VSReBuild :call <SID>visualstudio_rebuild_solution(1)
"command! VSBuildNoWait :call <SID>visualstudio_build_solution(0)
"command! VSReBuildNoWait :call <SID>visualstudio_rebuild_solution(0)
"command! VSCancelBuild :call <SID>visualstudio_cancel_build()
"}}}

"find {{{
"command! VSFindResult1 :call <SID>visualstudio_open_find_result(0)
"command! VSFindResult2 :call <SID>visualstudio_open_find_result(1)
"}}}

" run {{{
command! VSRun call visualstudio#run(0)
command! VSDebugRun call visualstudio#run(1)
"}}}


" clean {{{
"command! VSClean :call <SID>visualstudio_clean_solution(1)
"command! VSCleanNoWait :call <SID>visualstudio_clean_solution(0)
"}}}

" open & get file {{{
command! VSOpenFile call visualstudio#open_file()
command! -nargs=? VSGetFile call visualstudio#get_current_file(<f-args>)
" }}}


"other {{{
"command! VSOutput :call <SID>visualstudio_open_output()
"command! VSErorrList :call <SID>visualstudio_open_error_list()
"command! VSAddBreakPoint :call <SID>visualstudio_add_break_point()
"}}}


"}}} endfuc

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

