import
  std/os,
  std/strformat,
  std/times

const isDebug {.booldefine.} : bool = true

when isDebug:
  # ログを保存するディレクトリがないとき作る
  let log_path = getAppDir() / "log"
  if not dirExists(log_path):
    createDir(log_path)

  # ログを出力
  proc DebugLogging*(level, procName, message:string): void =
    let nowTime = now().format("yyyy-MM-dd HH:mm:ss")
    let logText = &"[{level}]:{procName} -> {message} -> " & nowTime
    echo logText
    let f = open(getAppDir() / "log" / "log.txt", fmAppend)
    f.writeLine(logText)
    f.close()

  # apiにアクセスした時のログを出力
  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    DebugLogging(reqMethod, path, "Http"&reqMethod&" comes.")
    body
    DebugLogging("200", path, message)

else:
  proc DebugLogging*(level, text:string): void =
    discard

  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    body