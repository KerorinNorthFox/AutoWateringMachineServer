import
  prologue,
  ./middlewares,
  ./views

let
  urlPatterns* = @[
  pattern("/api", api, HttpGet), # ドメイン
  pattern("/api/auth", auth, HttpPost), # アカウント認証
  pattern("/api/create_account", createAccount, HttpPost) # アカウント作成
  ]

  account_urlPatterns* = @[
    pattern("/", readAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/update", updateAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/delete", deleteAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
  ]
