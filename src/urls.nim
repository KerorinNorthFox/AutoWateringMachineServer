import
  prologue,
  ./middlewares,
  ./views

let
  urlPatterns* = @[
  pattern("/", api, HttpGet), # ドメイン
  pattern("/auth", auth, HttpPost), # アカウント認証
  pattern("/create-account", createAccount, HttpPost) # アカウント作成
  ]

  account_urlPatterns* = @[
    pattern("/", readAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/update", updateAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/delete", deleteAccount, HttpPost, middlewares = @[checkTokenMiddleware()]),
  ]
