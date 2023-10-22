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
