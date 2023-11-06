import
  std/os,
  std/strformat,
  std/strutils,
  std/times,
  norm/model,
  norm/sqlite,
  ./debugging

# db接続
proc connectDB*(): auto =
  let db_path: string = getAppDir() / "db.sqlite"
  result = open(db_path, "", "", "")
  DebugLogging("INFO", "connectDB", "Connecting to DB.")

#================================================================
type Account* = ref object of Model
  username*: string
  password*: string
  email*: string

proc newAccount*(username="", password="", email=""): Account =
  Account(username:username, password:password, email:email)

# アカウントの重複を確認する
proc checkDuplicateAccount*(value:string or int): bool =
  let
    key: string = (if value.type is int: "id" else: "email")
    dbConn = connectDB()
  result = dbConn.exists(Account, &"{key} = ?", value) # valueはemailかid
  DebugLogging("INFO", "checkDuplicateAccount", &"Checked if account is duplicate -> {$result}")

# パスワードが合っているか確認する
proc checkAccountFromDB*(email, password:string): bool =
  var account: Account = newAccount()
  let dbConn = connectDB()
  dbConn.select(account, "email = ?", email)
  if account.password != password:
    DebugLogging("ERROR", "checkAccountFromDB", &"Password is incorrect.")
    return false
  DebugLogging("SUCCESS", "checkAccountFromDB", &"Password is correct.")
  return true

# アカウント情報読み取り
proc readAccountFromDB*(value:string or int): Account =
  var account: Account = newAccount()
  let
    key: string = (if value.type is int: "id" else: "email")
    dbConn = connectDB()
  if not dbConn.exists(Account, &"{key} = ?", value): # # valueはemailかid
    account = nil
    DebugLogging("ERROR", "readAccountFromDB", &"Read nobody's data from Account tables.")
  else:
    dbConn.select(account, &"{key} = ?", value)
    DebugLogging("SUCCESS", "readAccountFromDB", &"Read {account.username}'s data from Account tables.")
  return account

# アカウントを更新
proc updateAccountAtDB*(account:var Account): void =
  let dbConn = connectDB()
  dbConn.update(account)
  DebugLogging("INFO", "updateAccountAtDB", &"Updated {account.username}'s account infomation.")

# アカウント削除
proc deleteAccountAtDB*(account:var Account): void =
  let
    username = account.username
    dbConn = connectDB()
  dbConn.delete(account)
  DebugLogging("INFO", "deleteAccountAtDB", &"Deleted {username}'s account.")

#================================================================
type Temperature* = ref object of Model
  temperature*: float

proc newTemperature(temperature=0.0): Temperature =
  Temperature(temperature:temperature)

#================================================================
type Humidity* = ref object of Model
  humidity*: float

proc newHumidity(humidity=0.0): Humidity =
  Humidity(humidity:humidity)

#===============================================================
type Schedule* = ref object of Model
  schedule*: string

proc newSchedule(schedule=now().format("yyyy-MM-dd HH:mm")): Schedule =
  Schedule(schedule:schedule)

#===============================================p=================
type Hardware* = ref object of Model
  account*: Account
  name*: string
  temperature*: Temperature
  humidity*: Humidity
  schedule*: Schedule

proc newHardware*(account=newAccount(),
  name="",
  temperature=newTemperature(),
  humidity=newHumidity(),
  schedule=newSchedule()
): Hardware =
  Hardware(
    account:account,
    name:name,
    temperature:temperature,
    humidity:humidity,
    schedule:schedule
  )

proc checkDuplicateHardware*(account:Account, name:string): bool =
  let dbConn = connectDB()
  var hardwares = @[newHardware()]
  dbConn.selectOneToMany(account, hardwares, "account")
  result = true
  for a in hardwares:
    echo a.name
    echo name
    if a.name == name:
      result = false
    else:
      result = true
  DebugLogging("INFO", "checkDuplicateHardware", &"Checked if hardware is duplicate -> {$result}")

proc readHardwareFromDB*(account:Account): seq[Hardware] =
  var hardwares = @[newHardware()]
  let dbConn = connectDB()
  dbConn.selectOneToMany(account, hardwares, "account")
  DebugLogging("SUCCESS", "readHardwareFromDB", &"Read {account.username}'s hardwares from Hardware tables.")
  return hardwares

proc updateHardwareAtDB*(hardware:var Hardware): void =
  let dbConn = connectDB()
  dbConn.update(hardware)
  DebugLogging("INFO", "updateHardwareAtDB", &"Updated {hardware.name}'s hardware infomation.")

#================================================================
# db作成
proc createDB*(): void =
  let dbConn = connectDB()
  dbConn.createTables(newHardware())
  # TODO:ここにモデルを随時追加
  DebugLogging("INFO", "createDB", "Created tables.")

# dbにinsert
proc insertDB*[T](model:var T): void =
  let dbConn = connectDB()
  dbConn.insert(model)
  DebugLogging("INFO", "insertDB", &"Inserted {T.type.`$`} data to tables.")
