import
  std/json,
  std/os,
  std/strformat,
  std/tables,
  std/times,
  jwt

from ./logging import Logging

# 秘密鍵を読み込む
proc loadPrivateKey*(): string =
  let f: File = open(getAppDir() / "key/private.key", fmRead)
  result = f.readAll()
  f.close()
  Logging("INFO", "loadPrivateKey", "Loaded private key.")

# jsonの中に全てのキーが存在するか確認
proc checkJsonKeys*(jsonBody:JsonNode, keys:seq[string]): bool =
  if jsonBody.len > keys.len:
    Logging("ERROR", "checkJsonKeys", "Detected excess keys.")
    return false
  for key in keys:
    if not jsonBody.hasKey(key):
      Logging("ERROR", "checkJsonKeys", &"JsonBody has not key '{key}'.")
      return false
  Logging("SUCCESS", "checkJsonKeys", "All key is OK.")
  return true

# jwtでトークンを生成
proc generateJwt*(id:int, deadlineHour:int): string =
  var jwtToken = toJwt(%*{
    "header":{
      "alg":"HS256",
      "typ":"JWT"
    },
    "claims":{
      "userId":id,
      "exp":(getTime() + deadlineHour.hours).toUnix() # TODO: 期限を変える
    }
  })
  jwtToken.sign(loadPrivateKey())
  Logging("INFO", "generateJwt", &"Generated token by id '{$id}'.")
  return $jwtToken

# jwtでトークン認証
proc verifyJwt*(token:string): bool =
  try:
    result = token.toJwT().verify(loadPrivateKey(), HS256)
    Logging("SUCCESS", "verifyJwt", "Token varification is successful.")
  except:
    result = false
    Logging("ERROR", "verifyJwt", "Token varification is unsuccessful.")

# jwtでトークンからidを取り出し
proc decodeJwt*(token:string): int =
  result = token.toJWT().claims["userId"].node[].num
  Logging("INFO", "decodeJwt", &"Decoded token -> {$result}")
