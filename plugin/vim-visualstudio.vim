" vim:foldmethod=marker:fen:

if exists('g:loaded_visualstudio')
  finish
elseif v:version < 702
  echoerr 'visualstudio.vim does not work this version of Vim "' . v:version . '".'
  finish
endif

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

let s:visualstudio_temp_result =""
let s:visualstudio_debug = 1
let s:visualstudio_install_vimproc = 0

function s:visual_studio_system(command)
    let l:enableVimproc = s:visual_studio_enable_vimproc()

    if l:enableVimproc == 1
        return vimproc#system(a:command)
    endif

    return system(a:command)
endfunction

function s:visual_studio_enable_vimproc()
    if s:visualstudio_install_vimproc == 0
        try
            call vimproc#version()
            let s:visualstudio_install_vimproc = 1
        catch
            let s:visualstudio_install_vimproc = 0
        endtry
    endif

    let l:temp = 0
    if s:visualstudio_install_vimproc == 1 && g:visualstudio_enablevimproc == 1
        let l:temp = 1
    endif
    return l:temp
endfunction


function! s:visualstudio_make_commnad(commnad, ...)
    let l:arglist = []
    for funargs in a:000
        let l:enableVimproc = s:visual_studio_enable_vimproc()
        if l:enableVimproc == 1
            let l:arglist += [funargs]
        else
            let l:arglist += [shellescape(funargs)]
        endif
    endfor
    let l:nativeargs = join(l:arglist, ' ')

    let l:result = shellescape(expand(g:visualstudio_controllerpath)) . " " . a:commnad . " " . l:nativeargs

    return substitute(l:result, "\\", "/", "g")
endfunction

if g:visualstudio_enableerrormarker == 1
    augroup visualstudio
        autocmd!
        autocmd QuickFixCmdPost cfile call <SID>visualstudio_seterrortype()
    augroup END
endif

function! s:visualstudio_seterrortype()
    let l:dic = getqflist()
    for l:d in l:dic
        if (l:d.bufnr == 0 || l:d.lnum == 0)
            continue
        endif
            
        let l:d.type = "w"
        if strlen(l:d.text) && stridx(l:d.text, 'error') >= 0
            let l:d.type = "e"
        endif
    endfor
    :call setqflist(l:dic)
endfunction

function! s:visualstudio_open_output()
    :call <SID>visualstudio_save_output()
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'setlocal errorformat='.g:visualstudio_errorformat
    exe 'cfile '.g:visualstudio_outputfilepath
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

function! s:visualstudio_open_error_list()
    :call <SID>visualstudio_save_error_list()
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'setlocal errorformat='.g:visualstudio_errorformat
    exe 'cfile '.g:visualstudio_outputfilepath
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

" find {{{
function! s:visualstudio_open_find_result(findType)
    :call <SID>visualstudio_save_findResult(a:findType)
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'setlocal errorformat='.g:visualstudio_findformat
    exe 'cfile '.g:visualstudio_findresultfilepath
endfunction

function! s:visualstudio_save_findResult(findType)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("getfindresult1", "-t", currentfilefullpath)
    if a:findType == 1
        let l:cmd = <SID>visualstudio_make_commnad("getfindresult2", "-t", currentfilefullpath)
    endif
    let s:visualstudio_temp_result = system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_findresultfilepath)
endfunction
"}}}

function! s:visualstudio_get_current_file(...)
    let l:cmd = <SID>visualstudio_make_commnad("getfile")
    if a:0
        let l:cmd = <SID>visualstudio_make_commnad("getfile", "-t", a:1)
    endif
    
    let s:visualstudio_temp_result = system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    "echo l:temp
    exe 'e '.l:temp
endfunction


function! s:visualstudio_save_output()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("getoutput", "-t", "\"". currentfilefullpath . "\"")
    let s:visualstudio_temp_result = system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_outputfilepath)
endfunction

function! s:visualstudio_save_error_list()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("geterrorlist", "-t", currentfilefullpath)
    let s:visualstudio_temp_result = system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_outputfilepath)
endfunction


" build solution. & clean solution"{{{
function! s:visualstudio_build_solution(wait)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("build", "-t", shellescape(currentfilefullpath), "-w")
    echo l:cmd
    
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_rebuild_solution(wait)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("rebuild", "-t", currentfilefullpath, "-w")
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_clean_solution(wait)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("clean", "-t", currentfilefullpath, "-w")
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

"}}}

function! s:visualstudio_compile_file(wait)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("compilefile", "-t", currentfilefullpath, "-f", currentfilefullpath, a:wait == 1 ? "-w" : "")
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_add_break_point()
    let currentfilefullpath = expand("%:p")
    let linenum = line(".")
    let l:cmd = <SID>visualstudio_make_commnad("addbreakpoint", "-t", currentfilefullpath, "-f", currentfilefullpath, "-line", linenum)
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
endfunction


function! s:visualstudio_open_file()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
endfunction


function! s:visualstudio_cancel_build()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("cancelbuild", "-t", currentfilefullpath)
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
endfunction

function! s:visualstudio_run(runType)
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("run", "-t", currentfilefullpath)
    if a:runType == 1
        let l:cmd = <SID>visualstudio_make_commnad("debugrun", "-t", currentfilefullpath)
    endif
    let s:visualstudio_temp_result = <SID>visual_studio_system(l:cmd)
endfunction

function! s:visualstudio_echo_result()
    echo s:visualstudio_temp_result
endfunction


if s:visualstudio_debug == 1
    function! s:visualstudio_debug_testFunc()
        let savefilename = g:visualstudio_outputfilepath
        echo savefilename
        echo expand(savefilename)
    endfunction

    function! s:visualstudio_debug_testFunc2()
        call <SID>visualstudio_rebuild_solution(0)
        call <SID>visualstudio_cancel_build()
    endfunction

endif


" vim-visualstudio functions {{{

"compile & build {{{
command! VSCompile :call <SID>visualstudio_compile_file(1)
command! VSCompileNoWait :call <SID>visualstudio_compile_file(0)
command! VSBuild :call <SID>visualstudio_build_solution(1)
command! VSReBuild :call <SID>visualstudio_rebuild_solution(1)
command! VSBuildNoWait :call <SID>visualstudio_build_solution(0)
command! VSReBuildNoWait :call <SID>visualstudio_rebuild_solution(0)
command! VSCancelBuild :call <SID>visualstudio_cancel_build()
"}}}

"find {{{
command! VSFindResult1 :call <SID>visualstudio_open_find_result(0)
command! VSFindResult2 :call <SID>visualstudio_open_find_result(1)
"}}}

" run {{{
command! VSRun :call <SID>visualstudio_run(0)
command! VSDebugRun :call <SID>visualstudio_run(1)
"}}}


" clean {{{
command! VSClean :call <SID>visualstudio_clean_solution(1)
command! VSCleanNoWait :call <SID>visualstudio_clean_solution(0)
"}}}

" open & get file {{{
command! VSOpenFile :call <SID>visualstudio_open_file()
command! -nargs=? VSGetFile :call <SID>visualstudio_get_current_file(<f-args>)
" }}}


"other {{{
command! VSOutput :call <SID>visualstudio_open_output()
command! VSErorrList :call <SID>visualstudio_open_error_list()
command! VSAddBreakPoint :call <SID>visualstudio_add_break_point()
"}}}

"test function {{{
if s:visualstudio_debug == 1
    command! VSTestFunc1 :call <SID>visualstudio_debug_testFunc()
    command! VSTestFunc2 :call <SID>visualstudio_debug_testFunc2()
    command! VSTestFunc3 :call <SID>visual_studio_enable_vimproc()
endif
"}}}

"}}}


let g:loaded_visualstudio = 0
