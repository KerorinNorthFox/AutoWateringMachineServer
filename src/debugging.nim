import
  std/os,
  std/strformat,
  std/times

const isDebug {.booldefine.} : bool = true

when isDebug:
  if not dirExists(getAppDir() / "log"):
      createDir(getAppDir() / "log")

  proc debugLogging*(level, procName, message:string): void =
    let nowTime = now().format("yyyy-MM-dd HH:mm:ss")
    let log = &"[{level}]:{procName} -> {message} : " & nowTime
    echo log
    let f = open(getAppDir() / "log" / "log.txt", fmAppend)
    f.writeLine(log)
    f.close()

else:
  proc debugLogging*(level, text:string): void =
    discard