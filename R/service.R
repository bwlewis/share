#' Register an Object Store Service
#'
#' Register an object store service backend, including backend-specific options
#' like authentication, encryption, and compression.
#' @param url The service root url including protocol, address and port number. For example \code{http://localhost:8000}.
#' @param backend A service backend provider function. The default is \code{mongoose}, but you may choose from other available
#' backends like \code{minio} and {s3}.
#' @param ... Backend-specific arguments, see backend documentation for details.
#' @return An object of class \code{object_store}, really a function usable by \code{assign}, \code{get}, \code{delete}, and \code{info}.
#' @seealso \code{\link{mongoose}} \code{link{get,character,object_store-method}} \code{\link{assign,character,ANY,object_store-method}} \code{\link{delete}}
#' @examples
#' # Start an example local mongoose backend server
#' mongoose_start(path=tempdir())
#' con <- connect()
#' # Store part of the 'iris' dataset in a directory named 'mydata':
#' assign("mydata/iris", head(iris), con)
#' # Retrieve it from the object store:
#' get("mydata/iris", con)
#' # Retrieve the URL of the object:
#' get("mydata/urus", con, mode="url")
#' # Delete the entire 'mydata' directory
#' delete("mydata", con)
#' mongoose_stop()
#' @export
connect = function(url="http://localhost:8000", backend=mongoose, ...)
{
  backend(url, ...)
}

#' Deleta a Value or Directory from an Object Store
#'
#' Delete the value or directory corresponding to the specified \code{key} from the object store service
#' connection \code{con}.
#' This function roughly corresponds to R's \code{remove()} function.
#' @param key A key name, optionally including a \code{/} separated directory path
#' @param con An object store connection from \code{\link{connect}}.
#' @return \code{NULL} is invisibly returned, or an error may be thrown.
#' @seealso \code{\link{connect}} \code{\link{assign,character,ANY,object_store-method}} \code{\link{get,character,object_store-method}}
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
delete = function(key, con)
{
  con("delete", key=key)
  invisible()
}

#' Retrieve Metadata from an Object Store
#'
#' Retrieve metadata like last modified time and size corresponding to the specified \code{key} from the object store service
#' connection \code{con}. If \code{key} corresponds to a directory, then a data frame listing
#' the directory contents is returned.
#' @param con An object store connection from \code{\link{connect}}.
#' @param key A key name, optionally including a \code{/} separated directory path.
#' @return Either a data frame directory listing when \code{key} corresponds to a directory,
#' or an R list of headers and their values corresponding to \code{key}.
#' @note Corresponds to the HTTP \code{HEAD} operations. Directory entries in the data frame directory listing output are identified by \code{size=NA}.
#' @seealso \code{\link{connect}} \code{\link{get}} \code{\link{delete}}
#' @examples
#' # Start an example local mongoose backend server
#' mongoose_start(path=tempdir())
#' con <- connect()
#' # Store the 'iris' dataset in a directory named 'mydata':
#' assign("mydata/iris", iris, con)
#' # Print some info about it
#' info("mydata/iris", con)
#' # Retrieve it from the object store into a new variable called 'x'
#' x <- get("mydata/iris", con)
#' # Delete the entire 'mydata' directory
#' delete("mydata", con)
#' mongoose_stop()
#' @export
info = function(key, con)
{
  con("head", key=key)
}
