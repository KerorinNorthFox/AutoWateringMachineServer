import
  std/json,
  std/os,
  std/strformat,
  std/tables,
  std/times,
  jwt,
  ./debugging

# 秘密鍵を読み込む
proc loadPrivateKey*(): string =
  let f: File = open(getAppDir() / "key/private.key", fmRead)
  result = f.readAll()
  f.close()
  DebugLogging("INFO", "loadPrivateKey", "Loaded private key.")

# jsonの中に全てのキーが存在するか確認
proc checkJsonKeys*(jsonBody:JsonNode, keys:seq[string]): bool =
  if jsonBody.len != keys.len:
    DebugLogging("ERROR", "checkJsonKeys", "Detected excess keys.")
    return false
  for key in keys:
    if not jsonBody.hasKey(key):
      DebugLogging("ERROR", "checkJsonKeys", &"JsonBody has not key '{key}'.")
      return false
  DebugLogging("SUCCESS", "checkJsonKeys", "All key is OK.")
  return true

# jwtでトークンを生成
proc generateJwt*(id:int, deadlineHour:int): string =
  let private_key: string = loadPrivateKey()
  var token = toJwt(%*{
    "header":{
      "alg":"HS256",
      "typ":"JWT"
    },
    "claims":{
      "userId":id,
      "exp":(getTime() + deadlineHour.hours).toUnix() # TODO: 期限を変える
    }
  })
  token.sign(private_key)
  DebugLogging("INFO", "generateJwt", &"Generated token by id '{$id}'.")
  return $token

# jwtでトークン認証
proc verifyJwt*(token:string): bool =
  let private_key:string = loadPrivateKey()
  try:
    let jwtToken = token.toJwT()
    result = jwtToken.verify(private_key, HS256)
    DebugLogging("SUCCESS", "verifyJwt", "Token varification is successful.")
  except:
    result = false
    DebugLogging("ERROR", "verifyJwt", "Token varification is unsuccessful.")

# jwtでトークンからidを取り出し
proc decodeJwt*(token:string): int =
  let jwtToken = token.toJWT()
  result = jwtToken.claims["userId"].node[].num
  DebugLogging("INFO", "decodeJwt", &"Decoded token -> {$result}")
