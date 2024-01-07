# Translator
## *Description*
* チャットをDeepLで翻訳します
    * コマンド入力時
    * チャットダブルクリック時
    * チャット右クリックから翻訳時
* 導入方法
    * addons フォルダ内に translator フォルダをコピーしてください
    * DeepLのAPIキーの取得
    * DeepLのAPIキーをconfig.jsonで指定
    * m2TranslatorServiceのインストール（install.batを管理者権限で実行）
* 削除方法
    * m2TranslatorServiceのアンインストール（uninstall.batを管理者権限で実行）
* 動作には別途「__m2util」が必要

## *Commands*
* `/trans <ja/en/ko/...> <chat>` :
    * <ja/en/ko/...>で指定した言語に<chat>内容を翻訳する
