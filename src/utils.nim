import
  std/json,
  std/strformat,
  std/times,
  jwt,
  ./debugging

# 秘密鍵を読み込む
proc loadPrivateKey*(): string =
  let f: File = open("./key/private.key", fmRead)
  defer:
    f.close()
    DebugLogging("INFO", "loadPrivateKey", "Loaded private key.")
  return f.readAll()

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
proc generateJwt*(id:int): string =
  let private_key = loadPrivateKey()
  var token = toJwt(%*{
    "header":{
      "alg":"HS256",
      "typ":"JWT"
    },
    "claims":{
      "userId":id,
      "exp":(getTime() + 3.days).toUnix() # TODO: 期限を変える
    }
  })
  token.sign(private_key)
  DebugLogging("INFO", "generateJwt", &"Generated token by id '{$id}'")
  return $token