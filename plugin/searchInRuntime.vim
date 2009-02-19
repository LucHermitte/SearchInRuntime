" ======================================================================
" $Id$
" File:		searchInRuntime.vim 
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
" 		<URL:http://hermitte.free.fr/vim/>
" Last Update:  $Date$
" Version:	2.1.7
"
" Purpose:	Search a file in the runtime path, $PATH, or any other
"               variable, and execute an Ex command on it.
" URL:http://hermitte.free.fr/vim/ressources/vimfiles/plugin/searchInRuntime.vim
" ======================================================================
" History: {{{
"	Version 2.1.7
"	(*) It wasn't able to expand paths on windows because of fnamemodify()
"	that returns '.' instead of an empty string.
"	Version 2.1.6
"	(*) extracts paths from options specifications like "-I/usr/include" or
"	"--option=path"
"	(*) Requires lh#List#Match()
"	Version 2.1.5
"	(*) Use the new lh#path#Simplify(), and lh#path#StripCommon() functions
"	Version 2.1.4
"	(*) Generic code moved to autoload plugins.
"	(*) New command: :Whereis
"	Version 2.1.3
"	(*) Bug fix: regression introduced on gf and CTRL-W_f since bang can be
"	    used on :G*Split (v2.1.2). 
"	(*) Completely different mapping for CTRL-W_v, it may break default
"	    keybinding
"	    => todo option
"	(*) UTF-8 bug fix for :GSplit
"	(*) :GSplit gets rid of doublons
"	Version 2.1.2
"	(*) New behavior for :GSplit and :GVSplit:
"	    If a matching file is already opened in a window, jump to the
"	    window, even if several files match the globing pattern. 
"	(*) Bang for :GSplit and :GVSplit
"	    -> ask which file to jump to even if one is already opened.
"	Version 2.1.1
"	(*) Completion rules fixed for :GSplit and :GVSplit
"	(*) Bug fix: absolute paths (with :G*Split and CTRL-W_f) incorrectly
"	    handled
"	(*) Bug fix: paths with spaces (e.g. c:/Program files/...) were split
"	(*) Bug fix: s:StripCommon() did not stop at directories boundaries 
"	(*) Options to choose the commands for :GSplit and :GVSplit
"	    -> g:sir_goto_hsplit and g:sir_goto_vsplit.
"	(*) gf and CTRL-W_f support UNC paths, URLs, ...
"	Version 2.1.0
"	(*) Select one file from a list of files matching
"	    -> gf, <c-w>f
"	       :GSplit, :GVSplit
"	(*) Bug fix when several parameters were given to |0
"	    -> «SearchInRuntime grepadd *.vim |0 -w aug» is ok now
"	    todo: check if this introduces regressions or not
"
"	Version 2.0.4
"	(*) Bug fixed. The patch from v1.6d was incomplete.
"	    :SearchInVar accepts ':' as path separator in directories lists.
"	Version 2.0.3
"	(*) New command: :Runtime that wraps :runtime, but adds a support for
"	    auto completion.
"	Version 2.0.2
"	(*) New commands: :Sp and :Vsp that (vertically) split open files from
"	    the &path. auto completion supported.
"	Version 2.0.1
"	(*) Autocompletion for commands, paths and variables
"	    (Many thanks to Bertram Scharpf and Hari Krishna Dara on Vim mailing
"	    list for their valuable information)
"
"	Version 1.6d:
"	(*) Bug fixed with non win32 versions of Vim: 
"	    :SearchInPATH accepts ':' as a path separator in $PATH.
"	Version 1.6c:
"	(*) Bug fixed with non win32 versions of Vim: no more
"            %Undefined variable ss
"            %Invalid expression ss
"	Version 1.6b:
"	(*) Minor changes in the comments
"	Version 1.6:
"	(*) :SearchInENV has become :SearchInVar.
"	Version 1.5:
"	(*) The commands passed to the different :SearchIn* commands can
"	    accept any number of arguments before the names of the files found.
"	    To use them, add at the end of the :SearchIn* command: a pipe+0
"	    (' |0 ') and then the list of the other parameters.
"	Version 1.4:
"	(*) Fix a minor problem under Windows when VIM is launched from the
"	    explorer.
"	Version 1.3:
"	(*) The commands passed to the different :SearchIn* commands can
"	    accept any number of arguments after the names of the files found.
"	    To use them, add at the end of the :SearchIn* command: a pipe 
"	    (' | ') and then the list of the other parameters.
"	Version 1.2b:
"	(*) Address obfuscated for spammers
"	Version 1.2:
"	(*) Add continuation lines support ; cf 'cpoptions'
"	Version 1.1:
"	(*) Support the '&verbose' option :
"	     >= 0 -> display 'no file found'.
"	     >= 2 -> display the list of files found.
"	     >= 3 -> display the list of directories searched.
"	(*) SearchInPATH : like SearchInRuntime, but with $PATH
"	(*) SearchInENV : work on any list of directories defined in an
"	    environment variable.
"	(*) Define the classical debug command : Echo
"	(*) Contrary to 'runtime', the search can accept absolute paths ; 
"	    for instance, 
"	    	runtime! /usr/local/share/vim/*.vim 
"	    is not valid while 
"	    	SearchInRuntime source /usr/local/share/vim/*.vim 
"	    is accepted.
"	
"	Version 1.0 : initial version
" }}}
"
" Todo: {{{
" 	(*) Should be able to interpret absolute paths stored in environment
" 	    variables ; e.g: SearchInRuntime Echo $VIM/*vimrc*
" 	(*) Absolute paths should not shortcut the order of the file globing 
" 	    patterns ; see: SearchInENV! $PATH Echo *.sh /usr/local/vim/*
" }}}
"
" Examples: {{{
" 	(*) :SearchInVar $INCLUDE sp vector
" 	    Will (if $INCLUDE is correctly set) open in a |split| window (:sp)
" 	    the C++ header file vector.
"
"    	(*) :let g:include = $INCLUDE
"    	    :SearchInVar g:include Echo *
"	    Will echo the name of all the files present in the directories
"	    specified in $INCLUDE.
"
"	(*) :SearchInRuntime! Echo plugin/*foo*.vim | final arguments
"	    For every file name plugin/*foo*.vim in the 'runtimepath', this
"	    will execute:
"		:Echo {path-to-the-file} final arguments
"
"	(*) :SearchInRuntime! grep plugin/*foo*.vim |0 text
"	    For every file name plugin/*foo*.vim in the 'runtimepath', this
"	    will execute:
"		:grep text {path-to-the-file}
"
"	(*) :SearchInRuntime! source here/foo*.vim 
"	    is equivalent to:
"		:runtime! here/foo*.vim 
"
"	(*) :silent exe 'SearchInRuntime 0r there/that.'.&ft 
"	    Will:
"	    - search the 'runtimepath' list for the first file named
"	    "that.{filetype}" present in the directory "there", 
"	    - and insert it in the current buffer. 
"	    If no file is found, nothing is done. 
"
" }}}
" ========================================================================
" Anti-reinclusion guards                                  {{{1
let s:cpo_save = &cpo
set cpo&vim
if exists("g:loaded_searchInRuntime") 
      \ && !exists('g:force_reload_searchInRuntime')  
  let &cpo = s:cpo_save
  finish 
endif
let g:loaded_searchInRuntime = 1

" Anti-reinclusion guards                                  }}}1
" ========================================================================
" Commands                                                 {{{1

" Generic commands {{{2
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       SearchInRuntime	call <SID>SearchInRuntime("<bang>",  <f-args>)
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       SearchInVar	call <SID>SearchInVar    ("<bang>", <f-args>)
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       SearchInPATH	call <SID>SearchInPATH   ("<bang>", <f-args>)

" Specialized commands {{{2
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       Runtime		:runtime<bang> <args>
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       Split		:SearchInVar<bang> &path sp <args>
command! -nargs=+ -complete=custom,SiRComplete -bang
      \       Vsplit		:SearchInVar<bang> &path vsp <args>
command! -nargs=1 -complete=custom,SiRComplete -bang
      \       Whereis		:echo globpath(&path,'*<args>*')

if !exists('!Echo')
  command! -nargs=+ Echo echo "<args>"
endif

" Mappings and specialized commands for Vim 7+ {{{2
if v:version >= 700
  nnoremap <silent> gf
	\ :call <sid>OpenWith('nobang', 'e', &path, expand('<cfile>'))<cr>
  nnoremap <silent> glf
	\ :echo globpath(&path, expand('<cfile>'))<cr>
  nnoremap <silent> <c-w>f
	\ :call <sid>OpenWith('nobang', 'sp', &path, expand('<cfile>'))<cr>
  nnoremap <silent> <c-w>v
	\ :call <sid>OpenWith('nobang', 'vsp', &path, expand('<cfile>'))<cr>

  " Function: s:Option(name, default [, scope])            {{{3
  " Copy-paste from LHOption()
  function! s:Option(name,default,...)
    " Name prefixed by my initial to avoid clashes wth other plugins.
    let scope = (a:0 == 1) ? a:1 : 'bg'
    let name = a:name
    let i = 0
    while i != strlen(scope)
      if exists(scope[i].':'.name) && (0 != strlen({scope[i]}:{name}))
	return {scope[i]}:{name}
      endif
      let i = i + 1
    endwhile 
    return a:default
  endfunction
  "  }}}3

  let s:cmd0 = 'command! -bang -nargs=+ -complete=custom,SiRComplete '
  let s:cmd1h = s:Option('sir_goto_hsplit', 'GSplit', 'g') 
  let s:cmd1v = s:Option('sir_goto_vsplit', 'VGSplit', 'g') 

  function! s:cmd2(cmd)
    return ' call <sid>OpenWith("<bang>","'.a:cmd.'", &path, <f-args>)'
  endfunction

  exe s:cmd0 . s:cmd1h . s:cmd2('sp')
  exe s:cmd0 . s:cmd1v . s:cmd2('vsp')
endif

" }}}1
" ========================================================================
" Functions                                                {{{1

" Main functions {{{2
" Function: s:ToCommaSeparatedPath({path})     {{{3
function! s:ToCommaSeparatedPath(path)
  let path = substitute(a:path, ';', ',', 'g')
  if !(has('win16') || has('win32') || has('win64') || has('win95'))
    let path = substitute(a:path, ':', ',', 'g')
  endif
  return path
endfunction

" Function: s:SearchIn({do_all}, {cmd}, {rpath}, [{glob}...]) {{{3
function! s:SearchIn(do_all, cmd, rpath, ...)
  " Loop on runtimepath : build the list of files
  if has('win32')
    let ss=&shellslash
    set shellslash
    " because of glob + escape ('\\')
  endif
  let rp = a:rpath
  let f = ''
  let firstTime = 1
  let params0 = '' | let params = '' 
  while strlen(rp) != 0
    let r  = matchstr(rp, '^[^,]*' )."/"
    let rp = substitute(rp, '.\{-}\(,\|$\)', '', '')
    if &verbose >= 3 | echo "Directory searched: [" . r. "]\n" | endif
      
    " Loop on arguments
    let params0 = '' | let params = '' 
    let i = 1
    while i <= a:0
      if a:{i} =~? '^\(/\|[a-z]:[\\/]\)' " absolute path
	if firstTime
	  if &verbose >= 3 | echo "Absolute path : [" . glob(a:{i}). "]\n" | endif
	  let f = f . glob(a:{i}) . "\n"
	endif
      elseif a:{i} == "|0"	" Other parameters
	let i = i + 1
	while i <= a:0
	  let params0 = params0 . ' ' . a:{i}
	  let i = i + 1
	endwhile
      elseif a:{i} == "|"	" Other parameters
	let i = i + 1
	while i <= a:0
	  let params = params . ' ' . a:{i}
	  let i = i + 1
	endwhile
      else
	let f = f . glob(r.a:{i}). "\n"
	"echo a:{i} . " -- " . glob(r.a:{i})."\n"
	"echo a:{i} . " -- " . f."\n"
      endif
      let i = i + 1
    endwhile
    let firstTime = 0
  endwhile
  if has('win32')
    let &shellslash=ss
  endif
  " correct the params
  let params0 = escape(params0, "\\\t")
  let params = escape(params, "\\\t")
  " Execute the command on the matching files
  let foundOne = 0
  while strlen(f) != 0
    let ff = matchstr(f, "^[^\n]*")
    let f  = substitute(f, '.\{-}\('."\n".'\|$\)', '', '')
    if filereadable(ff)
      if     &verbose >= 3 
	echo "Action on: [" . ff . "] (".params0.'/'.params.")\n"
      elseif &verbose >= 2 
	echo "Action on: [" . ff . "]\n" 
      endif
      " echo a:cmd.params0." ".escape(ff, "\\ \t").params
      exe a:cmd.params0." ".escape(ff, "\\ \t").params
      if !a:do_all | return | endif
      let foundOne = 1
    endif
  endwhile
  if &verbose > 0 && !foundOne " {{{
    let msg = "not found : « "
    let i = 1
    while i <= a:0
      let msg = msg. a:{i} . " "
      let i = i + 1
    endwhile
    echo msg."»"
  endif " }}}
endfunction

" Function: s:SearchInRuntime({bang}, {cmd}, [{glob-pat}]) {{{3
function! s:SearchInRuntime(bang, cmd, ...)
  let do_all = a:bang == "!"
  let i = 1
  let a = ''
  while i <= a:0
    let a = a.",'".escape(a:{i}, "\\ \t")."'"
    let i = i + 1
  endwhile
  exe 'call <sid>SearchIn(do_all, a:cmd, &runtimepath' .a.')'
endfunction

" Function: :s:SearchInPATH({bang}, {cmd}, [{glob-pat}]) {{{3
function! s:SearchInPATH(bang, cmd, ...)
  " momentarally deactive &wildignore
  let do_all = a:bang == "!"
  let i = 1
  let a = ''
  while i <= a:0
    " let a = a.",'".a:{i}."'"
    " let a = a.",'".escape(a:{i}, '\ ')."'"
    let a = a.",'".escape(a:{i}, "\\ \t")."'"
    let i = i + 1
  endwhile
  let p = substitute($PATH, ';', ',', 'g')
  let p = s:ToCommaSeparatedPath(p)
  let s_wildgnore = &wildignore
  set wildignore&vim
  try
    exe "call <sid>SearchIn(do_all, a:cmd,'". p ."'".a.")"
  finally
    let &wildignore = s_wildgnore
  endtry
endfunction

" Function: :s:SearchInVar({bang}, {cmd}, [{glob-pat}]) {{{3
function! s:SearchInVar(bang, env, cmd, ...)
  let do_all = a:bang == "!"
  let i = 1
  let a = ''
  while i <= a:0
    " let a = a.",'".a:{i}."'"
    " let a = a.",'".escape(a:{i}, '\ ')."'"
    let a = a.",'".escape(a:{i}, "\\ \t")."'"
    let i = i + 1
  endwhile
  exe "let p = substitute(".a:env.", ';', ',', 'g')"
  let p = s:ToCommaSeparatedPath(p)
  exe "call <sid>SearchIn(do_all, a:cmd,'". p ."'".a.")"
endfunction

" Functions for vim7 only {{{2

if v:version >= 700

" Function: s:SelectOne({ask_even_if_already_opened}, {path}, {glob-patterns}) {{{3
" All globbing pattern all matched against the {path}, if several files
" are found, a confirm dialog box will ask to select one file only.
" NB: on some systems, we may be interrested in setting:
"   :set guioptions+=c
function! s:SelectOne(ask_even_if_already_opened, path, gpatterns)
  " Get all the matching files
  let matches = []
  let i = 0
  while i < len(a:gpatterns)
    if lh#path#IsAbsolutePath(a:gpatterns[i])
	  \ || lh#path#IsURL(a:gpatterns[i])
      let matches += [ a:gpatterns[i] ]
    else
    let m = lh#path#GlobAsList(a:path, a:gpatterns[i])
    call extend (matches, m)
    endif
    let i = i + 1
  endwhile

  " Get rid of doublons
  call map (matches, 'lh#path#Simplify(v:val)')
  call sort(matches)
  "     uniq...
  let i = 1
  while i < len(matches)
    if matches[i-1] == matches[i]
      call remove(matches, i)
    else
      let i = i + 1
    endif
  endwhile

  if len(matches) > 1
    if !a:ask_even_if_already_opened
      " Try to see if a matching buffer is aready opened
      " If so, jump to it.
      " @todo: if several match, then ask from the restricted list of matching
      " buffers....
      let i = 0
      while i != len(matches)
	if lh#buffer#Find(matches[i]) != -1 | return '' | endif
	let i = i + 1
      endwhile
      " No matching opened buffer found.
    endif
    let simpl_matches = deepcopy(matches) 
    let simpl_matches = lh#path#StripCommon(simpl_matches)
    let simpl_matches = [ '&Cancel' ] + simpl_matches
    " Consider guioptions+=c is case of difficulties with the gui
    let selection = confirm('Select file to open:', join(simpl_matches,"\n"), 1, 'Question')
    let file = (selection == 1) ? '' : matches[selection-2]
  elseif len(matches) == 0
    let file = ''
  else
    let file = matches[0]
  endif
  return file
endfunction

" Function: s:OpenWith({bang}, {cmd}, {path}, {glob-patterns}) {{{3
" Select only one file that matches {path} +  {glob-patterns}. Then
" apply the opening command {cmd} on the resulting file.
" If the {glob-pattern} has the form "-[a-zA-Z0-9]{path}", or "--\w\+={path}",
" the file will be searched without the leading part. (The rationale behind
" this feature comes from compiler options like -I/usr/include)
" NB: If the result file is already opened in a window, this window
" becomes the active window. Otherwise, {cmd} is applied. Typical values
" for {cmd} are "sp", "e", ...
let s:k_pattern = '^-\([a-zA-Z0-9]\|-\w\+=\)'
function! s:OpenWith(bang, cmd, path, ...)
  let file = s:DoOpenWith(a:bang, a:cmd, a:path, a:000)
  if strlen(file) == 0 && lh#list#Match(a:000, s:k_pattern) != -1
    let a000 = deepcopy(a:000)
    call map(a000, 'substitute(v:val, s:k_pattern, "", "g")')
    echomsg string(a000)
    let file = s:DoOpenWith(a:bang, a:cmd, a:path, a000)
  endif
  if strlen(file) == 0 
    echohl WarningMsg
    echomsg "No file found for ".string(a:000)
    echohl None
    return
  endif
  if lh#buffer#Find(file) != -1 | return | endif
  exe a:cmd . ' '.file
endfunction

" Function: s:DoOpenWith({bang}, {cmd}, {path}, {glob-patterns}) {{{4
" Internal function used by s:OpenWith()
function! s:DoOpenWith(bang, cmd, path, a000)
  let ask_even_if_already_opened = a:bang == "!"
  let file = s:SelectOne(ask_even_if_already_opened, a:path, a:a000)
  return file
endfunction

endif " version >= 700

" Auto-completion                                {{{2
" Note: the completion cannot expand with different leading data
" SiRComplete(ArgLead,CmdLine,CursorPos)                   {{{3
let s:commands = '^SearchIn\S\+\|^V\=[Ss]p\%[lit]\|^Ru\%[ntime]\|^W\%[hereis]'
let s:split_commands = '^V\=[Ss]p\%[lit]$'
if exists('s:cmd1h')
  " With Vim 7+, there is a support for customizable split commands  
  let s:cmd1h_pat = substitute(s:cmd1h, '^\(.\)\(.\+\)$', '\1\\%[\2]', '') 
  let s:cmd1v_pat = substitute(s:cmd1v, '^\(.\)\(.\+\)$', '\1\\%[\2]', '') 

  let s:commands = s:commands . '\|^'.s:cmd1h_pat.'\|^'.s:cmd1v_pat
  let s:split_commands = s:split_commands . '\|^'.s:cmd1h_pat.'$\|^'.s:cmd1v_pat.'$'
endif

function! SiRComplete(ArgLead, CmdLine, CursorPos)
  let cmd = matchstr(a:CmdLine, s:commands)
  let cmdpat = '^'.cmd

  let tmp = substitute(a:CmdLine, '\s*\S\+', 'Z', 'g')
  let pos = strlen(tmp)
  let lCmdLine = strlen(a:CmdLine)
  let fromLast = strlen(a:ArgLead) + a:CursorPos - lCmdLine 
  " The argument to expand, but cut where the cursor is
  let ArgLead = strpart(a:ArgLead, 0, fromLast )
  if 0
    call confirm( "a:AL = ". a:ArgLead."\nAl  = ".ArgLead
	  \ . "\nx=" . fromLast
	  \ . "\ncut = ".strpart(a:CmdLine, a:CursorPos)
	  \ . "\nCL = ". a:CmdLine."\nCP = ".a:CursorPos
	  \ . "\ntmp = ".tmp."\npos = ".pos
	  \, '&Ok', 1)
  endif
  
  " let delta = ('SearchInVar'==cmd) ? 1 : 0
  if     'SearchInVar' == cmd
    let delta = 1
  elseif cmd =~ s:split_commands
    return s:FindMatchingFiles(&path, ArgLead)
  elseif cmd =~ '^Ru\%[ntime]$'
    return s:FindMatchingFiles(&runtimepath, ArgLead)
  elseif cmd =~ '^W\%[hereis]$'
    return s:FindMatchingFiles(&path, ArgLead)
  else 
    let delta = 0
  endif

  if     1+delta == pos
    " First argument for :SearchInVar -> variable
    return s:FindMatchingVariable(ArgLead)
  elseif 2+delta == pos
    " First argument: a command
    return s:MatchingCommands(ArgLead)
  elseif 3+delta <= pos
    if     cmd =~ 'SearchInPATH!\='
      let path = $PATH
    elseif cmd =~ 'SearchInRuntime!\='
      let path = &rtp
    elseif cmd =~ 'SearchInVar!\='
      let path = matchstr(a:CmdLine, '\S\+\s\+\zs\S\+\ze.*')
      exe "let path = ".path
    endif
    return s:FindMatchingFiles(path, ArgLead)
  endif
  " finally: unknown
  echoerr cmd.': unexpected parameter ``'. a:ArgLead ."''"
  return ''

endfunction

" s:MatchingCommands(ArgLead)                              {{{3
" return the list of custom commands starting by {FirstLetters}
"
if v:version > 603 || v:version == 603 && has('patch011') 
  " should be the required version
  function! s:MatchingCommands(ArgLead)
    silent! exe "norm! :".a:ArgLead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
    let cmds = substitute(cmds, '\s\+', '\n', 'g')
    return cmds
  endfunction

else
  " Thislimited version works with older version of vim, but only return custom
  " commands
  function! s:MatchingCommands(ArgLead)
    let a_save=@a
    silent! redir @a
    silent! exe 'command '.a:ArgLead
    redir END
    let cmds = @a
    let @a = a_save
    let pat = '\%(^\|\n\)\s\+\(\S\+\).\{-}\ze\(\n\|$\)'
    let cmds=substitute(cmds, pat, '\1\2', 'g')
    return cmds
  endfunction
endif

function! s:MatchingCommandsOld(ArgLead) " {{{4
  "
  " a- First approach
  " let a_save=@a
  " silent! redir @a
  " silent! exe 'command '.a:ArgLead
  " redir END
  " let cmds = @a
  " let @a = a_save
  "
  " b- second approach
  " silent! exe "norm! :".a:ArgLead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
  "
  " c- genutils' approach
  command! -complete=command -nargs=* CMD :echo '<arg>'
  " let a_save=@a
  " silent! redir @a
  " silent! exec "norm! :".a:ArgLead."\<c-A>\"\<Home>echo\ \"\<cr>"
  " silent! exec "normal! :CMD ".a:ArgLead."\<c-A>\<cr>"
  " redir END
  " let cmds = @a
  " let @a = a_save
  let cmds = GetVimCmdOutput("normal! :CMD ".a:ArgLead."\<C-A>\<CR>")

  let cmds = substitute(cmds, '\s\+', '\n', 'g')
  
  " let pat = '\%(^\|\n\)\s\+\(\S\+\).\{-}\ze\(\n\|$\)'
  " let cmds=substitute(cmds, pat, '\1\2', 'g')

  return cmds
endfunction

" s:FindMatchingFiles(path,ArgLead)                        {{{3
function! s:FindMatchingFiles(pathsList, ArgLead)
  " Convert the paths list to be compatible with globpath()
  let pathsList = s:ToCommaSeparatedPath(a:pathsList)
  let ArgLead = a:ArgLead
  " If there is no '*' in the ArgLead, append it
  if -1 == stridx(ArgLead, '*')
    let ArgLead = ArgLead . '*'
  endif
  " Get the matching paths
  let paths = globpath(pathsList, ArgLead)

  " Build the result list of matching paths
  let result = ''
  while strlen(paths)
    let p     = matchstr(paths, "[^\n]*")
    let paths = matchstr(paths, "[^\n]*\n\\zs.*")
    let sl = isdirectory(p) ? '/' : '' " use shellslash
    let p     = fnamemodify(p, ':t') . sl
    if strlen(p) && (!strlen(result) || (result !~ '.*'.p.'.*'))
      " Append the matching path is not already in the result list
      let result = result . (strlen(result) ? "\n" : '') . p
    endif
  endwhile

  " Add the leading path as it has been stripped by fnamemodify
  let lead = fnamemodify(ArgLead, ':h') . '/'
  let lead = substitute(lead, '^.[/\\]', '', '') " fnamemodify may returns '.' on windows ...
  if strlen(lead) > 1
    let result = substitute(result, '\(^\|\n\)', '\1'.lead, 'g')
  endif

  " Return the list of paths matching a:ArgLead
  return result
endfunction

" s:FindMatchingVariable(ArgLead)                          {{{3

if v:version > 603 || v:version == 603 && has('patch011') 
  " should be the required version
  function! s:FindMatchingVariable(ArgLead)
    if     a:ArgLead[0] == '$'
      command! -complete=environment -nargs=* FindVariable :echo '<arg>'
      let ArgLead = strpart(a:ArgLead, 1)
    elseif a:ArgLead[0] == '&'
      command! -complete=option -nargs=* FindVariable :echo '<arg>'
      let ArgLead = strpart(a:ArgLead, 1)
    else
      command! -complete=expression -nargs=* FindVariable :echo '<arg>'
      let ArgLead = a:ArgLead
    endif

    silent! exe "norm! :FindVariable ".ArgLead."\<c-a>\"\<home>let\ cmds=\"\<cr>"
    if a:ArgLead[0] =~ '[$&]'
      let cmds = substitute(cmds, '\<\S', escape(a:ArgLead[0], '&').'&', 'g')
    endif
    let cmds = substitute(cmds, '\s\+', '\n', 'g')
    let g:cmds = cmds
    return cmds
    " delc FindVariable
  endfunction

else
  function! s:FindMatchingVariable(ArgLead)
    return ''
  endfunction
endif


" }}}1
let &cpo = s:cpo_save
" ========================================================================
" vim60: set foldmethod=marker:
