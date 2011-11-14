## How Poutine Is Better

### A Better Driver API

The MongoDB driver exposes all the features and complexities of the
MongoDB API.  For example, to run a simple query you need to initialize
a Server object and a Db object.

From there, you can open a new connection.  You need a callback.  Next,
you can get hold of a collection.  You need another callback.  Last, you
can run a `find` operation.  That takes another callback.

APIs like that make us sad.  They're as powerful as they are verbose.
So we decided to improve that using a combination of techniques.

For starters, we're separating connection configuration from the act of
acquiring and using a connection.  That allows you to configure all your
connections in one place.  You may have multiple for different
environments, e.g. development, test and production.

With Poutine you can write:

    configure = require("poutine").configure
    configure "development", host: "localhost"
    configure "production", host: "db.jupiter", pool: 50
    configure.default = process.env.NODE_ENV

Then, elsewhere in your application, access the right connection by
calling the `connect` function.

Poutine gives you a chained API that makes everything easier, and will
lazily acquire a pooled connection when you actually execute a command.
So to find all posts by an author you could:

    connect = require("poutine").connect
    posts = connect().collection("posts")
    posts.where(author_id: author._id).desc("created_at").all (error, posts, db)->
      ...

The chained API gives you a higher level of abstraction, for example:

    Posts.prototype.byAuthor = (author) ->
      return connect().collection("posts").where(author_id: author._id)

Of course, you can also go straight for the kill and do this:

    connect().find("posts", { author_id: author.id }, order: [["created_at", -1]], (error, posts, db)->
      ...

Other operations work the same way.  You can perform them directly on
the connection object, or use the chaining API for easier composition.


### We've Got Models Too




## Working With The Database


### Configuring Database Access

You use the `connect` function to obtain a new `Database` object,
representing a logical database connection.

You can call `connect()` with a database name, in which case it will
return a database connection based on the named configuration, or with
no arguments, in which case it will return the default configuration.

To create a database configuration, use `configure()`.  For example:

    { connect, configure } = require("poutine")
    configure "blog", host: "127.0.0.1"
    connect().count "posts", (err, count, db)->
      console.log "There are #{count} posts in the database"

Poutine picks the first configuration as the default configuration,
making it easy to work with a single configuration.

Another common case is having one configuration per environment, and
then using the configuration suitable for the current environment.  For
example:

    configure = require("poutine").configure
    configure "development", name: "myapp", host: "127.0.0.1"
    configure "test", name: "myapp-test", host: "127.0.0.1"
    configure "production", name: "myapp", host: "db.jupiter", pool: 50
    configure.default = process.env.NODE_ENV

Alternatively, you can load configurations from a JSON document:

    configure = require("poutine").configure
    configure fs.readFileSync("databases.json")
    configure.default = process.env.NODE_ENV

The JSON configuration document would look like this:

    { "development": {
        name: "myapp",
        host: "127.0.0.1"
      },
      "test": {
        name: "myapp-test",
        host: "127.0.0.1"
      },
      "production": {
        name: "myapp",
        host: "db.jupiter",
        pool: 50
      }
    }


## Life With Connections

Mostly it's just works out, but you still need to understand what to do
to handle special cases.

MongoDB uses one thread per TCP connection.  That should tell you two
things.  First, if your application opens and uses a single connection,
all the workload will be serialized in a single thread.  You won't get a
lot of scalability that way.  If it's a Web server, you'll want each
request to be using its own connection.

Second, if your application keeps opening and closing connections,
there's a lot of overhead involved in establishing these connections,
both TCP overhead and threads.  You want to reuse connections through
some pooling mechanism.

Poutine solves this by allowing you to open as many logical connections
as you want, but using a pool of TCP connections to handle those
requests.  Whenever you do an operation, like insert or query, it grabs
a connection from the pool, performs that operation, and then returns
the connection back to the pool.

That means that all you need to do is grab a connection and use it.  You
can use one connection throughout the application (but read below why
it's not such a good idea), or grab a new connection for each request.
You don't have to worry about closing the connection, the logical
connection is just a wrapper, and the TCP connections are pooled.

And this works flawlessly for most things you do, but there are a couple
of exceptions.  Say you're inserting a record into the database and then
using the same logical connection to query the database.  By default
Poutine grabs a TCP connection from the database for each of these
operations.  It's possible that the insert operation will not complete
before the find operation is started and you won't be able to query the
object you just created.

There are two ways around this.  You can insert safely, which blocks
until the insert operation completes.  Or you can tell Poutine to reuse
the same TCP connection.

Another scenario is using replica sets where each TCP connection may
read from a different slave.  It takes slaves some time to replicate, so
it's possible that one query will hit one server and find an object, but
another query will hit a different server and not find the very same
object.  Again, you can solve that by telling Poutine to reuse the same
TCP connection.

You do that by calling `begin` and `end`.  Calling `begin` fixes the TCP
connection, so all subsequent operations on that connection object will
use the same TCP connection.  You must follow up with a call to `end`,
otherwise the TCP connection is not available for other requests.

There's reference tracking, so if you're passing the connection to
another function that calls `begin` followed by `end`, the connection
doesn't get released on you.

Here's a simple example:

    # Use the same TCP connection for insert and find.
    db.begin (end)->
      db.insert "posts", { text: "Find me" }, (err, id)->
        db.find("posts", id).one (err, post)->
          assert post
          end()

Alternatively, with one less callback:


    # Use the same TCP connection for insert and find.
    end = db.begin()
    db.insert "posts", { text: "Find me" }, (err, id)->
      db.find("posts", id).one (err, post)->
        assert post
        end()



## Working With Collections

Almost everything you do with a MongoDB connection is related to one
collection or another.

To access a collection, call the `collection()` method with collection
name or model.  We'll talk about models later on.  For example:

    posts = connect().collection("posts")
    posts.count (error, count)->
      console.log("There are " + count + " posts")

Once you have a collection you can do a lot of interesting things.  For
example, you can find objects that are part of that collection:

    posts.where(author_id: author._id).each (err, post, db)->

The `where` method creates a new query from a single argument that
specifies the query criteria.

Queries are chained objects, so you can keep refining the query before
finally executing it:

    query.where(...)   # Add more query criteria
    query.fields(...)  # Specify which fields to load
    query.asc(...)     # Sort by ascending order
    query.desc(...)    # Sort by descending order
    query.limit(n)     # Load at most n records
    query.skip(n)      # Skip the first n records



