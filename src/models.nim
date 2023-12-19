import
  std/os,
  std/strformat,
  std/strutils,
  norm/model,
  norm/sqlite,
  ./logging

# db接続
proc connectDB*(): auto =
  let dbPath: string = getAppDir() / "db.sqlite"
  result = open(dbPath, "", "", "")
  Logging("INFO", "connectDB", "Connected to DB.")

#================================================================
type
  # ユーザーモデル
  User* = ref object of Model
    # ユーザー名
    username*: string
    # パスワード
    password*: string
    # メールアドレス
    email*: string

  # ハードウェアモデル
  Hardware* = ref object of Model
    # ハードウェアの属するユーザー
    user*: User
    # ハードウェアの名前
    name*: string

  # 温度モデル
  Temperature* = ref object of Model
    # 属するハードウェア
    hardware*: Hardware
    # 温度
    temperature*: float
    # 測定日時
    date*: string

  # 湿度モデル
  Humidity* = ref object of Model
    # 属するハードウェア
    hardware*: Hardware
    # 湿度
    humidity*: float
    # 測定日時
    date*: string

  # スケジュールモデル
  Schedule* = ref object of Model
    # 属するハードウェア
    hardware*: Hardware
    # スケジュール
    schedule*: string

#================================================================
# initialize User
proc newUser*(username="", password="", email=""): User =
  User(username:username, password:password, email:email)

# ユーザー情報取得
proc readUserFromDB*(value:string or int): User =
  var user: User = newUser()
  let
    key: string = (if value.type is int: "id" else: "email")
    dbConn = connectDB()
  if not dbConn.exists(User, &"{key} = ?", value):
    user = nil
    Logging("ERROR", "readUserFromDB", "Read nobody's data from User tables.")
  else:
    dbConn.select(user, &"{key} = ?", value)
    Logging("SUCCESS", "readUserFromDB", &"Read {user.username}'s data from User tables.")
  return user

# ユーザー情報更新
proc updateUserAtDB*(user:var User): void =
  let dbConn = connectDB()
  dbConn.update(user)
  Logging("INFO", "updateUserAtDB", &"Updated {user.username}'s user information.")

# ユーザー削除
proc deleteUserAtDB*(user:var User): void =
  let
    username: string = user.username
    dbConn = connectDB()
  dbConn.delete(user)
  Logging("INFO", "deleteUserAtDB", &"Deleted {username}'s account.")

# emailの重複を確認する
proc checkDuplicateUser*(value:string or int): bool =
  let
    key: string = (if value.type is int: "id" else: "email")
    dbConn = connectDB()
  result = dbConn.exists(User, &"{key} = ?", value)
  Logging("INFO", "checkDuplicateUser", &"Checked if account is duplicate -> {$result}")

# パスワードが合っているか確認する
proc checkPassword*(email, password:string): bool =
  var user: User = newUser()
  let dbConn = connectDB()
  dbConn.select(user, "email = ?", email)
  if user.password != password:
    Logging("ERROR", "checkPasswordFromDB", &"Password is incorrect.")
    return false
  Logging("SUCCESS", "checkPasswordFromDB", &"Password is correct.")
  return true

proc checkUserExists*(id:int): bool =
  let dbConn = connectDB()
  return dbConn.exists(User, "id = ?", id)

#================================================================
# initialize Hardware
proc newHardware*(user=newUser(),
  name="",
): Hardware =
  Hardware(
    user:user,
    name:name
  )

# ハードウェア一覧を取得
proc getHardwares(user:User): seq[Hardware] =
  var hardwares = @[newHardware()]
  let dbConn = connectDB()
  dbConn.selectOneToMany(user, hardwares, "user")
  return hardwares

# ハードウェア名の重複を確認
proc checkDuplicateHardware*(user:User, name:string): bool =
  let hardwares = getHardwares(user)
  result = true
  for hardware in hardwares:
    if hardware.name == name:
      result = false
  Logging("INFO", "checkDuplicateHardware", &"Checked if hardware is duplicate -> {$result}")

# ハードウェア情報取得
proc readHardwareFromDB*(user:User, name:string): Hardware =
  result = newHardware()
  let hardwares = getHardwares(user)
  for i, hardware in hardwares:
    Logging("INFO", "raedHardware", &"Read {i} hardware : {hardware[]}")
    if hardware.name == name:
      result = hardware
  Logging("INFO", "readHardwareFromDB", &"Read {user.username}'s hardwares from Hardware tables.")

# ハードウェア情報更新
proc updateHardwareAtDB*(hardware:var Hardware): void =
  let dbConn = connectDB()
  dbConn.update(hardware)
  Logging("INFO", "updateHardwareAtDB", &"Updated {hardware.name}'s hardware infomation.")

#================================================================
# initialize Temperature
proc newTemperature*(hardware=newHardware(), temperature=0.0, date=""): Temperature =
  Temperature(hardware:hardware, temperature:temperature, date:date)

# 温度のレコードを全部取得
proc getTemperatures(hardware:Hardware): seq[Temperature] =
  var temperatures = @[newTemperature()]
  let dbConn = connectDB()
  dbConn.selectOneToMany(hardware, temperatures, "hardware")
  return temperatures

# ハードウェアの温度のレコードを全て取得
proc readTemperatureFromDB*(hardware:Hardware): seq[Temperature] =
  result = getTemperatures(hardware)
  Logging("INFO", "readTemperatureFromDB", "Read {hardware.name}'s latest temperature from Temperature tables.")

#================================================================
# initialize Humidity
proc newHumidity(hardware=newHardware(), humidity=0.0, date=""): Humidity =
  Humidity(hardware:hardware, humidity:humidity, date:date)

# 湿度のレコードを全部取得
proc getHumidities(hardware:Hardware): seq[Humidity] =
  var humidities = @[newHumidity()]
  let dbConn = connectDB()
  dbConn.selectOneToMany(hardware, humidities, "hardware")
  return humidities

# ハードウェアの湿度のレコードを全て取得
proc readHumidityFromDB*(hardware:Hardware): seq[Humidity] =
  result = getHumidities(hardware)
  Logging("INFO", "readHumidityFromDB", "Read {hardware.name}'s latest temperature from Humidity tables.")

#================================================================
# initialize Schedule
proc newSchedule(hardware=newHardware(), schedule=""): Schedule =
  Schedule(hardware:hardware, schedule:schedule)

#================================================================
# dbのテーブル作成
proc createDB*(): void =
  let dbConn = connectDB()
  dbConn.createTables(newHardware())
  dbConn.createTables(newTemperature())
  dbConn.createTables(newHumidity())
  dbConn.createTables(newSchedule())
  Logging("INFO", "createDB", "Created tables.")

# dbにレコード挿入
proc insertAtDB*[T](model:var T): void =
  let dbConn = connectDB()
  dbConn.insert(model)
  Logging("INFO", "insertAtDB", &"Inserted {T.type.`$`} data to tables.")