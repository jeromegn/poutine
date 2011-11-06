vows = require("vows")
assert = require("assert")
Async = require "async"
{Poutine} = require("./helpers")

random = -> Math.random().toString().substr(3)

class Blog extends Poutine.Model
  fields:
    name: String
  
  @extend Poutine.Collection
  @include Poutine.Document

  @hasMany "posts"

class Post extends Poutine.Model
  fields:
    title: String
    body : String
  
  @extend Poutine.Collection
  @include Poutine.Document

  @belongsTo "blog"

  #@index {title: 1, blog_id: 1}, {unique: true}

vows.describe("Has Many").addBatch(

  "a saved `hasMany` model instance":
    topic: ->
      blog = new Blog name: "Test blog"
      blog.save @callback
      return
    
    "should not err": (err, blog)->
      assert.isNull err

    "should have access to the `hasMany` relation": (err, blog)->
      assert.instanceOf blog.posts, Poutine.Proxy.HasMany
    
    "creating a child instance":
      topic: (blog)->
        blog.posts.create {title: "test post", body: "lorem ipsum somethin' somethin'"}, (err, post)=>
          @callback(blog, err, post)
        return
      
      "should not err": (blog, err, post)->
        assert.isNull err
      
      "should return an instance of the child model": (blog, err, post) ->
        assert.instanceOf post, Post
      
      "should add the child model's id to the parent's proxy Array field": (blog, err, post) ->
        assert.include blog.posts_ids, post._id
        
      "the child should have the parent id in the appropriate field": (blog, err, post)->
        assert.equal post.blog_id, blog._id
    
    "creating two child instances":
      topic: ->
        blog = new Blog(name: "new blog")
        blog.save (err)=>
          return @callback(blog, err) if err 
          posts = [
            {title: "another test post", body: "lorem ipsum somethin' somethin'"}
            {title: "another test post", body: "lorem ipsum somethin' somethin'"}
          ]
          savedPosts = []
          Async.forEach(posts, (post, cb)->
            blog.posts.create {title: "another test post", body: "lorem ipsum somethin' somethin'"}, (err, post)=>
              return cb(err) if err
              savedPosts.push post
              cb()
          , (err)=>
            return @callback(blog, err) if err
            @callback(blog, null, savedPosts)
          )
        return
      
      "should not err": (blog, err, posts) ->
        assert.isNull err
      
      "should add the children model's id to the parent's proxy Array field": (blog, err, posts) ->
        assert.include blog.posts_ids, posts[0]._id
        assert.include blog.posts_ids, posts[1]._id
        
      "the children should have the parent id in the appropriate field": (blog, err, posts)->
        assert.equal posts[0].blog_id, blog._id
        assert.equal posts[1].blog_id, blog._id
    
    "pushing existing records into the parent's proxy field":
      topic: (blog) ->
        post = new Post(title: "test man", body: "lorem")
        post.save (err) =>
          blog.posts.push post, @callback
        return
      
      "should not err": (err, blog, post) ->
        assert.isNull err
      
      "should return the parent as second arg w/ array including the child": (err, blog, post) ->
        assert.instanceOf blog, Blog
        assert.include blog.posts_ids, post._id
      
      "should return the child as last arg w/ reference to the parent": (err, blog, post) ->
        assert.instanceOf post, Post
        assert.equal post.blog_id, blog._id
    
    "pushing an ObjectID into the proxy field":
      topic: (blog) ->
        post = new Post(title: "test 2", body: "lorem bro")
        post.save (err) =>
          blog.posts.push post._id, @callback
        return
      
      "should not err": (err, blog, post) ->
        assert.isNull err
      
      "should return the parent as second arg w/ array including the child": (err, blog, post) ->
        assert.instanceOf blog, Blog
        assert.include blog.posts_ids.map((oid)->oid.toString()), post._id.toString()
        
        # Not sure why that line below doesn't work
        # assert.include blog.posts_ids, post._id
      
      "should return the child as last arg w/ reference to the parent": (err, blog, post) ->
        assert.instanceOf post, Post
        assert.equal post.blog_id, blog._id
    
    "finding child models":
      topic: (blog) ->
        blog.posts.find().all (err, posts) =>
          @callback(err, posts, blog)
        return
      
      "should not err": (err, posts, blog) ->
        assert.isNull err

      "should return instances of the child model w/ the right parent id": (err, posts, blog)->
        assert.instanceOf posts[0], Post
        posts.forEach (post) ->
          assert.equal post.blog_id.toString(), blog._id.toString()
      
).export(module)