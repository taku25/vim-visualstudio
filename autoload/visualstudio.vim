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
let s:visualstudio_last_find_result_location = ""
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

        if a:checkType == "build"
            call visualstudio#open_output(shellescape(s:visualstudio_last_target_solution_fullpath))
        elseif a:checkType == "find"
            call visualstudio#open_find_result(s:visualstudio_last_find_result_location == "one" ? 0 : 1, shellescape(s:visualstudio_last_target_solution_fullpath))
        endif
        
        let s:visualstudio_last_target_solution_fullpath = "" 
        let s:visualstudio_last_find_result_location = "" 
    endif
endfunction


" compile & build "{{{
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
                let l:tempcmd = s:visualstudio_make_command("getsolutionfullpath", "-t", l:currentfilefullpath)
                let l:temp_result = s:visualstudio_system(l:tempcmd)
                let l:solutionfullpath = s:vital_datastring.chop(s:visualstudio_convert_encoding(l:temp_result))
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

function! visualstudio#compile_file(wait)
    let l:currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("compilefile", "-t", l:currentfilefullpath, "-f", l:currentfilefullpath, a:wait)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    if a:wait != "" && g:visualstudio_showautooutput==1
        call visualstudio#open_output(l:currentfilefullpath)
    endif
endfunction
                    

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
"}}}



" open & get file {{{
function! visualstudio#get_current_file(...)
    let l:cmd = s:visualstudio_make_command("getfile")
    if a:0
        let l:cmd = s:visualstudio_make_command("getfile", "-t", a:1)
    endif
    
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    exe 'e '.l:temp
endfunction

function! visualstudio#open_file()
    let currentfilefullpath = s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("openfile", "-t", currentfilefullpath, "-f", currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction
"}}}

" run {{{
function! visualstudio#run(runType, ...)
    let l:currentfilefullpath = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("run", "-t", l:currentfilefullpath)
    if a:runType == 1
        let l:cmd = s:visualstudio_make_command("debugrun", "-t", l:currentfilefullpath)
    endif
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
                                            \ a:wait,
                                            \ "-fl", a:resultLocationType,
                                            \ "-ft", a:findTarget)

    if a:wait == "-w"
        let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
        if g:visualstudio_showautooutput == 1
            call visualstudio#open_find_result(a:resultLocationType == "one" ? 0 : 1, l:target)
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
                let l:temp_result = s:visualstudio_system(l:tempcmd)
                let l:solutionfullpath = s:vital_datastring.chop(s:visualstudio_convert_encoding(l:temp_result))
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


function! s:visualstudio_save_find_result(findType, target)
    let l:currentfilefullpath = a:target != "" ? a:target : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command(a:findType == 0 ? "getfindresult1" : "getfindresult2", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_findresultfilepath)
endfunction

function! visualstudio#open_find_result(findType, ...)
    :call s:visualstudio_save_find_result(a:findType, a:0 ? a:1 : "")
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
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_outputfilepath)
endfunction

function! s:visualstudio_save_error_list(target)
    let l:currentfilefullpath = a:target == "" ? s:visualstudio_get_current_buffer_fullpath() : a:target
    let l:cmd = s:visualstudio_make_command("geterrorlist", "-t", l:currentfilefullpath)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:value = split(l:temp, "\n")
    call writefile(l:value, g:visualstudio_errorlistfilepath)
endfunction

function! visualstudio#open_output(...)
    "またないと正確に値が取れない時がある...orz
    sleep 500m
    :call s:visualstudio_save_output(a:0 ? a:1 : "")
    let &errorformat = g:visualstudio_errorformat
    exe 'copen '.g:visualstudio_quickfixheight
    exe 'cfile '.g:visualstudio_outputfilepath
    if g:visualstudio_enableerrormarker == 1
        :doautocmd QuickFixCmdPost make
    endif
endfunction

function! visualstudio#open_error_list(...)
    sleep 500m
    :call s:visualstudio_save_error_list(a:0 ? a:1 : "")
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

function! visualstudio#change_solution_directory(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getsolutiondirectory", "-t", l:target)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let s:visualstudio_temp_result = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let s:visualstudio_temp_result = s:vital_datastring.chop(s:visualstudio_temp_result)        
    echo 'cd '.shellescape(s:visualstudio_temp_result)
endfunction

function! visualstudio#get_all_files(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getallfiles", "-t", l:target)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let s:visualstudio_temp_result = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:temp = s:vital_datastring.lines(s:visualstudio_temp_result)
    return l:temp
endfunction
"}}}

"build config {{{

function! visualstudio#set_build_config(...)
    let l:target = a:0 ? a:1 : s:visualstudio_get_current_buffer_fullpath()
    let l:cmd = s:visualstudio_make_command("getbuildconfiglist", "-t", l:target)
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:configlist = s:vital_datastring.lines(l:temp)
    let l:displaylist = []
    let l:i = 0
    for l:config in l:configlist
        :call add(l:displaylist, (l:i + 1) . '.' . l:config)
        let l:i+=1
    endfor

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
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
    let l:temp = s:visualstudio_convert_encoding(s:visualstudio_temp_result)
    let l:platformlist = s:vital_datastring.lines(l:temp)
    let l:displaylist = []
    let l:i = 0
    for l:platform in l:platformlist
        :call add(l:displaylist, (l:i + 1) . '.' . l:platform)
        let l:i+=1
    endfor

    let l:inputnumber = inputlist(l:displaylist) - 1
    if l:inputnumber < 0 || l:inputnumber > len(l:displaylist)
        return 
    endif
    let l:cmd = s:visualstudio_make_command("setcurrentbuildconfig", "-t", l:target, "-platform", l:platformlist[l:inputnumber] )
    let s:visualstudio_temp_result = s:visualstudio_system(l:cmd)
endfunction

"}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

" vim:foldmethod=marker:fen:

