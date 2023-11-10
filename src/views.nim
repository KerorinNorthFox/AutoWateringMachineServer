import
  std/json,
  std/strformat,
  std/strutils,
  std/times,
  norm/model,
  norm/sqlite,
  prologue,
  ./logging,
  ./models,
  ./utils

# トップレベルドメイン
proc api*(ctx:Context) {.async.} =
  resp(plainTextResponse("ok"))

# アカウント作成
proc createUser*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to create account."):
    var req: JsonNode
    try:
      req = ctx.request.body.parseJson()
    except: # TODO: これを全てに適用
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Bad request : Invalid json"
        }, Http400)
      )
      Logging("400", ctx.request.path, "Invalid json")
      return
    # jsonの内容が違うときにHttp400をレスポンス
    if not req.checkJsonKeys(@["username", "password", "email"]):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Bad request : Wrong json structure"
        }, Http400)
      )
      Logging("400", ctx.request.path, "Wrong json structure.")
      return
    Logging("INFO",
      ctx.request.path,
      &"""Received data -> username:"{req["username"].getStr()}", pw:"{req["password"].getStr()}", email:"{req["email"].getStr()}" """
    )
    # emailが被っているときにHttp400をレスポンス
    if checkDuplicateUser(req["email"].getStr()):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"An account with the given email already exists."
        }, Http400)
      )
      Logging("400", ctx.request.path, "An account with the given email already exists.")
      return
    # アカウント作成処理
    var user: User = newUser(
      username=req["username"].getStr(),
      password=req["password"].getStr(),
      email=req["email"].getStr()
    )
    try:
      user.insertAtDB()
    except:
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Server database is something wrong."
        }, Http500)
      )
      Logging("500", ctx.request.path, "Inserting to db is failed.")
      return
    resp(jsonResponse(%*{
      "is_success":"true",
      "message":""
      }, Http201)
    )

# ログイン
proc auth*(ctx:Context) {.async.} =
  APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to auth."):
    let req: JsonNode = ctx.request.body.parseJson()
    # jsonの内容が違うときにHttp400をレスポンス
    if not req.checkJsonKeys(@["email", "password"]):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Bad request : Wrong json structure.",
        "token":"",
        "deadline":""
        }, Http400)
      )
      Logging("400", ctx.request.path, "Wrong json structure.")
      return
    Logging("INFO",
      ctx.request.path,
      &"""Received data -> email:"{req["email"].getStr()}", pw:"{req["password"].getStr()}" """
    )
    # DBからアカウントのデータを持ってくる
    var user: User = readUserFromDB(req["email"].getStr())
    # パスワードが合っているか確認
    if not checkPassword(req["email"].getStr(), req["password"].getStr()):
      resp(jsonResponse(%*{
        "is_success":"false",
        "message":"Wrong password or email",
        "token":"",
        "deadline":""
        }, Http400)
      )
      Logging("400", ctx.request.path, "Wrong password or email.")
      return
    # ユーザーIDでJWT認証してトークンを返す
    let
      deadlineHour: int = 1
      token: string = generateJwt(user.id, deadlineHour)
      deadline: string = $(getTime()+deadlineHour.hours)
    resp(jsonResponse(%*{
      "is_success":"true",
      "message":"",
      "token":token,
      "deadline":deadline
      }, Http201)
    )

# ユーザー情報取得
proc readUser*(ctx:Context) {.async.} =
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":"",
    "username":user.username,
    "password":user.password,
    "email":user.email,
    "id":user.id.`$`
    })
  )

# ユーザー情報更新
proc updateUser*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["username", "password", "email"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    Logging("400", ctx.request.path, "Wrong json structure.")
    return
  Logging("INFO",
    ctx.request.path,
    &"""Received data -> username:"{req["username"].getStr()}", pw:"{req["password"].getStr()}", email:"{req["email"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # アカウント情報更新
  let
    username: string = req["username"].getStr()
    password: string = req["password"].getStr()
    email: string = req["email"].getStr()
  if username != "":
    user.username = username
  if password != "":
    user.password = password
  if email != "":
    user.email = email
  updateUserAtDB(user)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    })
  )

# ユーザー削除
proc deleteUser*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["password"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    Logging("400", ctx.request.path, "Wrong json structure.")
    return
  Logging("INFO",
    ctx.request.path,
    &"""Received data -> pw:"{req["password"].getStr()}" """
  )
  let
    password: string = req["password"].getStr()
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # パスワードが合っているか確認
  if user.password != password:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Wrong password or email",
      }, Http400)
    )
    Logging("400", ctx.request.path, "Wrong password.")
    return
  # アカウント削除
  deleteUserAtDB(user)
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
    Logging("400", ctx.request.path, "Wrong json structure.")
    return
  Logging("INFO",
    ctx.request.path,
    &"""Received data -> name:"{req["name"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # ハードウェアの重複確認
  if not checkDuplicateHardware(user, req["name"].getStr()):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"A Hardware with the given name already exists."
      }, Http400)
    )
    Logging("400", ctx.request.path, "A Hardware with the given name already exists.")
    return
  # ハードウェア作成
  var hardware: Hardware = newHardware(
    user=user,
    name=req["name"].getStr(),
  )
  try:
    hardware.insertAtDB()
  except:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Server database is something wrong."
      }, Http500)
    )
    Logging("500", ctx.request.path, "Inserted to db is something wrong.")
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    }, Http201)
  )

# ハードウェア情報取得
proc readHardware*(ctx:Context) {.async.} =
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    name: string = ctx.getPathParamsOption("name").get()
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # ハードウェア情報取得
  var hardware: Hardware = readHardwareFromDB(user, name)
  if hardware.isNil:
    let msg = &"The hardware '{name}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg,
      "username":"",
      "name":"",
      "id":""
      }, Http400)
    )
    Logging("400", ctx.request.path, msg)
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":"",
    "username":hardware.user.username,
    "name":hardware.name,
    "id":hardware.id.`$`,
    }, Http201)
  )

# ハードウェア情報更新
proc updateHardware*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["name"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    Logging("400", ctx.request.path, "Wrong json structure.")
    return
  Logging("INFO",
    ctx.request.path,
    &"""Received data -> name:"{req["name"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    nameParam: string = ctx.getPathParamsOption("name").get()
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # ハードウェア情報更新
  var hardware: Hardware = readHardwareFromDB(user, nameParam)
  if hardware.isNil:
    let msg = &"The hardware '{nameParam}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg,
      }, Http400)
    )
    Logging("400", ctx.request.path, msg)
    return
  let
    name = req["name"].getStr()
  if name != "":
    hardware.name = name
  updateHardwareAtDB(hardware)
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    })
  )

proc readLatestTemperature*(ctx:Context) {.async.} =
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    name: string = ctx.getPathParamsOption("name").get()
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # ハードウェア情報取得
  var hardware: Hardware = readHardwareFromDB(user, name)
  if hardware.isNil:
    let msg = &"The hardware '{name}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg,
      "temperature":"",
      "date":""
      }, Http400)
    )
    Logging("400", ctx.request.path, msg)
    return
  let temperatures = readTemperatureFromDB(hardware)
  if temperatures.len == 0:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"No temperature record yet.",
      "temperature":"",
      "date":""
      }, Http400)
    )
    Logging("400", ctx.request.path, "No temperature record yet.")
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":"",
    "temperature":temperatures[^1].temperature.`$`,
    "date":temperatures[^1].date
    }, Http201)
  )

proc insertTemperature*(ctx:Context) {.async.} =
  let req: JsonNode = ctx.request.body.parseJson()
  # json構造が違うときにHttp400
  if not req.checkJsonKeys(@["temperature"]):
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Bad request : Wrong json structure."
      }, Http400)
    )
    Logging("400", ctx.request.path, "Wrong json structure.")
    return
  Logging("INFO",
    ctx.request.path,
    &"""Received data -> temperature:"{req["temperature"].getStr()}" """
  )
  let
    token: string = ctx.request.getHeader("Authorization")[0]
    id: int = decodeJwt(token)
    name: string = ctx.getPathParamsOption("name").get()
  # アカウント情報取得
  var user: User = readUserFromDB(id)
  # ハードウェア情報取得
  var hardware: Hardware = readHardwareFromDB(user, name)
  if hardware.isNil:
    let msg = &"The hardware '{name}' does not exist."
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":msg,
      "temperature":"",
      "date":""
      }, Http400)
    )
    Logging("400", ctx.request.path, msg)
    return
  var temperature = newTemperature(
    hardware=hardware,
    temperature=req["temperature"].getStr().parseFloat,
    date=now().format("yyyy-MM-dd HH:mm:ss")
  )
  try:
    temperature.insertAtDB()
  except:
    resp(jsonResponse(%*{
      "is_success":"false",
      "message":"Server database is something wrong."
      }, Http500)
    )
    Logging("500", ctx.request.path, "Inserted to db is something wrong.")
    return
  resp(jsonResponse(%*{
    "is_success":"true",
    "message":""
    }, Http201)
  )