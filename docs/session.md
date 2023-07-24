# インスタンスへの接続

EC2インスタンスにログインして調査したい！というときに

## ブラウザから

セッションマネージャーからログインできます

https://ap-northeast-1.console.aws.amazon.com/systems-manager/session-manager/sessions?region=ap-northeast-1

## ターミナルから

### 準備

1. キーペアの秘密鍵(_files/id_rsa)を取得します
    ```bash
    $ make get_ssh_key
    ```
1. awscli用のセッションマネージャープラグインをインストールする
    * 参考: https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
    ```bash
    $ curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
    $ unzip sessionmanager-bundle.zip
    $ sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
    ```
1. ~/.ssh/configを設定する
    - 参考: https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-getting-started-enable-ssh-connections.html
    ```
    # SSH over Session Manager
    Host i-* mi-*
        ProxyCommand sh -c "aws-vault exec sunrise2023-y -- aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
    ```

### 接続方法

EC2のインスタンスIDをブラウザ等で調べて以下のコマンドを実行する

```bash
ssh -i _files/id_rsa ec2-user@インスタンスID
```

redashへの接続の場合は以下の通り
```bash
$ ssh -i ./_files/id_rsa ubuntu@$インスタンスID
```
