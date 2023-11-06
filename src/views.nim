import
  std/json,
  std/strformat,
  std/strutils,
  std/times,
  prologue,
  norm/model,
  norm/sqlite
import
  ./debugging,
  ./models,
  ./utils

# ドメイン
proc api*(ctx:Context) {.async.} =
  resp(plainTextResponse("ok"))

# アカウント認証
proc auth*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to auth."):
    let req: JsonNode = ctx.request.body.parseJson()
    # json構造が違うときにHttp400
    if not req.checkJsonKeys(@["email", "password"]):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Bad request : Wrong json structure.",
        "token":"",
        "deadline":""
        }, Http400)
      )
      DebugLogging("400", ctx.request.path, "Wrong json structure.")
      return
    DebugLogging("INFO",
      ctx.request.path,
      &"""Received data -> email:"{req["email"].getStr()}", pw:"{req["password"].getStr()}" """
    )
    # DBからアカウントのデータを持ってくる＆なかったらhttp400を送る
    var account: Account = readAccountFromDB(req["email"].getStr())
    if account == nil:
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"No such an account exists.",
        "token":"",
        "deadline":""
        }, Http404)
      )
      DebugLogging("404", ctx.request.path, "No such an account exists.")
      return
    # パスワードが合っているか確認
    if not checkAccountFromDB(req["email"].getStr(), req["password"].getStr()):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Wrong password or email",
        "token":"",
        "deadline":""
        }, Http400)
      )
      DebugLogging("400", ctx.request.path, "Wrong password or email.")
      return
    # ユーザーIDでJWT認証してトークンを返す
    let
      deadlineHour: int = 1
      token: string = generateJwt(account.id, deadlineHour)
      deadline: string = $(getTime()+deadlineHour.hours)
    resp(jsonResponse(%*{
      "is_success":"true",
      "message":"",
      "token":token,
      "deadline":deadline
      })
    )

# アカウント作成
proc createAccount*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to create account."):
    let req: JsonNode = ctx.request.body.parseJson()
    # json構造が違うときにHttp400
    if not req.checkJsonKeys(@["username", "password", "email"]):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Bad request : Wrong json structure."
        }, Http400)
      )
      DebugLogging("400", ctx.request.path, "Wrong json structure.")
      return
    DebugLogging("INFO",
      ctx.request.path,
      &"""Received data -> username:"{req["username"].getStr()}", pw:"{req["password"].getStr()}", email:"{req["email"].getStr()}" """
    )
    # emailが重複しているときreturn
    if checkDuplicateAccount(req["email"].getStr()):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"An account with the given email already exists."
        }, Http400)
      )
      DebugLogging("400", ctx.request.path, "An account with the give email already exists.")
      return
    # DBにアカウントを作成する処理
    var account: Account = newAccount(
      username=req["username"].getStr(),
      password=req["password"].getStr(),
      email=req["email"].getStr()
    )
    try:
      account.insertDB()
    except:
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Server database is something wrong."
        }, Http500)
      )
      DebugLogging("500", ctx.request.path, "Inserting to db is something wrong.")
      return
    resp(jsonResponse(%*{
      "is_success":"true",
      "message":""
      }, Http201)
    )

# アカウント情報読み込み
proc readAccount*(ctx:Context) {.async.} =
  let token: string = ctx.request.getHeader("Authorization")[0]
  let id: int = decodeJwt(token)
  # アカウント情報取得
  var account: Account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist.",
      "username":"",
      "password":"",
      "email":"",
      "id":""
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":"",
    "username":account.username,
    "password":account.password,
    "email":account.email,
    "id":account.id.`$`
    })
  )

# アカウント情報更新
proc updateAccount*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["username", "password", "email"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "Wrong json structure.")
    return
  DebugLogging("INFO",
    ctx.request.path,
    &"""Received data -> username:"{req["username"].getStr()}", pw:"{req["password"].getStr()}", email:"{req["email"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  var account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist.",
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  # アカウント情報更新
  let
    username: string = req["username"].getStr()
    password: string = req["password"].getStr()
    email: string = req["email"].getStr()
  if username != "":
    account.username = username
  if password != "":
    account.password = password
  if email != "":
    account.email = email
  updateAccountAtDB(account)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    })
  )

# アカウント削除
proc deleteAccount*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["password"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "Wrong json structure.")
    return
  DebugLogging("INFO",
    ctx.request.path,
    &"""Received data -> pw:"{req["password"].getStr()}" """
  )
  let
    password: string = req["password"].getStr()
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  var account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist.",
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  # パスワードが合っているか確認
  if account.password != password:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Wrong password or email",
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "Wrong password.")
    return
  # アカウント削除
  deleteAccountAtDB(account)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    })
  )

# ハードウェア登録
proc registerHardware*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["name"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "Wrong json structure.")
    return
  DebugLogging("INFO",
    ctx.request.path,
    &"""Received data -> name:"{req["name"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  # アカウント情報取得
  var account: Account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist."
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  # ハードウェアの重複確認
  if not checkDuplicateHardware(account, req["name"].getStr()):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"A Hardware with the given name already exists."
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "A Hardware with the given name already exists.")
    return
  # ハードウェア作成
  var hardware: Hardware = newHardware(
    account = account,
    name=req["name"].getStr(),
  )
  try:
    hardware.insertDB()
  except:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Server database is something wrong."
      }, Http500)
    )
    DebugLogging("500", ctx.request.path, "Inserting to db is something wrong.")
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    }, Http201)
  )

proc readHardware*(ctx:Context) {.async.} =
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    name: string = ctx.getPathParamsOption("name").get()
  # アカウント情報取得
  var account: Account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist.",
      "username":"",
      "name":"",
      "temperature":"",
      "humidity":"",
      "schedule":"",
      "id":""
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  # ハードウェア情報取得
  var hardwares: seq[Hardware] = readHardwareFromDB(account)
  var hardware: Hardware
  for i, a in hardwares:
    DebugLogging("INFO", "raedHardware", &"Read {i} hardware : {a[]}")
    if a.name == name:
      hardware = a
  if hardware.isNil:
    let msg = &"The hardware '{name}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg,
      "username":"",
      "name":"",
      "temperature":"",
      "humidity":"",
      "schedule":"",
      "id":""
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, msg)
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":"",
    "username":hardware.account.username,
    "name":hardware.name,
    "temperature":hardware.temperature.temperature.`$`,
    "humidity":hardware.humidity.humidity.`$`,
    "schedule":hardware.schedule.schedule,
    "id":hardware.id.`$`,
    }, Http201)
  )

proc updateHardware*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["name", "temperature", "humidity", "schedule"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, "Wrong json structure.")
    return
  DebugLogging("INFO",
    ctx.request.path,
    &"""Received data -> name:"{req["name"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    nameParam: string = ctx.getPathParamsOption("name").get()
  var account = readAccountFromDB(id)
  # アカウントが存在しないとき
  if account == nil:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"The account does not exist."
      }, Http404)
    )
    DebugLogging("404", ctx.request.path, "The account does not exist.")
    return
  # ハードウェア情報更新
  var hardwares: seq[Hardware] = readHardwareFromDB(account)
  var hardware: Hardware
  for i, a in hardwares:
    DebugLogging("INFO", "raedHardware", &"Read {i} hardware : {a[]}")
    if a.name == nameParam:
      hardware = a
  if hardware.isNil:
    let msg = &"The hardware '{nameParam}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg
      }, Http400)
    )
    DebugLogging("400", ctx.request.path, msg)
    return
  let
    name = req["name"].getStr()
    temperature = req["temperature"].getStr()
    humidity = req["humidity"].getStr()
    schedule = req["schedule"].getStr()
  if name != "":
    hardware.name = name
  if schedule != "":
    hardware.schedule.schedule = schedule
  try:
    if temperature != "":
      hardware.temperature.temperature = temperature.parseFloat
    if humidity != "":
      hardware.humidity.humidity = humidity.parseFloat
  except:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Cannot cast values because of wrong type."
      }, Http400)
    )
  updateHardwareAtDB(hardware)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    })
  )
