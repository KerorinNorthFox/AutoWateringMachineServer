import
  std/os,
  std/strformat,
  std/strutils,
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
  result: bool = dbConn.exists(Account, &"{key} = ?", value) # valueはemailかid
  DebugLogging("INFO", "checkDuplicateAccount", &"Checked if account is duplicate -> {$isOk}")

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

# AccountをDBからread
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
