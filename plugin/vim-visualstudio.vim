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
        \ get(g:, 'g:visualstudio_enableerrormarker', 0)
"}}}
"
let s:visualstudio_temp_result =""
let s:loaded_visualstudio_debug = 0

function! s:visualstudio_make_commnad(commnad, ...)
    let arglist = []
    for funargs in a:000
        let arglist += [shellescape(funargs)]
    endfor
    let nativeargs = join(arglist, ' ')
    return g:visualstudio_controllerpath . " " . a:commnad . " " . nativeargs
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

function! s:visualstudio_open_find_result(findType)
    :call <SID>visualstudio_save_findResult(a:findType)
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'setlocal errorformat='.g:visualstudio_findformat
    exe 'cfile '.g:visualstudio_findresultfilepath
endfunction

function! s:visualstudio_get_current_file(...)
    let cmd = <SID>visualstudio_make_commnad("getfile")
    if a:0
        let cmd = <SID>visualstudio_make_commnad("getfile", "-t", a:1)
    endif
    
    let s:visualstudio_temp_result = system(cmd)
    exe 'e '.s:visualstudio_temp_result
endfunction


" solution."{{{
function! s:visualstudio_build_solution(wait)
    let currentfilefullpath = expand("%:p")
    let cmd = <SID>visualstudio_make_commnad("build", "-t", currentfilefullpath, a:wait == 1 ? "-w" : "")
    let s:visualstudio_temp_result = system(cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_rebuild_solution(wait)
    let currentfilefullpath = expand("%:p")
    let cmd = <SID>visualstudio_make_commnad("rebuild", "-t", currentfilefullpath, a:wait == 1 ? "-w" : "")
    let s:visualstudio_temp_result = system(cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_clean_solution(wait)
    let currentfilefullpath = expand("%:p")
    let cmd = <SID>visualstudio_make_commnad("clean", "-t", currentfilefullpath, a:wait == 1 ? "-w" : "")
    let s:visualstudio_temp_result = system(cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

"}}}

function! s:visualstudio_compile_file(wait)
    let currentfilefullpath = expand("%:p")
    let cmd = <SID>visualstudio_make_commnad("compilefile", "-t", currentfilefullpath, "-f", currentfilefullpath, a:wait == 1 ? "-w" : "")
    let s:visualstudio_temp_result = system(cmd)
    if a:wait == 1 && g:visualstudio_autoshowoutput==1
        :call <SID>visualstudio_open_output()
    endif
endfunction

function! s:visualstudio_add_break_point()
    let currentfilefullpath = expand("%:p")
    let linenum = line(".")
    let cmd = <SID>visualstudio_make_commnad("addbreakpoint", "-t", currentfilefullpath, "-f", currentfilefullpath, "-line", linenum)
    let s:visualstudio_temp_result = system(cmd)
endfunction



function! s:visualstudio_open_file()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = system(cmd)
endfunction

function! s:visualstudio_save_output()
    let currentfilefullpath = expand("%:p")
    let l:cmd = <SID>visualstudio_make_commnad("getoutput", "-t", currentfilefullpath)
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

function! s:visualstudio_echo_result()
    echo s:visualstudio_temp_result
endfunction


if s:loaded_visualstudio_debug == 1
    function! s:visualstudio_debug_testFunc()
        let savefilename = g:visualstudio_outputfilepath
        echo savefilename
        echo expand(savefilename)
    endfunction
    command! VSTestFunc :call <SID>visualstudio_save_error_list()
endif
        

command! VSOutput :call <SID>visualstudio_open_output()
command! VSFindResult1 :call <SID>visualstudio_open_find_result(0)
command! VSFindResult2 :call <SID>visualstudio_open_find_result(1)
command! VSBuild :call <SID>visualstudio_build_solution(1)
command! VSReBuild :call <SID>visualstudio_rebuild_solution(1)
command! VSClean :call <SID>visualstudio_clean_solution(1)
command! VSBuildNoWait :call <SID>visualstudio_build_solution(0)
command! VSReBuildNoWait :call <SID>visualstudio_rebuild_solution(0)
command! VSCleanNoWait :call <SID>visualstudio_clean_solution(0)
command! VSCompile :call <SID>visualstudio_compile_file(1)
command! VSCompileNoWait :call <SID>visualstudio_compile_file(0)
command! VSOpenFile :call <SID>visualstudio_open_file()
command! VSAddBreakPoint :call <SID>visualstudio_add_break_point()
command! VSErorrList :call <SID>visualstudio_open_error_list()
command! -nargs=? VSGetFile :call <SID>visualstudio_get_current_file(<f-args>)

let g:loaded_visualstudio = 0
