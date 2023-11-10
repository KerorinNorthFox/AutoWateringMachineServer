import
  prologue,
  ./middlewares,
  ./views

let
  urlPatterns* = @[
  # トップレベルドメイン
  pattern("/", api, HttpGet),
  # アカウント作成
  pattern("/create-user", createUser, HttpPost),
  # ログイン
  pattern("/auth", auth, HttpPost),
  ]

  account_urlPatterns* = @[
    # ユーザー情報取得
    pattern("/", readUser, HttpGet, middlewares = @[verifyToken()]),
    # ユーザー情報更新
    pattern("/update", updateUser, HttpPost, middlewares = @[verifyToken()]),
    # ユーザー削除
    pattern("/delete", deleteUser, HttpPost, middlewares = @[verifyToken()]),
    # ハードウェア登録
    pattern("/register", registerHardware, HttpPost, middlewares = @[verifyToken()]),
    # ハードウェア情報取得
    pattern("/{name}", readHardware, HttpGet, middlewares = @[verifyToken()]),
    # ハードウェア情報更新
    pattern("/{name}/update", updateHardware, HttpPost, middlewares = @[verifyToken()]),
    # ハードウェアの最新の温度取得
    pattern("/{name}/temperature/latest", readLatestTemperature, HttpGet, middlewares = @[verifyToken()]),
    # ハードウェアの温度をDBに格納
    pattern("/{name}/temperature", insertTemperature, HttpPost, middlewares = @[verifyToken()]),
  ]
