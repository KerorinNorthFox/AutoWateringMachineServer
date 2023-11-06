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
  if jsonBody.len != keys.len:
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
  let private_key: string = loadPrivateKey()
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
  jwtToken.sign(private_key)
  Logging("INFO", "generateJwt", &"Generated token by id '{$id}'.")
  return $jwtToken

# jwtでトークン認証
proc verifyJwt*(token:string): bool =
  let private_key: string = loadPrivateKey()
  try:
    let jwtToken = token.toJwT()
    result = jwtToken.verify(private_key, HS256)
    Logging("SUCCESS", "verifyJwt", "Token varification is successful.")
  except:
    result = false
    Logging("ERROR", "verifyJwt", "Token varification is unsuccessful.")

# jwtでトークンからidを取り出し
proc decodeJwt*(token:string): int =
  let jwtToken = token.toJWT()
  result = jwtToken.claims["userId"].node[].num
  Logging("INFO", "decodeJwt", &"Decoded token -> {$result}")
