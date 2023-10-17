import
  std/os,
  prologue,
  ./urls

from ./models import createDB

# webアプリ管理クラス
type App = ref object
  app: Prologue

# initialize
proc init(_:type App): App =
  let 
    env = loadPrologueEnv(getAppDir() / ".env")
    settings = newSettings(
      appName = env.getOrDefault("appName", "Prologue"),
      debug = env.getOrDefault("debug", true),
      port = Port(env.getOrDefault("port", 8080)),
      secretKey = env.getOrDefault("secretKey", "")
    )
  result = App()
  result.app = newApp(settings=settings)
  result.app.addRoute(urlPatterns, "/api")
  result.app.addRoute(account_urlPatterns, "/api/account")

# サーバースタート
proc start(self:App): void =
  if not fileExists(getAppDir() / "db.sqlite"): # db.sqliteがない場合dbを作成
    createDB()
  self.app.run()

when isMainModule:
  let application = App.init()
  application.start()

