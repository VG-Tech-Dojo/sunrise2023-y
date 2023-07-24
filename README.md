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
$ aws-vault add sunrise2023-z
Enter Access Key Id:
Enter Secret Key:
Added credentials to profile "sunrise2023-z" in vault
```

## awscli

```ini
# ~/.aws/config

[profile sunrise2023-z]
region=ap-northeast-1
cli_pager=
mfa_serial=arn:aws:iam::203772305478:mfa/YOUR-USER-NAME
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
