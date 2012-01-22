bonzo = require("bonzo")
qwery = require("qwery")

render_navigation = ->
  current_section = 0
  current_subsection = 0

  $sections = $("#sections")

  $sections.empty()

  $("h1, h2, h3, h4, h5, h6").each (el)->
    if el.tagName == "H2"
      current_subsection = 0
      current_section++
      el.id = section_id = "section-#{current_section}"
      $sections.append """
        <li id="for-#{section_id}">
          <a href="##{section_id}">#{el.textContent}</a>
        </li>
      """
    else if el.tagName == "H3"
      current_subsection++
      el.id = section_id = "section-#{current_section}-#{current_subsection}"
      $subsection = $("#for-section-#{current_section} ul")
      unless $subsection.length
        $("#for-section-#{current_section}").append("<ul></ul>")
        $subsection = $("#for-section-#{current_section} ul")
      $subsection.append """
        <li id="for-#{section_id}">
          <a href="##{section_id}">#{el.textContent}</a>
        </li>
      """

highlight_code = ->
  $("pre code").each (el)->
    hljs.initHighlighting(el)

render_content = (html)->
  $("#content").html html
  render_navigation()
  highlight_code()

$.domReady ->
  using_cache = false
  
  if cached = localStorage.getItem("cached")
    render_content(cached)
    using_cache = true

  $.ajax
    url: "https://api.github.com/repos/jeromegn/poutine/git/trees/master?callback=?"
    type: "jsonp"
    success: (resp)->
      readme_sha = obj.sha for obj in resp.data.tree when obj.path == "README.md"
      last_sha = localStorage.getItem("last_sha")
      
      if readme_sha != last_sha
        $.ajax
          url: "https://api.github.com/repos/jeromegn/poutine/git/blobs/#{readme_sha}?callback=?"
          type: "jsonp"
          success: (resp)->
            content = marked(decode64(resp.data.content))
            localStorage.setItem("cached", content)
            localStorage.setItem("last_sha", readme_sha)
            
            return render_content(content) unless using_cache
              
            refresh_link = $("<a id='refresh' href='#'>There's a new version of the documentation<br>Click here or refresh to see it.</a>")
            $("body").append(refresh_link)
            refresh_link.bind "click", (event)->
              event.preventDefault()
              render_content(content)
              refresh_link.remove()

decode64 = (input) ->
  output = ""
  chr1 = undefined
  chr2 = undefined
  chr3 = ""
  enc1 = undefined
  enc2 = undefined
  enc3 = undefined
  enc4 = ""
  i = 0
  input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "")
  loop
    enc1 = keyStr.indexOf(input.charAt(i++))
    enc2 = keyStr.indexOf(input.charAt(i++))
    enc3 = keyStr.indexOf(input.charAt(i++))
    enc4 = keyStr.indexOf(input.charAt(i++))
    chr1 = (enc1 << 2) | (enc2 >> 4)
    chr2 = ((enc2 & 15) << 4) | (enc3 >> 2)
    chr3 = ((enc3 & 3) << 6) | enc4
    output = output + String.fromCharCode(chr1)
    output = output + String.fromCharCode(chr2)  unless enc3 is 64
    output = output + String.fromCharCode(chr3)  unless enc4 is 64
    chr1 = chr2 = chr3 = ""
    enc1 = enc2 = enc3 = enc4 = ""
    break unless i < input.length
  unescape output

keyStr = "ABCDEFGHIJKLMNOP" + "QRSTUVWXYZabcdef" + "ghijklmnopqrstuv" + "wxyz0123456789+/" + "="