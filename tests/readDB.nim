import
  ../src/models,
  norm/sqlite

createDB()
var account = newAccount(username="kerorinnf", password="pw", email="a@g")
insertDB(account)
var ac = readAccountFromDB("kerorinnf")
echo "Inserted Account: " & ac[].`$`

let a = checkDuplicateAccount("a@g")
echo "True email result : " & a.`$`

let b = checkDuplicateAccount("a")
echo "False emmail result : " & b.`$`