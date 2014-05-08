
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

let g:visualstudio_quickfixheight =
      \ get(g:, 'visualstudio_quickfixheight', 10)

let g:visualstudio_errorformat =
      \ get(g:, 'visualstudio_errorformat', '%.%#>%f(%l):%m,%.%#>%f(%l\,%c%.%#):%m')

let g:visualstudio_errorlistformat =
      \ get(g:, 'visualstudio_errorlistformat', '%f (%l\,%c):%m')

let g:visualstudio_findformat =
      \ get(g:, 'visualstudio_findformat', '%f(%l):%m')

let g:visualstudio_showautooutput =
      \ get(g:, 'visualstudio_showautooutput', 1)

let g:visualstudio_enableerrormarker =
      \ get(g:, 'visualstudio_enableerrormarker', 0)

let g:visualstudio_enablevimproc =
      \ get(g:, 'visualstudio_enablevimproc', 1)

let g:visualstudio_updatetime =
      \ get(g:, 'visualstudio_updatetime', 2000)

let g:visualstudio_terminalencoding =
      \ get(g:, 'visualstudio_terminalencoding', 'utf-8')
"}}}

" vim-visualstudio functions {{{

" build {{{
command! VSCompile call visualstudio#compile_file("-w")
command! VSBuild call visualstudio#build_solution("build", "-w")
command! VSReBuild call visualstudio#build_solution("rebuild", "-w")

command! VSCompileNoWait call visualstudio#compile_file("")
command! VSBuildNoWait call visualstudio#build_solution("build", "")
command! VSReBuildNoWait call visualstudio#build_solution("rebuild", "")

" config {{{
command! -nargs=? VSSetBuildConfig call visualstudio#set_build_config(<f-args>)
command! -nargs=? VSSetPlatform call visualstudio#set_build_platform(<f-args>)
" }}}

" cancel {{{
command! -nargs=? VSCancelBuild call visualstudio#cancel_build(<f-args>)
" }}}

" clean {{{
command! -nargs=? VSClean call visualstudio#clean_solution(<f-args>)
"}}}

" result  {{{
command! -nargs=? VSOutput call visualstudio#open_output(<f-args>)
command! -nargs=? VSErorrList call visualstudio#open_error_list(<f-args>)
"}}}

" }}}


" run {{{
command! -nargs=? VSRun call visualstudio#run(0, <f-args>)
command! -nargs=? VSDebugRun call visualstudio#run(1, <f-args>)
command! -nargs=? VSSetStartUpProject call visualstudio#set_startup_project(<f-args>)
command! -nargs=? VSStopDebugRun call visualstudio#stop_debug_run(<f-args>)
"}}}


"find {{{

" solution {{{
command! -nargs=+ VSFindSolution1 call visualstudio#find("solution", "one", "-w", <f-args>)
command! -nargs=+ VSFindSolution2 call visualstudio#find("solution", "two", "-w", <f-args>)
command! -nargs=+ VSFindSolutionNoWait1 call visualstudio#find("solution", "one", "", <f-args>)
command! -nargs=+ VSFindSolutionNoWait2 call visualstudio#find("solution", "two", "", <f-args>)
"}}}

" project {{{
command! -nargs=+ VSFindProject1 call visualstudio#find("project", "one", "-w", <f-args>)
command! -nargs=+ VSFindProject2 call visualstudio#find("project", "two", "-w", <f-args>)
command! -nargs=+ VSFindProjectNoWait1 call visualstudio#find("project", "one", "", <f-args>)
command! -nargs=+ VSFindProjectNoWait2 call visualstudio#find("project", "two", "", <f-args>)
"}}}

" result  {{{
command! -nargs=? VSFindResult1 call visualstudio#open_find_result(0, <f-args>)
command! -nargs=? VSFindResult2 call visualstudio#open_find_result(1, <f-args>)
"}}}

"}}}

" open & get file {{{
command! VSOpenFile call visualstudio#open_file()
command! -nargs=? VSGetFile call visualstudio#get_current_file(<f-args>)
" }}}


"other {{{
command! VSAddBreakPoint call visualstudio#add_break_point()
command! -nargs=? VSChangeDirectory call visualstudio#change_directory(<f-args>)
"}}}


"}}} endfuc

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

