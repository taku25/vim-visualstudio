# vim-visualstudio  

## Description
plugin operates Vim to VisualStudio

![image](https://dl.dropboxusercontent.com/u/45602523/vim-visualstudio.gif)

## Operation has been confirmed in:
* gVim version kaoriya 7.3xx 32bit & 64bit
* gVim version kaoriya 7.4xx 32bit & 64bit

## Installation
### Manually
1. Put all files under $VIM.

### Pathogen
1. Install with the following command.

        git clone https://github.com/taku25/vim-visualstudio ~/.vim/bundle/vim-visualstudio

### Vundle (https://github.com/gmarik/vundle)
1. Add the following configuration to your `.vimrc`.

        Bundle 'taku25/vim-visualstudio'

2. Install with `:BundleInstall`.

### NeoBundle (https://github.com/Shougo/neobundle.vim)
1. Add the following configuration to your `.vimrc`.

        NeoBundle 'taku25/vim-visualstudio'

2. Install with `:NeoBundleInstall`.

### Requirements:
####VisualStudioController
##### Manually
1. Dowanload from "https://github.com/taku25/VisualStudioController" to VisualStudioController.zip

2. Set VisualStudioController path .vimrc or .gvimrc

        let g:visualstudio_controllerpath = xxx(default value is VisualStudioController.exe)

##### Git
1. Install with the following command.

        git clone https://github.com/taku25/VisualStudioController xxxxx(user folder)

2. Set VisualStudioController path .vimrc or .gvimrc

        let g:visualstudio_controllerpath = xxx(default value is VisualStudioController.exe)

### Recommends:
####Vimproc
you will be able to run asynchronously search and build  
https://github.com/Shougo/vimproc.vim

####unite.vim
You can browse the file in a solution now using unite.  
https://github.com/Shougo/unite.vim

  ![image](https://dl.dropboxusercontent.com/u/45602523/vim-visualstudio_unite.gif)

## Tips
If you want to jump to the parts with error by using the quickfix,  
please set the "/ FC" option to the compilation settings of VisualStudio

  **http://msdn.microsoft.com/library/027c4t2s.aspxx**  


