import
  std/json,
  std/strformat,
  std/with,
  prologue,
  norm/model,
  norm/sqlite
import
  ./debugging,
  ./models,
  ./utils

# ドメイン
proc api*(ctx:Context) {.async.} =
  resp("ok")

# アカウント認証
proc auth*(ctx:Context) {.async.} =
  let jsonBody = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if jsonBody.checkJsonKeys(@["username", "password"]):
    resp "Bad request : Wrong json structure.", Http400
  # TODO: DBからアカウントのデータを持ってくる処理＆なかったらerror400を送る
  # TODO: ユーザーIDでJWTしてトークンを返す処理

# アカウント作成
proc createAccount*(ctx:Context) {.async.} =
  debugLogging("POST", "api/create_account", "HttpPost comes.")
  var jsonBody = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if jsonBody.checkJsonKeys(@["username", "password", "email"]):
    resp("Bad request : Wrong json structure.", Http400)
    debugLogging("HTTP400", "api/create_account", "Wrong json structure.")
    return
  debugLogging("INFO",
    "api/create_account",
    &"""Received data -> username:"{jsonBody["username"].getStr()}", pw:"{jsonBody["password"].getStr()}", email:"{jsonBody["email"].getStr()}" """
  )
  # DBにアカウントを作成する処理
  var account = newAccount(
    username=jsonBody["username"].getStr(),
    password=jsonBody["password"].getStr(),
    email=jsonBody["email"].getStr()
    )
  try:
    account.insertDB()
  except:
    resp(jsonResponse(%*{"isSuccess":"false", "message":"Server database is something wrong."}))
    debugLogging("ERROR", "api/create_account", "Insert db is something wrong.")
    return
  resp(jsonResponse(%*{"isSuccess":"true"}))
  debugLogging("SUCCESS", "api/create_account", "Success to create account.")

# アカウント情報読み込み
proc readAccount*(ctx:Context) {.async.} =
  var jsonBody = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if jsonBody.checkJsonKeys(@["username"]):
    resp("Bad request : Wrong json structure.", Http400)
  # TODO:アカウントread
  var account = readAccountFromDB(jsonBody["username"].getStr())

# アカウント情報更新
proc updateAccount*(ctx:Context) {.async.} =
  # TODO:アカウントupdate
  discard

# アカウント削除
proc deleteAccount*(ctx:Context) {.async.} =
  # TODO:アカウントdelete
  discard
