% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mongoose.R
\name{mongoose}
\alias{mongoose}
\title{Mongoose file-backed storage back end}
\usage{
mongoose(uri, ...)
}
\arguments{
\item{uri}{The serivce uri, for instance \code{http://localhost:8000}.}

\item{...}{Optional service parameters including:
\itemize{
  \item{user}{Optional HTTP digest authentication user name}
  \item{password}{Optional HTTP digest authentication user password}
  \item{ssl_verifyhost}{Optional SSL/TLS host verification, defaults to 0 (no verification)}
  \item{ssl_verifypeer}{Optional SSL/TLS peer verification, defaults to 0 (no verification)}
  \item{redirect_limit}{Should be set to the mongoose cluster size, defaults to 3}
  \item{compress}{Compression function, defaults to \code{function(x) memCompress(x, type='gzip')}}
  \item{decompress}{De-compression function, defaults to \code{function(x) memDecompress(x, type='gzip')}}
}}
}
\description{
Specify connection details for a \code{mongoose} web service object store backend,
the default simple back end included in the share package.
}
\note{
The mongoose back end stores R values in compressed (unless compression=I), serialized form.
Default compression is gzip; change using the \code{compression} option.

Objects are stored as files in the path specified in the \code{path} argument of the
\code{\link{mongoose_start}} function, and can be directly accessed by R outside
of the share methods. See below for an example.
}
\examples{
# Start an example local mongoose backend server, serving data from a
# temporary directory:
tmp <- tempdir()
mongoose_start(path=tmp)
con <- connect()
# Store the 'iris' dataset in a directory named 'mydata', created as a
# sub-directory of 'tmp':
assign("mydata/iris", iris, con)
# The above data are stored in serialized, compressed form in the local
# file system path and can be directly accessed by R. For example:
file_path <- paste(tmp, "/mydata/iris", sep="")
unserialize(memDecompress(readBin(file_path, "raw", 1e7), type='gzip'))
}

