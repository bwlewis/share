#' Mongoose file-backed storage back end
#'
#' Specify connection details for a \code{mongoose} web service object store backend,
#' the default simple back end included in the share package.
#' @param uri The serivce uri, for instance \code{http://localhost:8000}.
#' @param ... Optional service parameters including:
#' \itemize{
#'   \item{user}{Optional HTTP digest authentication user name}
#'   \item{password}{Optional HTTP digest authentication user password}
#'   \item{ssl_verifyhost}{Optional SSL/TLS host verification, defaults to 0 (no verification)}
#'   \item{ssl_verifypeer}{Optional SSL/TLS peer verification, defaults to 0 (no verification)}
#'   \item{redirect_limit}{Should be set to the mongoose cluster size, defaults to 3}
#'   \item{compression}{Either 'lz4', 'xz', 'gzip' or 'none'.}
#' }
#' @note The mongoose back end stores R values in compressed (unless compression='none'), serialized form.
#' Default compression is lz4; change using the \code{compression} option.
#'
#' Objects are stored as files in the path specified in the \code{path} argument of the
#' \code{\link{mongoose_start}} function, and can be directly accessed by R outside
#' of the share methods. See below for an example.
#' @examples
#' # Start an example local mongoose backend server, serving data from a
#' # temporary directory:
#' tmp <- tempdir()
#' mongoose_start(path=tmp)
#' con <- connect()
#' # Store the 'iris' dataset in a directory named 'mydata', created as a
#' # sub-directory of 'tmp':
#' assign("mydata/iris", iris, con)
#' # The above data are stored in serialized, compressed form in the local
#' # file system path and can be directly accessed by R. For example:
#' file_path <- paste(tmp, "/mydata/iris", sep="")
#' unserialize(lz4::lzDecompress(readBin(file_path, "raw", 1e7)))
#' @export
mongoose = function(uri, ...)
{
  mycall = match.call()
  base = uri
  opts = list(...)

  if(is.null(opts$compression)) opts$compression = "lz4"
  if(is.null(opts$ssl_verifyhost)) opts$ssl_verifyhost = 0
  if(is.null(opts$ssl_verifypeer)) opts$ssl_verifypeer = 0
  if(is.null(opts$redirect_limit)) opts$redirect_limit = 3
  if(is.null(opts$xdr)) opts$xdr = FALSE

  serialize0 = function(x, con) if(is.raw(x)) x else serialize(x, con, xdr=opts$xdr)

  getfun = switch(opts$compression,
             lz4=function(x) unserialize(lz4::lzDecompress(x)),
             gzip=function(x) unserialize(memDecompress(x, type="gzip")),
             xz=function(x) unserialize(memDecompress(x, type="xz")),
             function(x) unserialize(x))
  putfun = switch(opts$compression,
             lz4=function(x) lz4::lzCompress(serialize0(x, NULL)),
             gzip=function(x) memCompress(serialize0(x, NULL), type="gzip"),
             xz=function(x) memCompress(serialize0(x, NULL), type="xz"),
             function(x) serialize(x, NULL))

  f = function(proto, ...)
  {
    if(proto == "show")
    {
      return(message("Mongoose service ", uri))
    }
    h = curl::new_handle()
    on.exit(curl::handle_reset(h), add = TRUE)
    if("user" %in% names(opts) && "password" %in% names(opts))
    {
      # digest authentication
      curl::handle_setopt(h, httpauth=2, userpwd=paste(opts$user, opts$password, sep=":"))
    }
    curl::handle_setopt(h, .list=list(ssl_verifyhost=opts$ssl_verifyhost, ssl_verifypeer=opts$ssl_verifypeer,
                                      maxredirs=opts$redirect_limit, followlocation=52))
    args = list(...)

    url = paste(base, urlEncodePath(args$key), sep="/") ## XXX urlencode
    if(!is.null(getOption("mongoose.debug"))) message(proto, ":", url)
    if(proto == "put")
    {
      curl::handle_setopt(h, .list = list(customrequest = "PUT"))
      data = putfun(args$value)
      curl::handle_setopt(h, .list=list(post=TRUE, postfieldsize=length(data), postfields=data))
      resp = curl::curl_fetch_memory(url, handle=h)
      if(resp$status_code > 299) stop("HTTP error ", resp$status_code)
      return(gsub(sprintf("%s/", base), "", resp$url))
    } else if(proto == "head")
    {
      curl::handle_setopt(h, .list = list(customrequest = "HEAD", nobody=TRUE))
      resp = curl::curl_fetch_memory(url, handle=h)
      if(resp$status_code > 299) stop("HTTP error ", resp$status_code)
      hdr = rawToChar(resp$headers)
      hdr = strsplit(hdr, "\r\n")[[1]][-1]
      hdr = hdr[nchar(hdr) > 0]
      n   = gsub(":.*", "", hdr)
      ans = Map(function(i) gsub(sprintf("^%s: ", n[i]), "", hdr[i]), 1:length(n))
      names(ans) = n
      ans$url = url
      return(ans)
    } else if(proto == "get")
    {
      resp = curl::curl_fetch_memory(url, handle=h)
      if(resp$status_code > 299) stop("HTTP error ", resp$status_code)
      hdr = rawToChar(resp$headers)
      type = tryCatch(
               gsub(" ", "", gsub("\\r\\n.*", "", strsplit(tolower(hdr),
                 split="content-type:")[[1]][2])), error=function(e) "application/binary")
      if(length(grep("application/json", type, ignore.case=TRUE) > 0)) # directory listing
      {
        ans = jsonlite::fromJSON(rawToChar(resp$content)) # XXX
        ans = ans[!(nchar(ans$key) == 0), ]
        ans$size = as.numeric(ans$size)
        return(ans)
      }
      return(getfun(resp$content)) ## XXX get rid of copy here? stream?
    }
    if(proto == "delete")
    {
      curl::handle_setopt(h, .list = list(customrequest = "DELETE"))
      resp = curl::curl_fetch_memory(url, handle=h)
      if(resp$status_code > 299) stop("HTTP error ", resp$status_code)
      return(resp$url)
    }
  }
  class(f) = "object_store"
  f
}

#' Start a Mongoose Service
#'
#' Manually start a local mongoose file-backed storage service.
#' @param path full path to data directory, defaults to the current working directory
#' @param port service port number
#' @param forward_to forward 'not found' requests to another server
#' @param ssl_cert optional SSL certificate for TLS-encrypted communication (if you specify this, the mongoose server will only use TLS encyption; otherwise no encryption is used)
#' @param auth_domain HTTP digest authentication domain/realm
#' @param global_auth HTTP digest global authentication file (with full path)
#' @note Leave parameters \code{NULL} to not use the corresponding features.
#' @seealso \code{\link{htdigest}}
#' @return Nothing; the mongoose server is started up as a background process.
#' @importFrom subprocess spawn_process
#' @export
mongoose_start = function(path=getwd(),
                          port=8000L,
                          forward_to=NULL,
                          ssl_cert=NULL,
                          auth_domain=NULL,
                          global_auth=NULL)
{
  if(!is.null(mongoose.env$handle)) mongoose_stop()
  exename = "backends/mongoose/mongoose"
  if(grepl("windows", Sys.info()["sysname"], ignore.case=TRUE))
  {
    exename = "backends/mongoose/mongoose.exe"
  }
  cmd = system.file(exename, package="share")
  if(nchar(cmd) == 0) stop("mongoose not found!")
  args = c("-l", 0, "-d", path)
  if(!is.null(port)) args = c(args, "-p", as.integer(port))
  if(!is.null(forward_to)) args = c(args, "-f", forward_to)
  if(!is.null(ssl_cert)) args = c(args, "-s", ssl_cert)
  if(!is.null(auth_domain)) args = c(args, "-a", auth_domain)
  if(!is.null(global_auth)) args = c(args, "-P", global_auth)
  assign("call", match.call(), envir=mongoose.env)
  assign("handle", spawn_process(cmd, args), envir=mongoose.env)
}

#' Stop a Running Mongoose Service
#' @importFrom subprocess process_state process_terminate
#' @export
mongoose_stop = function()
{
  if(is.null(mongoose.env$handle)) return(NULL)
  if(process_state(mongoose.env$handle) == "running") process_terminate(mongoose.env$handle)
  rm(list="handle", envir=mongoose.env)
}

#' Report the Status of the Mongoose Service
#' @export
mongoose_status = function()
{
  mongoose.env$handle
}

# Mongoose service state goes here:
mongoose.env = new.env()
