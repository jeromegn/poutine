(function() {
  var bonzo, decode64, highlight_code, keyStr, qwery, render_navigation;

  bonzo = require("bonzo");

  qwery = require("qwery");

  render_navigation = function() {
    var $sections, current_section, current_subsection;
    current_section = 0;
    current_subsection = 0;
    $sections = $("#sections");
    $sections.empty();
    return $("h1, h2, h3, h4, h5, h6").each(function(el) {
      var $subsection, section_id;
      if (el.tagName === "H2") {
        current_subsection = 0;
        current_section++;
        el.id = section_id = "section-" + current_section;
        return $sections.append("<li id=\"for-" + section_id + "\">\n  <a href=\"#" + section_id + "\">" + el.textContent + "</a>\n</li>");
      } else if (el.tagName === "H3") {
        current_subsection++;
        el.id = section_id = "section-" + current_section + "-" + current_subsection;
        $subsection = $("#for-section-" + current_section + " ul");
        if (!$subsection.length) {
          $("#for-section-" + current_section).append("<ul></ul>");
          $subsection = $("#for-section-" + current_section + " ul");
        }
        return $subsection.append("<li id=\"for-" + section_id + "\">\n  <a href=\"#" + section_id + "\">" + el.textContent + "</a>\n</li>");
      }
    });
  };

  highlight_code = function() {
    return $("pre code").each(function(el) {
      return hljs.initHighlighting(el);
    });
  };

  $.domReady(function() {
    var cached, using_cache;
    using_cache = false;
    if (cached = localStorage.getItem("cached")) {
      $("#content").html(cached);
      render_navigation();
      highlight_code();
      using_cache = true;
    }
    return $.ajax({
      url: "https://api.github.com/repos/jeromegn/poutine/git/trees/master?callback=?",
      type: "jsonp",
      success: function(resp) {
        var last_sha, obj, readme_sha, _i, _len, _ref;
        _ref = resp.data.tree;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          obj = _ref[_i];
          if (obj.path === "README.md") readme_sha = obj.sha;
        }
        last_sha = localStorage.getItem("last_sha");
        if (readme_sha !== last_sha) {
          return $.ajax({
            url: "https://api.github.com/repos/jeromegn/poutine/git/blobs/" + readme_sha + "?callback=?",
            type: "jsonp",
            success: function(resp) {
              var content, refresh_link;
              content = marked(decode64(resp.data.content));
              localStorage.setItem("cached", content);
              localStorage.setItem("last_sha", readme_sha);
              if (using_cache) {
                refresh_link = $("<a id='refresh' href='#'>There's a new version of the documentation<br>Click here or refresh to see it.</a>");
                $("body").append(refresh_link);
                return refresh_link.bind("click", function(event) {
                  event.preventDefault();
                  if (!using_cache) $("#content").html(content);
                  render_navigation();
                  highlight_code();
                  return refresh_link.remove();
                });
              }
            }
          });
        }
      }
    });
  });

  decode64 = function(input) {
    var chr1, chr2, chr3, enc1, enc2, enc3, enc4, i, output;
    output = "";
    chr1 = void 0;
    chr2 = void 0;
    chr3 = "";
    enc1 = void 0;
    enc2 = void 0;
    enc3 = void 0;
    enc4 = "";
    i = 0;
    input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
    while (true) {
      enc1 = keyStr.indexOf(input.charAt(i++));
      enc2 = keyStr.indexOf(input.charAt(i++));
      enc3 = keyStr.indexOf(input.charAt(i++));
      enc4 = keyStr.indexOf(input.charAt(i++));
      chr1 = (enc1 << 2) | (enc2 >> 4);
      chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
      chr3 = ((enc3 & 3) << 6) | enc4;
      output = output + String.fromCharCode(chr1);
      if (enc3 !== 64) output = output + String.fromCharCode(chr2);
      if (enc4 !== 64) output = output + String.fromCharCode(chr3);
      chr1 = chr2 = chr3 = "";
      enc1 = enc2 = enc3 = enc4 = "";
      if (!(i < input.length)) break;
    }
    return unescape(output);
  };

  keyStr = "ABCDEFGHIJKLMNOP" + "QRSTUVWXYZabcdef" + "ghijklmnopqrstuv" + "wxyz0123456789+/" + "=";

}).call(this);
