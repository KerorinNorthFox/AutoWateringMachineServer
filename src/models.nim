import
  std/os,
  std/strformat,
  std/times,
  norm/model,
  norm/sqlite

from ./logging import Logging

# db接続
proc connectDB*(): auto =
  let db_path: string = getAppDir() / "db.sqlite"
  result = open(db_path, "", "", "")

#================================================================
# ユーザーモデル
type User* = ref object of Model
  # ユーザー名
  username*: string
  # パスワード
  password*: string
  # メールアドレス
  email*: string

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
  # TODO: 関連するハードウェアなどのレコードも削除する
  Logging("INFO", "deleteUserAtDB", &"Deleted {username}'s account.")

#================================================================
# ハードウェアモデル
type Hardware* = ref object of Model
  # ハードウェアの属するユーザー
  user*: User
  # ハードウェアの名前
  name*: string

# initialize Hardware
proc newHardware*(user=newUser(),
  name="",
): Hardware =
  Hardware(
    user:user,
    name:name
  )

#================================================================
# 温度モデル
type Temperature* = ref object of Model
  # 属するハードウェア
  hardware*: Hardware
  # 温度
  temperature*: float

# initialize Temperature
proc newTemperature(hardware=newHardware(), temperature=0.0): Temperature =
  Temperature(hardware:hardware, temperature:temperature)

#================================================================
# 湿度モデル
type Humidity* = ref object of Model
  # 属するハードウェア
  hardware*: Hardware
  # 湿度
  humidity*: float

# initialize Humidity
proc newHumidity(hardware=newHardware(), humidity=0.0): Humidity =
  Humidity(hardware:hardware, humidity:humidity)

#================================================================
# スケジュールモデル
type Schedule* = ref object of Model
  # 属するハードウェア
  hardware*: Hardware
  # スケジュール
  schedule*: string

# initialize Schedule
proc newSchedule(hardware=newHardware(), schedule=now().format("yyyy-MM-dd HH:mm")): Schedule =
  Schedule(hardware:hardware, schedule:schedule)

#================================================================
# dbのテーブル作成
proc createDB*(): void =
  let dbConn = connectDB()
  dbConn.createTables(newHardware())
  Logging("INFO", "createDB", "Created tables.")

# dbにレコード挿入
proc insertAtDB*[T](model:var T): void =
  let dbConn = connectDB()
  dbConn.insert(model)
  Logging("INFO", "insertAtDB", &"Inserted {T.type.`$`} data to tables.")