## Version 0.2  2011-11-24

This is a complete rewrite based on some ideas I haven't seen anywhere else.

Tell me this is not awesome:

    class User extends Model
      @collection "users"

      @field "name", String

      @field "password", String
      @set "password", (clear)->
        @_.password = crypt(clear)

      @field "email", String

      @get "posts", ->
        Post.where(author_id: @_id)


    me = User.where(name: "Assaf")
    me.one (error, user)->
      console.log "Loaded #{user.name}"
      user.posts.count (error, count)->
        console.log "Published #{count} posts"
