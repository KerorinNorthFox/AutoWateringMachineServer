import
  ../src/utils

let token = generateJwt(1, 1)
echo ">Token : " & token

let isOk = verifyJwt(token)
echo isOk.`$`