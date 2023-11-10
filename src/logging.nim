import
  std/os,
  std/strformat,
  std/times

const isDebug {.booldefine.} : bool = true

when isDebug:
  # ログを保存するディレクトリがないとき作る
  let log_path: string = getAppDir() / "log"
  if not dirExists(log_path):
    createDir(log_path)

  # ログを出力
  proc Logging*(level, procName, message:string): void =
    let nowTime: string = now().format("yyyy-MM-dd HH:mm:ss")
    let logText: string = &"[{level}]:{procName} -> {message} -> " & nowTime
    echo logText
    let f: File = open(getAppDir() / "log" / "log.txt", fmAppend)
    f.writeLine(logText)
    f.close()

  # apiにアクセスした時のログを出力
  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    Logging(reqMethod, path, "Http"&reqMethod&" comes.")
    body
    Logging("200", path, message)

else:
  proc Logging*(level, text:string): void =
    discard

  template APILogging*(reqMethod, path, message:string, body:untyped): untyped =
    body