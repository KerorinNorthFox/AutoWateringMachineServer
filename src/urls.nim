import
  prologue,
  ./middlewares,
  ./views

let
  urlPatterns* = @[
  pattern("/api", api, HttpGet), # ドメイン
  pattern("/api/auth", auth, HttpPost), # アカウント認証
  pattern("/api/create_account", create_account, HttpPost) # アカウント作成
  ]

  account_urlPatterns* = @[
    pattern("/", read_account, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/update", update_account, HttpPost, middlewares = @[checkTokenMiddleware()]),
    pattern("/delete", delete_account, HttpPost, middlewares = @[checkTokenMiddleware()]),
  ]
