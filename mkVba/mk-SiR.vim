"=============================================================================
" $Id$
" File:		mk-SiR.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" License:      GPLv3 with exceptions
"               <URL:http://code.google.com/p/lh-vim/wiki/License>
" Version:	3.0.3
let s:version = '3.0.3'
" Created:	06th Nov 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
cd <sfile>:p:h
try 
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '22,$MkVimball! searchInRuntime-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
doc/searchInRuntime.txt
plugin/searchInRuntime.vim
