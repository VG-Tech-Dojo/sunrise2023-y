resource "local_file" "setup_rds_script" {
  filename        = "${path.cwd}/_files/setup_rds.sh"
  file_permission = "0755"
  content         = <<EOF
#!/bin/bash

cd "$(dirname $0)" || exit 2

if pgrep -f "ssh -f -N -L 13306"; then
  kill "$(pgrep -f "ssh -f -N -L 13306")"
fi

ssh -f -N -L 13306:${aws_db_instance.hakaru.endpoint} -i ../../_files/id_rsa -o ProxyCommand="aws-vault exec ${var.AWS_PROFILE} -- aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'" ubuntu@${aws_instance.redash.id}
mysql --ssl-mode=DISABLED -uroot -p"$(aws-vault exec ${var.AWS_PROFILE} -- aws ssm get-parameter --name "${aws_ssm_parameter.rds_root_password.name}" --output text --query Parameter.Value --with-decryption)" -h127.0.0.1 -P13306 -D${aws_db_instance.hakaru.db_name} < setup_rds.sql

kill "$(pgrep -f "ssh -f -N -L 13306")"
EOF
}

resource "local_file" "readme_md" {
  filename        = "${path.cwd}/README.md"
  file_permission = "0644"
  content         = <<EOF
# hakaru

# endpoint

http://${aws_lb.hakaru.dns_name}

# redash

http://${aws_eip.redash.public_ip}

## 初回セットアップ時に入力する項目

|||
|:---|:---|
|Name|admin|
|Email Address|admin@example.com|
|Password|チームで共有する|
|Subscribe to Security Notifications|チェックを入れない|
|Subscribe to newsletter (version updates, no more than once a month)|チェックを入れない|
|Organization Name:|hakaru|

## データソースの追加時に入力する項目

|||
|:---|:---|
|Name|hakaru|
|Host|${aws_db_instance.hakaru.address}|
|Port|${aws_db_instance.hakaru.port}|
|User|redash|
|Password|SSM パラメータストアの ${aws_ssm_parameter.rds_redash_password.name} の内容|
|Database Name|${aws_db_instance.hakaru.db_name}|
|Use SSL|チェックを入れない|
EOF
}
