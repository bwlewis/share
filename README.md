# NOTICE

This is a somewhat old experimental package R object cache.  Don't use it for
anything other than experimentation. Instead, consider using the similar
package, https://github.com/richfitz/storr.

The project is simpler than storr, however. And it includes a self-contained
and cross-platform networked object storage service.


# Share: Easy Networked R Object Sharing

The share package presents an extremely simple interface to networked object
storage. The package includes a self-contained, cross-platform and lightweight
file-backed binary object storage service and can interface to other object
service APIs like Amazon S3.  The share package supports GET/PUT/DELETE-style
operations using base R functions `get()` and `assign()` along with a
`delete()` function.

A simple cross-platform file-backed object storage service is provided by the
included Mongoose web service, but we also plan to support minio
(https://minio.io) and Amazon S3 object storage services and probably others
like Azure.

## Status
<a href="https://travis-ci.org/bwlewis/share">
<img src="https://travis-ci.org/bwlewis/share.svg?branch=master" alt="Travis CI status"></img>
</a>

![codecov.io](https://codecov.io/github/bwlewis/share/coverage.svg?branch=master)

## Installation (R example)

You'll need the `devtools` package, for instance from `install.packages("devtools")`.

```{r}
devtools::install_github("bwlewis/share")
```

## Quickstart (R example)

```{r}
library(share)
mongoose_start(path=tempdir())        # starts a local mongoose server on port 8000
                                      # serving data from a local temporary directory
con <- connect()                      # connect to the local mongoose back end
assign("cars", head(cars), con)       # put head(cars) in the object "cars"
assign("Nile", head(Nile), con)       # put head(Nile) in "Nile"
assign("mystuff/iris", iris, con)     # put a copy of iris in a "mystuff" subdirectory

get("/", con)                         # list the contents
get("",  con)                         # alternative syntax
       key               mod size
1     cars 30-Sep-2017 05:26  215
2     Nile 30-Sep-2017 05:26   83
3 mystuff/ 30-Sep-2017 05:26   NA

get("mystuff", con)                   # list contents of mystuff
   key               mod size
1 iris 30-Sep-2017 05:26 4892

head(get("mystuff/iris", con))        # retrieve iris from the object store
#   Sepal.Length Sepal.Width Petal.Length Petal.Width Species
# 1          5.1         3.5          1.4         0.2  setosa
# 2          4.9         3.0          1.4         0.2  setosa
# 3          4.7         3.2          1.3         0.2  setosa
# 4          4.6         3.1          1.5         0.2  setosa
# 5          5.0         3.6          1.4         0.2  setosa
# 6          5.4         3.9          1.7         0.4  setosa

env = as(con, "environment")          # Object store as a promise environment

ls(env)
# "cars"     "mystuff" "Nile"

env$cars                              # evalue 'cars' promise
#   speed dist
# 1     4    2
# 2     4   10
# 3     7    4
# 4     7   22
# 5     8   16
# 6     9   10
```
Notice that evaluation  in the last example downloads the `cars` data set and
replaces the promise with the downloaded in the `env` environment; see
`?promises` in R's help for details..


## Use case

We (Mike Kane and I and others) often see a need for, as simply as possible,
sharing native R values like data frames and matrices between R processes
running across many computers.  Good options are of course available,
including:

* Networked file systems like NFS (perhaps the simplest option)
* Networked databases including key/value stores

But we wanted an approach that works out of the box without dependencies, and
could optionally work with some more sophisticated external systems without
modification. We also wanted speed, multiple options for scalability, speed,
the simplicity of a file system, _and most important, we want to work with data
in native form to minimize or eliminate data marshaling/serialization cost._
And speed.

We see our approach working well with lightweight distributed computing systems
that are decoupled from I/O like R's foreach and doRedis packages
(https://github.com/bwlewis/doRedis), and Python's superb celery system
(http://www.celeryproject.org/).

## Anti use case

The share package is *not* a database. Right now, no claims to data consistency
are made and a lot of things are left up to the clients (R, whatever). Think of
it as a very crude networked object caching service.  Forthcoming back ends may
support varying consistency levels, but even so share is not a database. Use a
database if you think you need a database.  Or, coordinate activity in the
store using a known-consistent external system like
https://github.com/coreos/etcd !

## Features

* Cross-platform for Windows, Mac OS X and Linux systems
* Simple, familiar get/assign operations
* Modular storage back ends: mongoose (default), minio, Amazon S3, ...

## Storage back ends

The package is equipped with a self-contained and simple but fast HTTP/S
back end service that uses Mongoose (see below for many more details).

But share is designed to work with arbitrary object storage systems.
Future support for the S3 protocol is planned.

## Back end API

The share package requires storage back ends to support the following REST-like
operations:

* get
* put
* delete
* head

These operations directly correspond to HTTP 1.1 verbs, and map to the
corresponding high-level R package methods `assign()`, `get()`, and functions
`delete()` and `info()`.

## Mongoose back end

The package includes a back end based on Cesanta's excellent mongoose web
server (https://github.com/cesanta/mongoose) with TLS encryption, digest
authentication, optional auto-forwarded requests between servers in a cluster,
and JSON directory listings.

The Mongoose service can be invoked directly by the share package for ad hoc
use, or optionally installed as a system service.

Data stored by mongoose are relative to a user-configurable data directory and
are stored in plain old files that can be read directly (without the networked
object storage service).

Mongoose data files and directories are directly compatible with minio (local
S3) data and can be used interchangeably with that service when it's ready.


## A bit more on the use case

You might be thinking, why not just use Redis (http://redis.io) or whatever?
Indeed Redis is pretty awesomely fast, well-supported across multiple operating
systems, and has tons of features beyond simple GET/PUT. But Redis has some
issues too, for example, values are limited to a relatively small size.  And if
you want to just copy the "database" for offline analysis or backup, the values
and keys are not simple files and need to be accessed through Redis itself.
Those issues are typical of many databases. Mongodb (https://www.mongodb.org/)
and RethinkDB (http://rethinkdb.com/), for instance, are superb document
databases.  But values are limited to a very small size, although GridFS
(https://docs.mongodb.org/manual/core/gridfs/) is an option but that brings
additional configuration complexity, and they're geared to working with
structured values in JSON form, not arbitrary serialized R objects.

Apache Geode (http://geode.incubator.apache.org/) is super fast, has very
large value size limits (terabytes), and provides very strong consistency
in distributed settings to boot. Not bad! But it's a huge software project
with a gigantic footprint that needs to be installed and maintained on a
cluster. Which is fine if that's what you're already using, but might be
a pain if you just want a fast way to share data across a bunch of R and
Python processes.

Finally, very traditional networked databases like PostgreSQL and MySQL can
store binary blobs and be used just like this, while also providing added
transactional and consistency protections on the data. I seriously considered
using PostgreSQL for this project in fact, and indeed it still could be
outfitted as another modular back end. But I found the object store path
compelling because of the potential scalability/performance potential of
minio with their "XL" erasure-coded back end, and of course the proven
scalability of S3 (at least if you're running in Amazon's ecosystem).

The share package, by contrast, is trivially simple. Just point the built-in
Mongoose service to a directory and serve data. Or use an S3 back end.

# More documentation:

## Mongoose back end
https://github.com/bwlewis/share/blob/master/inst/backends/mongoose/README.md

The package includes a basic HTTP/S object store service based on the
Cesanta mongoose web server (https://github.com/cesanta/mongoose).

See https://github.com/bwlewis/share/blob/master/inst/backends/mongoose/README.md
for more information and details on installing the mongoose back end as a system
service.

## minio back end
Not ready yet!

## Amazon S3 back end
Not ready yet!

## Azure blob store back end
Not ready yet!
