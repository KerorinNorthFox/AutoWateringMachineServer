import
  prologue,
  ./logging,
  ./utils

from ./models import checkUserExists

proc verifyToken*(): HandlerAsync =
  result = proc(ctx:Context) {.async.} =
    APILogging(ctx.request.reqMethod.`$`, ctx.request.path, "Success to "&ctx.request.path&"."):
      
      # Authorizationヘッダーをチェック
      if not ctx.request.hasHeader("Authorization"):
        resp(jsonResponse(%*{
          "is_success":"false",
          "message":"Authorization header requires."
          }, Http401)
        )
        Logging("401", "checkTokenMiddleware", "Authorization header requires.")
        return
      
      # Tokenをチェック
      let token: string = ctx.request.getHeader("Authorization")[0]
      Logging("INFO", "checkTokenMiddleware", "Got token : " & token)
      if not verifyJwt(token):
        resp(jsonResponse(%*{
          "is_success":"false",
          "message":"Invalid token."
          }, Http401)
        )
        Logging("401", "checkTokenMiddleware", "Invalid token.")
        return
      Logging("SUCCESS", "checkTokenMiddleware", "Authorization is successful.")
      
      # ユーザーが存在するかチェック
      if not checkUserExists(decodeJwt(token)):
        resp(jsonResponse(%*{
          "is_success":"false",
          "message":"The account does not exist."
          }, Http404)
        )
        Logging("404", ctx.request.path, "No such an account exists.")
        return
      
      await switch(ctx)