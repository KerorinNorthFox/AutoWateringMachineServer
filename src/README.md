# API
- [API](#api)
  - [/api](#api-1)
    - [HTTP](#http)
    - [Response](#response)
  - [/api/auth](#apiauth)
    - [HTTP](#http-1)
    - [Request](#request)
    - [Response](#response-1)
  - [/api/create-account](#apicreate-account)
    - [HTTP](#http-2)
    - [Request](#request-1)
    - [Response](#response-2)
  - [/api/account](#apiaccount)
    - [HTTP](#http-3)
    - [Header](#header)
    - [Response](#response-3)
  - [/api/account/update](#apiaccountupdate)
    - [HTTP](#http-4)
    - [Header](#header-1)
    - [Request](#request-2)
    - [Response](#response-4)
  - [/api/account/delete](#apiaccountdelete)
    - [HTTP](#http-5)
    - [Header](#header-2)
    - [Request](#request-3)
    - [Response](#response-5)

## /api
トップレベルドメイン
### HTTP
Get
### Response
text/plain
```
"ok"
```

## /api/auth
emailでアカウントにログインしてトークンを取得
### HTTP
Post
### Request
application/json
```
{
  "email":string,
  "password":string
}
```
### Response
application/json
```
{
  "is_success":bool,
  "message":string,
  "token":string,
  "deadline":DateTime
}
```

## /api/create-account
アカウント作成
### HTTP
Post
### Request
application/json
```
{
  "username":string,
  "password":string,
  "email":string
}
```
### Response
application/json
```
{
  "is_success":bool,
  "message":string
}
```

## /api/account
アカウントの情報を取得
### HTTP
Get
### Header
```
Authorization: Bearer token
```
### Response
application/json
```
{
  ""is_success":bool,
  "message":string,
  "username":string,
  "password":string,
  "email":string,
  "id":int
}
```

## /api/account/update
アカウントの情報を更新
### HTTP
Post
### Header
```
Authorization: Bearer token
```
### Request
application/json
```
{
  "username":string,
  "password":string,
  "email":string
}
```
### Response
application/json
```
{
  "is_success":string,
  "message":string
}
```

## /api/account/delete
アカウントを削除
### HTTP
Post
### Header
```
Authorization: Bearer token
```
### Request
application/json
```
{
  "password":string
}
```
### Response
application/json
```
{
  "is_success":string,
  "message":string
}
```