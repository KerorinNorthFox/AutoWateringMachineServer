import
  ../src/models,
  norm/sqlite

createDB()
var user = newUser("kerorinnf", "neko", "gmail")
insertAtDB(user)

user = readUserFromDB("gmail")
echo user.username
echo user.password