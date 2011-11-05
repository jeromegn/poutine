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

vows.describe("Has Many").addBatch(

  "once a connection is established":
    topic: ->
      Poutine.connect this.callback
      return

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
          assert.equal blog.posts_ids.length, 1
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
          assert.equal blog.posts_ids.length, 2
          assert.include blog.posts_ids, posts[0]._id
          assert.include blog.posts_ids, posts[1]._id
          
        "the children should have the parent id in the appropriate field": (blog, err, posts)->
          assert.equal posts[0].blog_id, blog._id
          assert.equal posts[1].blog_id, blog._id

).export(module)