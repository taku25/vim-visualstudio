#vim-visualstudio  

##説明
VimからVisualStudioに対しての操作を行うプラグイン

##参考
同じようなプラグインで  
visual_studio.vim  
というプラグインもあるのですがvisual_studioはもう何年も更新がされていないのと  
pythonを使用していのもあり環境にはよって2.7 & 3.0系の縛りで使用できなかったり  
winextention周りで32 & 64bitなどの問題が発生してしまう可能性があります  
    
このvim-visualstudioプラグインではできるだけそういう他の環境に依存しないように作成したつもりです

##用途 & 目的
1.Vimでソースファイル編集  
↓  
2.VisualStudioでBuildコンパイルエラー確認  
↓  
3.Vimに戻りエラー行に行き修正  
↓  
4.以下コンパイルラーがなくなるまで2と3を繰り返す  
という作業をいかにVimから出ることなく行うか?ということを目的に作成されたプラグインです  

##動作確認 & 必要外部Exe
* kaoriya版gVim  7.3 32bit & 64bit 
* Windows 7 32bit / 64 bit
* 要 vimproc
 * 最新のKaoriya版gVimには標準で入っています
* 要 VisualStudioController.exe
 * パスが通っているディレクトリかg:visualstudio_controllerpathでフルパス指定  
 * https://github.com/taku25/VisualStudioController  

##インストール
* NeoBundle 'taku25/vim-visualstudio'  
または  
* https://github.com/taku25/vim-visualstudio  
からダウンロードして解凍してでてきたvim-visualstudio.vimを
個々の環境のpluginフォルダにコピー

##機能
###version 2013/5/24現在
* VisualStudioで編集中のファイルをVimで開く
* Vimで編集中のファイルをVisualStudioで開く
* VisualStudioで編集中のソリューションに含まれているファイルをVim上で編集していた場合
 * ソリューションのビルド
 * ソリューションのリビルド
 * ソリューションのクリーン
 * Vim上で編集中のファイルのみコンパイル
 * ビルド,リビルド,クリーン&コンパイルの結果を表示
 * 検索結果1の表示
 * 検索結果2の表示
 * Error一覧の表示  
       **要VisualStudio2005以上**
 * 編集中のファイルのカーソルがある行にBreakPointの追加


##コマンド
* VSGet  
VisualStudioで編集中のカレントのファイルをVimで開く  
  引数として Solution名を設定することができます  
  またSolution名は先頭からの一部でも大丈夫です  

* VSOpenFile  
Vimで編集中のファイルをVisualStudioで開く

* VSAddBreakPoint  
Vimで編集中のファイルのカーソルがある行にブレイクポイントを設定します  

* VSBuild or VSBuildNoWait  
Vimで編集中のファイルを含むVisualStudioをビルドします  
NoWait付きのものはコマンドの完了を待ちません

* VSReBuild or VSReBuildNoWait  
Vimで編集中のファイルを含むVisualStudioをリビルドします  
NoWait付きのものはコマンドの完了を待ちません

* VSClean or VSCleanNoWait  
Vimで編集中のファイルを含むVisualStudioをクリーンします  
NoWait付きのものはコマンドの完了を待ちません

* VSCompile or VSCompileNoWait  
Vimで編集中のファイルを含むVisualStudioをコンパイルします  
NoWait付きのものはコマンドの完了を待ちません

* VSErorrList  
Vimで編集中のファイルを含むVisualStudioのエラー一覧をqickfixに表示します

* VSOutput  
Vimで編集中のファイルを含むVisualStudioの出力をqickfixに表示します

* VSFindResult1  
Vimで編集中のファイルを含むVisualStudioの検索結果1をqickfixに表示します

* VSFindResult1  
Vimで編集中のファイルを含むVisualStudioの検索結果1をqickfixに表示します
