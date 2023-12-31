import 
  prologue,
  ./debugging,
  ./utils

proc checkTokenMiddleware*(): HandlerAsync =
  result = proc(ctx:Context) {.async.} =
    APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to "&ctx.request.path&"."):
      # Authorizationヘッダーをチェック
      if not ctx.request.hasHeader("Authorization"):
        resp(jsonResponse(%*{
          "is_success":"false",
          "message":"Authorization header requires."
          }, Http401)
        )
        DebugLogging("401", "checkTokenMiddleware", "Authorization header requires.")
        return
      # Tokenをチェック
      let token: string = ctx.request.getHeader("Authorization")[0]
      DebugLogging("INFO", "checkTokenMiddleware", "Got token : " & token)
      if not verifyJwt(token):
        resp(jsonResponse(%*{
          "is_success":"false",
          "message":"Invalid token."
          }, Http401)
        )
        DebugLogging("401", "checkTokenMiddleware", "Invalid token.")
        return
      DebugLogging("SUCCESS", "checkTokenMiddleware", "Authorization is successful.")
      await switch(ctx)