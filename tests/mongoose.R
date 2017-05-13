check = function(a, b)
{
  print(match.call())
  stopifnot(all.equal(a, b, check.attributes=FALSE, check.names=FALSE))
}

library("rs3")
mongoose_start()                      # start a local mongosse service
con <- connect()                      # connect to the local mongoose service
assign("mystuff/iris", iris, con)     # put a copy of iris in the 'mystuff' directory
assign("mystuff/cars", cars, con)     # put a copy of cars in the 'mystuff' directory
d <- get("mystuff", con)              # list the contents of 'mystuff'
check(all(c("cars", "iris") %in% d$key), TRUE)
x <- get("mystuff/iris", con)         # retrieve iris from the cache
check(iris, x)

# weird characters
n <- assign("mystuff/~ ! @#$%^&*()-_=+[]{}:;\"'<>,.?`", iris, con)
x <- get(n, con)
check(iris, x)

# delete 'mystuff' path
delete("mystuff", con)

mongoose_stop()
