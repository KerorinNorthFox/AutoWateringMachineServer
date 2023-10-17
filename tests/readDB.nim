import
  ../src/models

createDB()
var account = newAccount(username="kerorinnf", password="pw", email="a@g")
insertDB(account)
var a = readAccountFromDB("kerorinnf")
doAssert a.type.`$` == "Account"
