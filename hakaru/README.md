# hakaru

# endpoint

http://hakaru-1430077846.ap-northeast-1.elb.amazonaws.com

# redash

http://18.177.167.132

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
|Host|hakaru.cuktn9tqlzz4.ap-northeast-1.rds.amazonaws.com|
|Port|3306|
|User|redash|
|Password|SSM パラメータストアの /hakaru/rds/redash/password の内容|
|Database Name|hakaru|
|Use SSL|チェックを入れない|
