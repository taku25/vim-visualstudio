﻿" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}

" local variable.  " {{{1
let s:visualstudio_temp_result =""
let s:visualstudio_install_vimproc = 0
"}}}

function! s:visualstudio_enable_vimproc()
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

function! s:visualstudio_system(command)
    let l:enableVimproc = s:visualstudio_enable_vimproc()

    if l:enableVimproc == 1
        return vimproc#system(a:command)
    endif

    return system(a:command)
endfunction


function! s:visualstudio_get_current_buffer_fullpath()
    let l:currentfilefullpath = expand("%:p")
    let l:enableVimproc = s:visualstudio_enable_vimproc()
    if l:enableVimproc == 1
        let l:currentfilefullpath = shellescape(l:currentfilefullpath)
    else
        let l:currentfilefullpath = l:currentfilefullpath
    endif
    return l:currentfilefullpath
endfunction


function! s:visualstudio_make_command(command, ...)
    let l:arglist = []
    let l:enableVimproc = s:visualstudio_enable_vimproc()
    for funargs in a:000
        if l:enableVimproc == 1
            let l:arglist += [funargs]
        else
            let l:arglist += [shellescape(funargs)]
        endif
    endfor
    let l:nativeargs = join(l:arglist, ' ')

    let l:result = shellescape(expand(g:visualstudio_controllerpath)) . " " . a:command . " " . l:nativeargs

    return substitute(l:result, "\\", "/", "g")
endfunction

"function! s:visualstudio_is_wait(wait)
    "let l:enableVimproc = s:visualstudio_enable_vimproc()
    "let l:temp = a:wait

    ""vimproc system_
    ""if l:enableVimproc == 1
        ""let l:temp = 1
    ""endif
    "return l:temp
"endfunction


"if g:visualstudio_enableerrormarker == 1
    "augroup visualstudio
        "autocmd!
        "autocmd QuickFixCmdPost cfile call <SID>visualstudio_seterrortype()
    "augroup END
"endif

"function! s:visualstudio_seterrortype()
    "let l:dic = getqflist()
    "for l:d in l:dic
        "if (l:d.bufnr == 0 || l:d.lnum == 0)
            "continue
        "endif
            
        "let l:d.type = "w"
        "if strlen(l:d.text) && stridx(l:d.text, 'error') >= 0
            "let l:d.type = "e"
        "endif
    "endfor
    ":call setqflist(l:dic)
"endfunction

"function! s:visualstudio_open_output()
    ":call <SID>visualstudio_save_output()
    "exe 'copen '.g:visualstudio_quickfixheight
    "exe 'setlocal errorformat='.g:visualstudio_errorformat
    "exe 'cfile '.g:visualstudio_outputfilepath
    "if g:visualstudio_enableerrormarker == 1
        ":doautocmd QuickFixCmdPost make
    "endif
"endfunction

"function! s:visualstudio_open_error_list()
    ":call <SID>visualstudio_save_error_list()
    "exe 'copen '.g:visualstudio_quickfixheight
    "exe 'setlocal errorformat='.g:visualstudio_errorformat
    "exe 'cfile '.g:visualstudio_outputfilepath
    "if g:visualstudio_enableerrormarker == 1
        ":doautocmd QuickFixCmdPost make
    "endif
"endfunction

"" find {{{
"function! s:visualstudio_open_find_result(findType)
    ":call <SID>visualstudio_save_findResult(a:findType)
    "exe 'copen '.g:visualstudio_quickfixheight
    "exe 'setlocal errorformat='.g:visualstudio_findformat
    "exe 'cfile '.g:visualstudio_findresultfilepath
"endfunction

"function! s:visualstudio_save_findResult(findType)
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:cmd = <SID>visualstudio_make_command("getfindresult1", "-t", currentfilefullpath)
    "if a:findType == 1
        "let l:cmd = <SID>visualstudio_make_command("getfindresult2", "-t", currentfilefullpath)
    "endif
    "let s:visualstudio_temp_result = system(l:cmd)
    "let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    "let l:value = split(l:temp, "\n")
    "call writefile(l:value, g:visualstudio_findresultfilepath)
"endfunction
""}}}



"function! s:visualstudio_save_output()
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:cmd = <SID>visualstudio_make_command("getoutput", "-t", "\"". currentfilefullpath . "\"")
    "let s:visualstudio_temp_result = system(l:cmd)
    "let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    "let l:value = split(l:temp, "\n")
    "call writefile(l:value, g:visualstudio_outputfilepath)
"endfunction

"function! s:visualstudio_save_error_list()
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:cmd = <SID>visualstudio_make_command("geterrorlist", "-t", currentfilefullpath)
    "let s:visualstudio_temp_result = system(l:cmd)
    "let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    "let l:value = split(l:temp, "\n")
    "call writefile(l:value, g:visualstudio_outputfilepath)
"endfunction


"" build solution. & clean solution"{{{
"function! s:visualstudio_build_solution(wait)
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:iswait = <SID>visualstudio_is_wait(a:wait)
    "let l:cmd = <SID>visualstudio_make_command("build", "-t", currentfilefullpath, l:iswait == 1 ? "-w" : "")
    
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
    "if l:iswait == 1 && g:visualstudio_autoshowoutput==1
        ":call <SID>visualstudio_open_output()
    "endif
"endfunction

"function! s:visualstudio_rebuild_solution(wait)
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:iswait = <SID>visualstudio_is_wait(a:wait)
    "let l:cmd = <SID>visualstudio_make_command("rebuild", "-t", currentfilefullpath, l:iswait == 1 ? "-w" : "")
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
    "if l:iswait == 1 && g:visualstudio_autoshowoutput==1
        ":call <SID>visualstudio_open_output()
    "endif
"endfunction

"function! s:visualstudio_clean_solution(wait)
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:iswait = <SID>visualstudio_is_wait(a:wait)
    "let l:cmd = <SID>visualstudio_make_command("clean", "-t", currentfilefullpath, l:iswait == 1 ? "-w" : "")
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
    "if l:iswait == 1 && g:visualstudio_autoshowoutput==1
        ":call <SID>visualstudio_open_output()
    "endif
"endfunction

""}}}

"function! s:visualstudio_compile_file(wait)
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:iswait = <SID>visualstudio_is_wait(a:wait)
    "let l:cmd = <SID>visualstudio_make_command("compilefile", "-t", currentfilefullpath, "-f", currentfilefullpath, l:iswait == 1 ? "-w" : "")
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
    "if l:iswait == 1 && g:visualstudio_autoshowoutput==1
        ":call <SID>visualstudio_open_output()
    "endif
"endfunction

"function! s:visualstudio_add_break_point()
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let linenum = line(".")
    "let l:cmd = <SID>visualstudio_make_command("addbreakpoint", "-t", currentfilefullpath, "-f", currentfilefullpath, "-line", linenum)
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
"endfunction




"function! s:visualstudio_cancel_build()
    "let currentfilefullpath = <SID>visualstudio_get_current_buffer_fullpath()
    "let l:cmd = <SID>visualstudio_make_command("cancelbuild", "-t", currentfilefullpath)
    "let s:visualstudio_temp_result = <SID>visualstudio_system(l:cmd)
"endfunction

" open & get file {{{
function! visualstudio#get_current_file(...)
    let l:cmd = s:visualstudio_make_command("getfile")
    if a:0
        let l:cmd = s:visualstudio_make_command("getfile", "-t", a:1)
    endif
    
    let s:visualstudio_temp_result = system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, 'cp932', &encoding)
    exe 'e '.l:temp
endfunction

function! visualstudio#open_file()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

function! visualstudio#run(runType)
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("run", "-t", currentfilefullpath)
    if a:runType == 1
        let l:cmd = s:visualstudio_make_command("debugrun", "-t", currentfilefullpath)
    endif
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

