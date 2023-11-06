import
  prologue

# トップレベルドメイン
proc api*(ctx:Context) {.async.} =
  discard

# アカウント作成
proc createUser*(ctx:Context) {.async.} =
  discard

# ログイン
proc auth*(ctx:Context) {.async.} =
  discard

# ユーザー情報取得
proc readUser*(ctx:Context) {.async.} =
  discard

# ユーザー情報更新
proc updateUser*(ctx:Context) {.async.} =
  discard

# ユーザー削除
proc deleteUser*(ctx:Context) {.async.} =
  discard

# ハードウェア登録
proc registerHardware*(ctx:Context) {.async.} =
  discard

# ハードウェア情報取得
proc readHardware*(ctx:Context) {.async.} =
  discard

# ハードウェア情報更新
proc updateHardware*(ctx:Context) {.async.} =
  discard

