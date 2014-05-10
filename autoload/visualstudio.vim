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
let s:visualstudio_last_target_solution_fullpath = ""
let s:visualstudio_last_find_result_location = 0
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

    let l:result = ""
    if l:enableVimproc == 1
        let l:result = vimproc#system(a:command)
    else
        let l:result = system(a:command)
    endif

    return s:visualstudio_convert_encoding(l:result)
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

function! s:visualstudio_convert_encoding(targetString)
    if g:visualstudio_terminalencoding != "utf-8"
        return iconv(a:targetString, g:visualstudio_terminalencoding, &encoding)
    endif
    return a:targetString
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
    let l:result = shellescape(expand(g:visualstudio_controllerpath)) . " " . a:command . " " . l:nativeargs . " -oe utf8"

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

function! s:visualstudio_clear_process_and_augroup()
    let &updatetime = s:visualstudio_global_update_time
    augroup plugin-visualstudio
        autocmd! 
    augroup END
    try
        call s:vital_processmanager.kill("visualstudio")
    catch
    endtry
endfunction

function! s:visualstudio_check_finished(checkType)
    let l:status = s:vital_processmanager.status("visualstudio")
    if  l:status == 'inactive'
        call s:visualstudio_clear_process_and_augroup()

        echo "check"
        if a:checkType == "build"
            call visualstudio#open_output(shellescape(s:visualstudio_last_target_solution_fullpath))
        elseif a:checkType == "find"
            call visualstudio#open_find_result(s:visualstudio_last_find_result_location, shellescape(s:visualstudio_last_target_solution_fullpath))
        endif
        
        let s:visualstudio_last_target_solution_fullpath = "" 
        let s:visualstudio_last_find_result_location = 0 
    endif
endfunction

function! s:visualstudio_make_user_select_list(targetlist)
    let displaylist = []
    let l:i = 0
    for l:target in a:targetlist
        :call add(displaylist, (l:i + 1) . '.' . l:target)
        let l:i+=1
    endfor
    return displaylist
endfunction


" compile & build "{{{

" build {{{
function! visualstudio#build(buildtype, wait)
    let l:currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command(a:buildtype, "-t", l:currentfilefullpath, a:wait == 0 ? "" : "-w")
    
    if a:wait == 1
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
                let l:tempcmd = s:visualstudio_make_command("getsolutionfullpath", "-t", l:currentfilefullpath)
                let l:solutionfullpath = s:vital_datastring.chop(s:visualstudio_system(l:tempcmd))
                if s:visualstudio_last_target_solution_fullpath == l:solutionfullpath
                    "同じsolutionをビルドなら前のを消しておく
                    call visualstudio#cancel_build(l:solutionfullpath)
                    call s:visualstudio_clear_process_and_augroup()
                endif
                let s:visualstudio_last_target_solution_fullpath = l:solutionfullpath
                "プロセス監視のため起動waitをつけて起動する
                call s:vital_processmanager.touch("visualstudio", l:cmd . " -w")
                let &updatetime = g:visualstudio_updatetime
                augroup plugin-visualstudio
                    execute 'autocmd! CursorHold,CursorHoldI * call' 's:visualstudio_check_finished("build")'
                augroup END
            endif
        endif
    endif
endfunction

function! visualstudio#compile(wait, ...)
    let l:currentfilefullpath = a:0 != 0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("compilefile", "-t", l:currentfilefullpath, "-f", l:currentfilefullpath, a:wait == 0 ? "" : "-w")
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    if a:wait == 1 && g:visualstudio_showautooutput==1
        call visualstudio#open_output(l:currentfilefullpath)
    endif
endfunction                  
" }}}

"  cancel {{{
function! visualstudio#cancel_build(...)
    let l:currentfilefullpath = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath() 
    let l:cmd = s:visualstudio_make_command("cancelbuild", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" clean {{{
function! visualstudio#clean_solution(...)
    let l:currentfilefullpath = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath() 
    let l:cmd = s:visualstudio_make_command("clean", "-t", l:currentfilefullpath )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

"build config {{{

function! visualstudio#set_build_config(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getbuildconfiglist", "-t", l:target)
    let l:temp = s:visualstudio_system(l:cmd)
    let l:configlist = s:vital_datastring.lines(l:temp)
    let l:displaylist = s:visualstudio_make_user_select_list(l:configlist)

    let l:inputnumber = inputlist(l:displaylist) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displaylist)
        return 
    endif
    let l:cmd = s:visualstudio_make_command("setcurrentbuildconfig", "-t", l:target, "-buildconfig", l:configlist[l:inputnumber] )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)

endfunction

function! visualstudio#set_build_platform(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getplatformlist", "-t", l:target)
    let l:temp = s:visualstudio_system(l:cmd)
    let l:platformlist = s:vital_datastring.lines(l:temp)
    let l:displaylist = s:visualstudio_make_user_select_list(l:platformlist)

    let l:inputnumber = inputlist(l:displaylist) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displaylist)
        return 
    endif
    let l:cmd = s:visualstudio_make_command("setcurrentbuildconfig", "-t", l:target, "-platform", l:platformlist[l:inputnumber] )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction

"}}}
"}}}



" open & get file {{{
function! visualstudio#get_current_file(...)
    let l:cmd = s:visualstudio_make_command("getcurrentfileinfo", a:0 ? ("-t " . a:1) : "")
    let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))        
    exe 'e '. s:vital_datastring.replace(l:value[0], "Name=", "")
endfunction

function! visualstudio#open_file()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" run & stop {{{
function! visualstudio#run(runType, ...)
    let l:currentfilefullpath = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command(a:runType == 0 ? "run" : "debugrun", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction

function! visualstudio#stop_debug_run(...)
    let l:currentfilefullpath = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("stopdebugrun", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction

function! visualstudio#set_startup_project(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getprojectlist", "-t", l:target)
    let l:temp = s:visualstudio_system(l:cmd)
    let l:projectlist = s:vital_datastring.lines(l:temp)
    let l:displaylist = s:visualstudio_make_user_select_list(l:projectlist)

    let l:inputnumber = inputlist(l:displaylist) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displaylist)
        return 
    endif
    let l:cmd = s:visualstudio_make_command("setstartupproject", "-t", l:target, "-p", l:projectlist[l:inputnumber] )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

"find {{{
function! visualstudio#find(findTarget, resultLocationType, wait, ...)
    if a:0 == 0
        echo "Please set a search word"
        return
    endif
    
    let l:target = a:0 == 2 ? a:2 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("find", "-t", l:target,
                                            \ "-fw", a:1,
                                            \ a:wait == 0 ? "" : "-w",
                                            \ "-fl", a:resultLocationType == 0 ? "one" : "two",
                                            \ "-ft", a:findTarget)

    if a:wait == 1
        let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
        if g:visualstudio_showautooutput == 1
            call visualstudio#open_find_result(a:resultLocationType, l:target)
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
                let l:tempcmd = s:visualstudio_make_command("getsolutionfullpath", "-t", l:target)
                let l:solutionfullpath = s:vital_datastring.chop(s:visualstudio_system(l:tempcmd))
                if s:visualstudio_last_target_solution_fullpath == l:solutionfullpath
                    call s:visualstudio_clear_process_and_augroup()
                endif
                let s:visualstudio_last_target_solution_fullpath = l:solutionfullpath
                let s:visualstudio_last_find_result_location = a:resultLocationType
                "起動
                call s:vital_processmanager.touch("visualstudio", l:cmd . " -w")
                let &updatetime = g:visualstudio_updatetime
                augroup plugin-visualstudio
                    execute 'autocmd! CursorHold,CursorHoldI * call' 's:visualstudio_check_finished("find")'
                augroup END
            endif
        endif
    endif
endfunction


function! visualstudio#open_find_result(findType, ...)
    let l:currentfilefullpath = a:0 != 0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command(a:findType == 0 ? "getfindresult1" : "getfindresult2", "-t", l:currentfilefullpath)
    let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))        
    let &errorformat = g:visualstudio_findformat
    cgetexpr l:value
    exe 'copen '.g:visualstudio_quickfixheight
endfunction

""}}}


"other {{{

function! visualstudio#open_output(...)
    sleep 500m
    let l:currentfilefullpath = a:0 != 0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getoutput", "-t", l:currentfilefullpath)
    let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))        
    let &errorformat = g:visualstudio_errorformat
    cgetexpr l:value
    exe 'copen '.g:visualstudio_quickfixheight
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

function! visualstudio#open_error_list(...)
    sleep 500m
    let l:currentfilefullpath = a:0 != 0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("geterrorlist", "-t", l:currentfilefullpath)
    let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))        
    let &errorformat = g:visualstudio_errorlistformat
    cgetexpr l:value
    exe 'copen '.g:visualstudio_quickfixheight
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

function! visualstudio#go_to_definition()
    let l:currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getlanguagetype", "-t ", l:currentfilefullpath, "-f", l:currentfilefullpath)
    let l:languagetype = s:vital_datastring.chop(s:visualstudio_system(l:cmd))

    let l:pos = getpos(".")
    let l:cmd = s:visualstudio_make_command("gotodefinition",
                                            \ "-t", l:currentfilefullpath,
                                            \ "-f", l:currentfilefullpath,
                                            \ "-l", l:pos[1], "-c", l:pos[2],
                                            \ "-fw", expand('<cword>'))
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)

    if l:languagetype == "CSharp"
        let l:cmd = s:visualstudio_make_command("getcurrentfileinfo", "-t ", l:currentfilefullpath)
        let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))
        let l:filename = s:vital_datastring.replace(l:value[0], "Name=", "")
        let l:line = s:vital_datastring.replace(l:value[2], "Line=", "")
        let l:column = s:vital_datastring.replace(l:value[3], "Column=", "")
        exe 'e '. l:filename
        call cursor(l:line, l:column)
        
    elseif l:languagetype == "CPlusPlus"
        let l:cmd = s:visualstudio_make_command("getfindsymbolresult", "-t ", l:currentfilefullpath)
        let l:value = s:vital_datastring.lines(s:visualstudio_system(l:cmd))
        let &errorformat = g:visualstudio_findformat
        cgetexpr l:value
        exe 'copen '.g:visualstudio_quickfixheight

    else

    endif

endfunction

function! visualstudio#change_directory(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getsolutiondirectory", "-t", l:target)
    let s:visualstudio_temp_result = s:vital_datastring.chop(s:visualstudio_system(l:cmd))        
    echo 'cd '.shellescape(s:visualstudio_temp_result)
endfunction

function! visualstudio#get_all_files(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getallfiles", "-t", l:target)
    let l:temp = s:vital_datastring.lines(s:visualstudio_system(l:cmd))
    return l:temp
endfunction



"}}}



" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

