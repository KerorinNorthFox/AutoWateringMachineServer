import
  std/json,
  std/marshal,
  std/strformat,
  prologue,
  norm/model,
  norm/sqlite
import
  ./debugging,
  ./models,
  ./utils

# ドメイン
proc api*(ctx:Context) {.async.} =
  resp "ok"

# アカウント認証
proc auth*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to auth."):
    let jsonBody = ctx.request.body.parseJson()
    # json構造が違うときにHttp400
    if jsonBody.checkJsonKeys(@["email", "password"]):
      resp("Bad request : Wrong json structure.", Http400)
      DebugLogging("ERROR", ctx.request.path, "Wrong json structure.")
      return
    # TODO: DBからアカウントのデータを持ってくる処理＆なかったらerror400を送る
    # TODO: ユーザーIDでJWTしてトークンを返す処理

# アカウント作成
proc createAccount*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to create account."):
    var jsonBody = ctx.request.body.parseJson()
    # json構造が違うときにHttp400
    if jsonBody.checkJsonKeys(@["username", "password", "email"]):
      resp("Bad request : Wrong json structure.", Http400)
      DebugLogging("ERROR", ctx.request.path, "Wrong json structure.")
      return
    DebugLogging("INFO",
      ctx.request.path,
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
      resp(jsonResponse(%*{"isSuccess":"false", "message":"Server database is something wrong."}, Http400))
      DebugLogging("ERROR", ctx.request.path, "Insert db is something wrong.")
      return
    resp(jsonResponse(%*{"isSuccess":"true", "message":""}))

# アカウント情報読み込み
proc readAccount*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to read account."):
    var jsonBody = ctx.request.body.parseJson()
    # json構造が違うときにHttp400
    if jsonBody.checkJsonKeys(@["email"]):
      resp("Bad request : Wrong json structure.", Http400)
      DebugLogging("HTTP400", "api/readAccount", "Wrong json structure.")
      return
    # TODO:usernameが違うときの処理
    var account = readAccountFromDB(jsonBody["username"].getStr())
    resp jsonResponse(parseJson($$account))

# アカウント情報更新
proc updateAccount*(ctx:Context) {.async.} =
  # TODO:アカウントupdate
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to update account."):
    discard

# アカウント削除
proc deleteAccount*(ctx:Context) {.async.} =
  # TODO:アカウントdelete
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to delete account."):
    discard
