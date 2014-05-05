# vim-visualstudio  

## 説明
VimからVisualStudioに対しての操作を行うプラグイン

![image](https://dl.dropboxusercontent.com/u/45602523/vim-visualstudio.gif)

## 参考
同じようなプラグインで
**visual_studio.vim**
というプラグインもあるのですがvisual_studioはもう何年も更新がされていないのと  
pythonを使用していのもあり環境にはよって2.7 & 3.0系の縛りで使用できなかったり  
winextention周りで32 & 64bitなどの問題が発生してしまう可能性があります  
このvim-visualstudioプラグインではできるだけそういう他の環境に依存しないように作成したつもりです
(依存しているVisualStudioController.exeはC#とVisualStudio DTE(COM)を使用して作成されていますのでVisualStudioがインストールされていれば動作可能です)

## 用途 & 目的
1.Vimでソースファイル編集  
↓  
2.VisualStudioでBuildコンパイルエラー確認  
↓  
3.Vimに戻りエラー行に行き修正  
↓  
4.以下コンパイルラーがなくなるまで2と3を繰り返す  
という作業をいかにVimから出ることなく行うか?ということを目的に作成されたプラグインです  

## 動作確認 & 必要外部Exe
* kaoriya版gVim  7.3 32bit & 64bit 
* Windows 7 32bit / 64 bit
* 要 VisualStudioController.exe  
  * パスが通っているディレクトリかg:visualstudio_controllerpathでフルパス指定  
  * https://github.com/taku25/VisualStudioController  
* vimprocがインストールされている場合デフォルトでは自動的にvimprocを使用し非同期でbuildなどを実行できるようになります
* VisuaslStudio2005以上  
  **quickfixを使用してエラー個所などにジャンプする場合は VisualStudioのプロジェクト設定で/FCオプションを使用してください**  
  **http://msdn.microsoft.com/ja-jp/library/027c4t2s.aspx**  
* Unite  
  * ソリューションに含まれているファイルを表示できるようになります  

## インストール
* NeoBundle 'taku25/vim-visualstudio'  
または  
* https://github.com/taku25/vim-visualstudio  
からダウンロードして解凍してでてきたvim-visualstudio.vimを
個々の環境のpluginフォルダにコピー

## 機能
### version 2014/5/05現在
 - ソリューションのビルド
 - ソリューションのビルド
 - ソリューションのリビルド
 - ソリューションのクリーン
 - ソリューションのビルドキャンセル
 - ソリューションの実行
 - ソリューションのデバッグ実行
 - ソリューションのデバッグ実行の中断
 - VisualStudioで編集中のファイルをVimで開く
 - Vimで編集中のファイルをVisualStudioで開く
 - ソリューション内での検索
 - プロジェクト内での検索
 - 検索結果1の表示
 - 検索結果2の表示
 - Vim上で編集中のファイルのみコンパイル
 - ビルド,リビルド,クリーン&コンパイルの結果を表示
 - Error一覧の表示  
  **要VisualStudio2005以上**
 - 編集中のファイルのカーソルがある行にBreakPointの追加
 - ソリューションのあるディレクトリに移動 
 - スタートアッププロジェクトの設定
 - ビルドコンフィグの設定
 - ビルドプラットフォームの設定
  ![image](https://dl.dropboxusercontent.com/u/45602523/vim-visualstudio_setconfig.gif)
 - ソリューションに含まれているファイルを検索して開く  
  **要Unite**  
  ![image](https://dl.dropboxusercontent.com/u/45602523/vim-visualstudio_unite.gif)


