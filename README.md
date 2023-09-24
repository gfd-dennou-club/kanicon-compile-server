# kanicon-compile-server

Matz葉がにロボコン用コンパイルサーバプログラム

Web Serial API使用

## How to use

* 本リポジトリをclone後、サーバを起動

    ```sh
    ruby serve.rb
    ```

* マイコンとUSB Serialで接続
    * ESP-32マイコンのみ動作確認済
* 書き込みボタンを押した後に表示されるウィンドウから、マイコンを接続したポート（USB Serial Port）を選択

## 動作環境

### クライアント環境

* OS：Windows、Macのみ動作確認済
* ブラウザ：Google Chrome、Edgeのみ動作確認済

### サーバ環境

* OS：Linuxのみ動作確認済
* ESP-IDF：v4.2.4、v4.2.5
* mkspiffs：master (2020-11-03 f248296)
* mruby：3.1.0
* ruby：3.1.0
