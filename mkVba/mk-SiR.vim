"=============================================================================
" $Id$
" File:		mk-SiR.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	2.1.6
" Created:	06th Nov 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
cd <sfile>:p:h
15,$MkVimball! searchInRuntime
set modifiable
set buftype=
finish
doc/searchInRuntime.txt
plugin/searchInRuntime.vim
