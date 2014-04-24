" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
"}}}


" vital  {{{
let s:vital = vital#of('visualstudio')
let s:vital_processmanager = s:vital.import('ProcessManager')
let s:vital_datastring = s:vital.import('Data.String')
" }}}

" Create augroup.
augroup plugin-visualstudio
augroup END

" local variable.  " {{{1
let s:visualstudio_temp_result =""
let s:visualstudio_install_vimproc = 0
let s:visualstudio_last_build_solution_fullpath = ""
let s:visualstudio_global_update_time = &updatetime
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

if g:visualstudio_enableerrormarker == 1
    augroup plugin-visualstudio-errortype
        autocmd!
        autocmd QuickFixCmdPost cfile call s:visualstudio_seterrortype()
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

"" compile & build "{{{
function! visualstudio#build_solution(buildtype, wait)
    let l:currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command(a:buildtype, "-t", l:currentfilefullpath, a:wait)
    
    if a:wait == "-w"
        let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
        if g:visualstudio_showautooutput == 1
            call visualstudio#open_output(l:currentfilefullpath)
        endif
    else
        let l:enableVimproc = s:visualstudio_enable_vimproc()
        "waitなしでvimprocが使えない時は自動表示はしない
        if l:enableVimproc == 0
            let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
        else
            if g:visualstudio_showautooutput == 0
                let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
            else
                "waitなし かつ vimprocが使用できる かつ　自動表示時のみ
                "processmanagerを使用する
                "{
                    let l:tempcmd = s:visualstudio_make_command("getsolutionfullpath", "-t", l:currentfilefullpath)
                    let l:temp_result = s:visualstudio_system(l:tempcmd)
                    let l:solutionfullpath = iconv(l:temp_result, g:visualstudio_terminalencoding, &encoding)
                    let l:solutionfullpath = s:vital_datastring.chop(l:solutionfullpath)        
                    if s:visualstudio_last_build_solution_fullpath == l:solutionfullpath
                        "同じsolutionをビルドなら前のを消しておく
                        call visualstudio#cancel_build(l:solutionfullpath)
                        let &updatetime = s:visualstudio_global_update_time
                        augroup plugin-visualstudio
                            autocmd! 
                        augroup END
                        try
                            s:vital_processmanager.kill("visualstudio_build")
                        catch
                        endtry
                    endif
                    let s:visualstudio_last_build_solution_fullpath = l:solutionfullpath
                "}
                "起動
                call s:vital_processmanager.touch("visualstudio_build", l:cmd)
                let &updatetime = g:visualstudio_updatetime
                "ちょっとまち
                sleep 500m
                augroup plugin-visualstudio
                    execute 'autocmd! CursorHold,CursorHoldI * call' 's:visualstudio_check_finished()'
                augroup END
            endif
        endif
    endif
endfunction

function! visualstudio#compile_file(wait)
    let l:currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("compilefile", "-t", l:currentfilefullpath, "-f", l:currentfilefullpath, a:wait)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    if a:wait != "" && g:visualstudio_showautooutput==1
        call visualstudio#open_output(l:currentfilefullpath)
    endif
endfunction
                    
function! s:visualstudio_check_finished()
    let l:cmd = s:visualstudio_make_command("getbuildstatus", "-t", s:visualstudio_last_build_solution_fullpath)
    let l:status = iconv(s:visualstudio_system(l:cmd), g:visualstudio_terminalencoding, &encoding)
    if l:status != "InProgress"
        "もどし
        let &updatetime = s:visualstudio_global_update_time
        augroup plugin-visualstudio
            autocmd! 
        augroup END
        call s:vital_processmanager.kill("visualstudio_build")
        call visualstudio#open_output(shellescape(s:visualstudio_last_build_solution_fullpath))
    endif
endfunction

"}}}


" build cancel {{{
function! visualstudio#cancel_build(...)
    let l:currentfilefullpath = a:0 ? a:0 : s:visualstudio_get_current_buffer_fullpath() 
    let l:cmd = s:visualstudio_make_command("cancelbuild", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" clean {{{
function! visualstudio#clean_solution()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("clean", "-t", currentfilefullpath )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" open & get file {{{
function! visualstudio#get_current_file(...)
    let l:cmd = s:visualstudio_make_command("getfile")
    if a:0
        let l:cmd = s:visualstudio_make_command("getfile", "-t", a:1)
    endif
    
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, g:visualstudio_terminalencoding, &encoding)
    exe 'e '.l:temp
endfunction

function! visualstudio#open_file()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" run {{{
function! visualstudio#run(runType)
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("run", "-t", currentfilefullpath)
    if a:runType == 1
        let l:cmd = s:visualstudio_make_command("debugrun", "-t", currentfilefullpath)
    endif
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

"" find {{{
function! s:visualstudio_save_find_result(findType)
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getfindresult1", "-t", currentfilefullpath)
    if a:findType == 1
        let l:cmd = s:visualstudio_make_command("getfindresult2", "-t", currentfilefullpath)
    endif
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, g:visualstudio_terminalencoding, &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_findresultfilepath)
endfunction

function! visualstudio#open_find_result(findType)
    :call s:visualstudio_save_find_result(a:findType)
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'setlocal errorformat='.g:visualstudio_findformat
    exe 'cfile '.g:visualstudio_findresultfilepath
endfunction

""}}}


"other {{{
function! s:visualstudio_save_output(target)
    let l:currentfilefullpath = a:target == "" ? s:visualstudio_get_current_buffer_fullpath() : a:target
    let l:cmd = s:visualstudio_make_command("getoutput", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, g:visualstudio_terminalencoding, &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_outputfilepath)
endfunction

function! s:visualstudio_save_error_list(target)
    let l:currentfilefullpath = a:target == "" ? s:visualstudio_get_current_buffer_fullpath() : a:target
    let l:cmd = s:visualstudio_make_command("geterrorlist", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = iconv(s:visualstudio_temp_result, g:visualstudio_terminalencoding, &encoding)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_errorlistfilepath)
endfunction

function! visualstudio#open_output(...)
    "またないと正確に値が取れない時がある...orz
    sleep 500m
    :call s:visualstudio_save_output(a:0 ? a:0 : "")
    let &errorformat = g:visualstudio_errorformat
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'cfile '.g:visualstudio_outputfilepath
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

function! visualstudio#open_error_list(...)
    sleep 500m
    :call s:visualstudio_save_error_list(a:0 ? a:0 : "")
    let &errorformat = g:visualstudio_errorlistformat
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'cfile '.g:visualstudio_errorlistfilepath
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

function! visualstudio#add_break_point()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let linenum = line(".")
    let l:cmd = s:visualstudio_make_command("addbreakpoint", "-t", currentfilefullpath, "-f", currentfilefullpath, "-line", linenum)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction


function! visualstudio#set_build_config()

endfunction

function! visualstudio#set_build_platform()
endfunction

"}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

