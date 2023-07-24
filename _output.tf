resource "local_file" "readme_md" {
  filename        = "${path.cwd}/README.md"
  file_permission = "0644"
  content         = <<EOF
# sunrise2023

09/11-15

## requirements

* awscli https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/install-cliv2.html
* aws-vault https://github.com/99designs/aws-vault#installing

## Slack

* participant [#general](https://sunrise2023.slack.com/archives/C043M35QZC7)
* staff [#sunrise-ad](https://cartaholdings.slack.com/archives/C75KXQ7QF)

## aws-vault

```shell
$ aws-vault add ${var.AWS_PROFILE}
Enter Access Key Id:
Enter Secret Key:
Added credentials to profile "${var.AWS_PROFILE}" in vault
```

## awscli

```ini
# ~/.aws/config

[profile ${var.AWS_PROFILE}]
region=${var.AWS_DEFAULT_REGION}
cli_pager=
mfa_serial=arn:aws:iam::${data.aws_caller_identity.current.account_id}:mfa/YOUR-USER-NAME
```

## docs

- インスタンスへの接続方法 [session.md](docs/session.md)
- [スタッフ向け]スイッチロールリンク集 [switchrole.md](docs/switchrole.md)

## Makefile

TOを指定することで対象ディレクトリを選択できます

## initialization

AWSアカウントを作ったら make apply の前に一度実行する

```bash
$ make setup
```

AWSアカウントを使うにあたり必要なリソースを作成する

```bash
$ make plan
```

```bash
$ make apply
```

hakaru に必要なリソースをAWS上に作成する

```bash
$ make plan TO=hakaru
```

```bash
$ make apply TO=hakaru
```

make apply TO=hakaru が完了したら一度実行する

```bash
$ make setup_rds
```

## plan

terraform による変更を確認する

```bash
$ make plan
```

## apply

terraform による変更を実施する

```bash
$ make apply
```
EOF
}

resource "local_file" "docs_switchrole" {
  filename        = "${path.cwd}/docs/switchrole.md"
  file_permission = "0644"
  content         = <<EOF
# AWS switchrole

普段利用しているAWSユーザアカウントからスイッチロールできるようにしています
以下の対応するアカウントから、URLから設定してください

${join("\n", formatlist("  * %s", [for v in var.aws_account_names : format("[%s](https://signin.aws.amazon.com/switchrole?account=%d&displayName=%s&roleName=switchrole/sunrise2023-%s)", v, data.aws_caller_identity.current.account_id, var.AWS_PROFILE, v)]))}
EOF
}

resource "local_file" "docs_ssh" {
  filename = "${path.cwd}/docs/session.md"
  file_permission = "0644"
  content = <<EOF
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
        ProxyCommand sh -c "aws-vault exec ${var.AWS_PROFILE} -- aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
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
EOF
}
