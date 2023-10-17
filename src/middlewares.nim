import prologue

proc checkTokenMiddleware*(): HandlerAsync =
  result = proc(ctx:Context) {.async.} =
    # TODO: Tokenを認証する処理
    await switch(ctx)