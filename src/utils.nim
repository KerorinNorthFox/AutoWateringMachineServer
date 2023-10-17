import
  std/json,
  std/strformat,
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
  for key in keys:
    if not jsonBody.hasKey(key):
      DebugLogging("ERROR", "checkJsonKeys", &"JsonBody has not key '{key}'.")
      return true
  DebugLogging("SUCCESS", "checkJsonKeys", "All key is OK.")
  return false