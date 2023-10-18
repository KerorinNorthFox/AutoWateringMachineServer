import
  std/os,
  std/strformat,
  std/strutils,
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

# アカウントの重複を確認する
proc checkDuplicateAccount*(value:string or int): bool =
  let key: string = (if value.type is int: "id" else: "email")
  let dbConn = connectDB()
  let isOk = dbConn.exists(Account, &"{key} = ?", value) # valueはemailかid
  DebugLogging("INFO", "checkDuplicateAccount", &"Checked if account is duplicate -> {$isOk}")
  return isOk

# AccountをDBからread
proc readAccountFromDB*(value:string or int): Account =
  let key: string = (if value.type is int: "id" else: "email")
  var account = newAccount()
  let dbConn = connectDB()
  if not dbConn.exists(Account, &"{key} = ?", value): # # valueはemailかid
    account = nil
    DebugLogging("ERROR", "readAccountFromDB", &"Read nobody's data from Account tables.")
  else:
    dbConn.select(account, &"{key} = ?", value)
    DebugLogging("SUCCESS", "readAccountFromDB", &"Read {account.username}'s data from Account tables.")
  return account

#================================================================
# db作成
proc createDB*(): void =
  let dbConn = connectDB()
  dbConn.createTables(newAccount())
  # TODO:ここにモデルを随時追加
  DebugLogging("INFO", "createDB", "Created tables.")

# dbにinsert
proc insertDB*[T](model:var T): void =
  let dbConn = connectDB()
  dbConn.insert(model)
  DebugLogging("INFO", "insertDB", &"Inserted {T.type.`$`} data to tables.")
