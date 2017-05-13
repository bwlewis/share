setOldClass("object_store")

#' Print a summary of a \code{object_store} object
#' @param object an object of class \code{object_store}
#' @return printed object summary
#' @export
setMethod("show", "object_store",
  function(object) {
    .object_storestr(object)
  })
#' Print a summary of a \code{object_store} SciDB database connection object
#' @param x  \code{object_store} object
#' @return printed object summary
#' @export
setMethod("print", signature(x="object_store"),
  function(x) {
    .object_storestr(x)
  })
#' Print a summary of an \code{object_store} connection object
#' @param x \code{object_store} object
#' @param ... optional arguments (not used)
#' @return printed object summary
#' @method print object_store
#' @importFrom methods setAs
#' @export
print.object_store = function(x, ...)
{
  .object_storestr(x)
}

setAs("object_store", "environment", function(from)
{
  toenv(from)
})

#' Convert an object store connection object to an environment full of promises
#' @param x an object store, see \code{connect()}, \code{\link{setAs}}
#' @param base base path
#' @return an environment
#' @keywords internal function
#' @examples
#' \dontrun{
#' # Start an example local mongoose backend server
#' mongoose_start(path=tempdir())
#' con <- connect()
#' # Store some data as objects...
#' assign("cars", head(cars), con)
#' assign("Nile", head(Nile), con)
#' # ...more objects in a directory named 'mydata':
#' assign("mydata/iris", head(iris), con)
#' # Represent the connection as an environment
#' e = as(con, "environment")
#' ls(e)
#' e$cars
#' (e$"mydata/")$iris
#' mongoose_stop()
#' }
toenv = function(x, base="")
{
  d = get(base, x)
  e = new.env()
  for(j in seq(nrow(d)))
  {
   obj = gsub("/", "", d$key[j])
   if(nchar(base) > 0) obj = paste(base, obj, sep="/")
   if(is.na(d$size[j]))
   {
     l = new.env()
     l$expr = substitute(toenv(x, y), list(x=x, y=obj))
     delayedAssign(d$key[j], eval(expr), eval.env=l, assign.env=e)
   } else
   {
     l = new.env()
     l$expr = substitute(get(o, x), list(o=obj, x=x))
     delayedAssign(d$key[j], eval(expr), eval.env=l, assign.env=e)
   }
  }
  e
}

.object_storestr = function(x)
{
  x("show")
}

setGeneric("get")
#' Retrieve a Value from an Object Store
#'
#' Retrieve a value corresponding to the specified name \code{x} from the object store service
#' connection \code{pos}. The method is analagous to the standard R \code{get()} function.
#' If \code{x} corresponds to a directory path, then a data frame listing
#' the directory contents is returned. Set \code{x=""} to list the contents of the
#' service root directory path.
#' @param pos An object store connection from \code{\link{connect}}.
#' @param x A key name, optionally including a \code{/} separated directory path.
#' @param mode Optional, set \code{mode="url"} to return the URL of the specified object.
#' @return Either a data frame directory listing when \code{x} corresponds to a directory,
#' or an R value corresponding to \code{x}.
#' @note Directory entries in the data frame directory listing output are identified by \code{size=NA}.
#' @seealso \code{\link{connect}} \code{\link{assign,character,ANY,object_store-method}} \code{\link{remove}}
#' @examples
#' # Start an example local mongoose backend server
#' mongoose_start(path=tempdir())
#' con <- connect()
#' # Cache the 'iris' dataset in a directory named 'mydata':
#' assign("mydata/iris", head(iris), con)
#' # Retrieve it from the object store
#' get("mydata/iris", con)
#' # Retrieve only the (character) url of the object:
#' get("mydata/iris", con, mode="url")
#' # Delete the entire 'mydata' directory
#' delete("mydata", con)
#' mongoose_stop()
#' @export
setMethod("get", signature(x="character", pos="object_store"),
  function(x, pos)
  {
    if(x == "/") x = ""
    x = gsub("//", "/", x)
    pos("get", key=x)
  })
setMethod("get", signature(x="character", pos="object_store", envir="ANY", mode="character"),
function(x, pos, envir, mode)
  {
    if(x == "/") x = ""
    x = gsub("//", "/", x)
    if(tolower(mode) == "url") return(info(x, con)$url)
    pos("get", key=x)
  })


#' Upload an R Value to an Object Store
#'
#' Upload the R \code{value} to the object store connection \code{pos} with the key name and
#' optional path specified by \code{x}. This method is analagous to the standard R
#' \code{assign()} function.
#' @param x A key name, optionally including a \code{/} separated directory path
#' @param value Any serializeable R value.
#' @param pos An object store connection from \code{\link{connect}}.
#' @return A character string corresponding to the url of the uploaded object.
#' @note Key names are url-encoded and may be changed (\code{assign()} returns the uri of the
#' stored value). The forward slash character \code{/} is NOT url-encoded and reserved for directory
#' path information. Do not use any slash (forward or backward) in your key names, they will
#' be interpreted as directory separators.
#' @seealso \code{\link{connect}} \code{\link{get,character,object_store-method}} \code{\link{remove}}
#' @examples
#' # Start an example local mongoose backend server
#' mongoose_start(path=tempdir())
#' con <- connect()
#' # Store the 'iris' dataset in a directory named 'mydata':
#' assign("mydata/iris", iris, con)
#' # Retrieve it from the object store into a new variable called 'x'
#' x <- get("mydata/iris", con)
#' # Delete the entire 'mydata' directory
#' delete("mydata", con)
#' mongoose_stop()
#' @export
setMethod("assign", signature(x="character", value="ANY", pos="object_store"),
  function(x, value, pos)
  {
    pos("put", value=value, key=x, xdr=getOption("share.xdr"))
  })
