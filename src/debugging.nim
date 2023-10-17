import
  std/os,
  std/strformat,
  std/times

const isDebug {.booldefine.} : bool = true

when isDebug:
  # ログを保存するディレクトリがないとき作る
  if not dirExists(getAppDir() / "log"):
    createDir(getAppDir() / "log")

  # ログを出力
  proc DebugLogging*(level, procName, message:string): void =
    let nowTime = now().format("yyyy-MM-dd HH:mm:ss")
    let log = &"[{level}]:{procName} -> {message} -> " & nowTime
    echo log
    let f = open(getAppDir() / "log" / "log.txt", fmAppend)
    f.writeLine(log)
    f.close()

  # apiにアクセスした時のログを出力
  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    DebugLogging(reqMethod, path, "Http"&reqMethod&" comes.")
    body
    DebugLogging("SUCCESS", path, message)

else:
  proc DebugLogging*(level, text:string): void =
    discard

  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    body