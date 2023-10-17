# API
## /api
ドメイン
### Http
Get
### Response
```
"ok"
```

## /api/create_account
アカウント作成
### Http
Post
### Request
```
{"username":string, "password":string, "email":string}
```
### Response
```
{"isSuccess":bool, "message":string}
```

## /api/auth
ログインしてトークンを取得
### Http
Post
### Request
```
{"email":string, "password":string}
```