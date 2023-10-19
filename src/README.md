# API
- [API](#api)
  - [/api](#api-1)
    - [HTTP](#http)
    - [Response](#response)
  - [/api/create-account](#apicreate-account)
    - [HTTP](#http-1)
    - [Request](#request)
    - [Response](#response-1)
  - [/api/auth](#apiauth)
    - [HTTP](#http-2)
    - [Request](#request-1)
    - [Response](#response-2)
  - [/api/account](#apiaccount)
    - [HTTP](#http-3)
    - [Request](#request-2)
    - [Response](#response-3)
  - [/api/account/update](#apiaccountupdate)
    - [HTTP](#http-4)
    - [Request](#request-3)
    - [Response](#response-4)
  - [/api/account/delete](#apiaccountdelete)
    - [HTTP](#http-5)
    - [Request](#request-4)
    - [Response](#response-5)

## /api
ドメイン
### HTTP
Get
### Response
text/plain
```
"ok"
```

## /api/create-account
アカウント作成
### HTTP
Post
### Request
application/json
```
{"username":string, "password":string, "email":string}
```
### Response
application/json
```
{"is_success":bool, "message":string}
```

## /api/auth
ログインしてトークンを取得
### HTTP
Post
### Request
application/json
```
{"email":string, "password":string}
```
### Response
application/json
```
{"is_success":string, "message":string, "token":string, "deadline":string}
```

## /api/account
アカウントの情報を取得
### HTTP
Post
### Request
application/json
```
{"token":string}
```
### Response
application/json
```
{"username":string, "password":string, "email":string, "id":int}
```

## /api/account/update
アカウントの情報を更新
### HTTP
Post
### Request
application/json
```
{"token":string, "username":string, "password":string, "email":string}
```
### Response
application/json
```
{"is_success":string, "message":string}
```

## /api/account/delete
アカウントを削除
### HTTP
Post
### Request
application/json
```
{"token":string}
```
### Response
application/json
```
{"is_success":string, "message":string}
```