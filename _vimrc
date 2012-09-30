set nocompatible
filetype off
 
if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
    call neobundle#rc(expand('~/.vim/bundle/'))
endif
 
NeoBundle 'Shougo/neobundle.vim'
 
" Color Scheme
NeoBundle 'altercation/vim-colors-solarized'
 
filetype plugin on
filetype indent on
 
 
" Color Scheme Configure:
syntax enable
set background=light
let g:solarized_termcolors=256
colorscheme solarized
