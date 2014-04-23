
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
      \ get(g:, 'visualstudio_quickfixheight', 10)

let g:visualstudio_errorformat =
      \ get(g:, 'visualstudio_errorformat', '%.\*>%f\(%l\):\ %m')

let g:visualstudio_findformat =
      \ get(g:, 'visualstudio_findformat', '%f\(%l\):%m')

let g:visualstudio_showautooutput =
      \ get(g:, 'visualstudio_showautooutput', 1)

let g:visualstudio_enableerrormarker =
      \ get(g:, 'visualstudio_enableerrormarker', 0)

let g:visualstudio_enablevimproc =
      \ get(g:, 'visualstudio_enablevimproc', 1)

let g:visualstudio_updatetime =
      \ get(g:, 'visualstudio_updatetime', 2000)

"}}}

" vim-visualstudio functions {{{

"compile & build {{{
command! VSCompile call visualstudio#compile_file("-w")
command! VSCompileNoWait call visualstudio#compile_file("")
command! VSBuild call visualstudio#build_solution("build", "-w")
command! VSReBuild call visualstudio#build_solution("rebuild", "-w")
command! VSBuildNoWait call visualstudio#build_solution("build", "")
command! VSReBuildNoWait call visualstudio#build_solution("rebuild", "")
"}}}

"cancel{{{
command! VSCancelBuild call visualstudio#cancel_build("")
"}}}

" run {{{
command! VSRun call visualstudio#run(0)
command! VSDebugRun call visualstudio#run(1)
"}}}


" clean {{{
command! VSClean call visualstudio#clean_solution()
"}}}

"find {{{
command! VSFindResult1 call visualstudio#open_find_result(0)
command! VSFindResult2 call visualstudio#open_find_result(1)
"}}}

" open & get file {{{
command! VSOpenFile call visualstudio#open_file()
command! -nargs=? VSGetFile call visualstudio#get_current_file(<f-args>)
" }}}


"other {{{
command! VSOutput call visualstudio#open_output("")
command! VSErorrList call visualstudio#open_error_list("")
command! VSAddBreakPoint call visualstudio#add_break_point()
"}}}


"}}} endfuc

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}


" vim:foldmethod=marker:fen:

