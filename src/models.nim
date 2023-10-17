import
  std/os,
  std/strformat,
  norm/model,
  norm/sqlite,
  ./debugging

# db接続
proc connectDB*(): auto =
  let db_path = getAppDir() / "db.sqlite"
  defer: DebugLogging("INFO", "connectDB", "Connecting to DB.")
  open(db_path, "", "", "")

#================================================================
type Account* = ref object of Model
  username*: string
  password*: string
  email*: string

proc newAccount*(username="", password="", email=""): Account =
  Account(username:username, password:password, email:email)

# AccountをDBからread
# TODO:emailでselectする
proc readAccountFromDB*(username:string): Account =
  var account = newAccount()
  let dbConn = connectDB()
  dbConn.select(account, "username = ?", username)
  DebugLogging("SUCCESS", "readAccountFromDB", &"Read {username}'s data from Account tables.")
  return account

#================================================================
# db作成
proc createDB*(): void =
  let dbConn = connectDB()
  dbConn.createTables(newAccount())
  # TODO:ここにモデルを随時追加
  DebugLogging("SUCCESS", "createDB", "Create tables.")

# dbにinsert
proc insertDB*[T](model:var T): void =
  let dbConn = connectDB()
  dbConn.insert(model)
  DebugLogging("SUCCESS", "insertDB", &"Insert {T.type.`$`} data to tables.")
