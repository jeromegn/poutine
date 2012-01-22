(function() {
  var decode64, keyStr;

  window.DocumentUp = (function() {

    function DocumentUp() {}

    DocumentUp.template = function(locals) {
      return "<nav id=\"nav\">\n  <header>\n    <a href=\"#\" id=\"logo\">" + locals.name + "</a>\n  </header>\n  <ul id=\"sections\">\n  </ul>\n</nav>\n<div id=\"content\">\n  <div id=\"loader\">\n    Loading documentation...\n  </div>\n</div>";
    };

    DocumentUp.defaults = {
      color: "#369",
      twitter: null,
      changelog: false,
      travis: false
    };

    DocumentUp.document = function(options) {
      var key, repo, value, _base, _ref;
      var _this = this;
      this.options = options;
      if ("string" === typeof this.options) {
        repo = this.options;
        this.options = {
          repo: repo
        };
      }
      if (!this.options || !this.options.repo || !/\//.test(this.options.repo)) {
        throw new Error("Repository required with format: username/repository");
      }
      _ref = this.defaults;
      for (key in _ref) {
        value = _ref[key];
        if (!this.options[key]) this.options[key] = value;
      }
      (_base = this.options).name || (_base.name = this.options.repo.replace(/.+\//, ""));
      $.domReady(function() {
        var $nav, extra, iframe, twitter, _i, _len, _ref2, _results;
        $("body").html(_this.template(_this.options));
        $("head").append("<style type=\"text/css\">\n  a {color: " + _this.options.color + "}\n</style>");
        $nav = $("#nav");
        if (_this.options.travis) {
          $nav.append("<div id=\"travis\" class=\"extra\">\n  <a href=\"http://travis-ci.org/" + _this.options.repo + "\">Travis CI</a>\n  <a href=\"http://travis-ci.org/" + _this.options.repo + "\">\n    <img src=\"https://secure.travis-ci.org/" + _this.options.repo + ".png\">\n  </a>\n</div>");
        }
        if (_this.options.twitter) {
          if (!(_this.options.twitter instanceof Array)) {
            _this.options.twitter = [_this.options.twitter];
          }
          _ref2 = _this.options.twitter;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            twitter = _ref2[_i];
            twitter = twitter.replace("@", "");
            extra = $("<div class='extra twitter'>");
            iframe = $('<iframe allowtransparency="true" frameborder="0" scrolling="no" style="width:162px; height:20px;">');
            iframe.attr("src", "https://platform.twitter.com/widgets/follow_button.html?screen_name=" + twitter + "&show_count=false");
            extra.append(iframe);
            _results.push($nav.append(extra));
          }
          return _results;
        }
      });
      return this.getReadme(function(err, html) {
        _this.html = html;
        if (err) throw err;
        return $.domReady(function() {
          return _this.renderContent();
        });
      });
    };

    DocumentUp.getReadme = function(callback) {
      var html, using_cache;
      var _this = this;
      using_cache = false;
      if (html = localStorage.getItem("cached_content")) {
        callback(null, html);
        this.usingCache = true;
      }
      return $.ajax({
        url: "https://api.github.com/repos/" + this.options.repo + "/git/trees/master?callback=?",
        type: "jsonp",
        success: function(resp) {
          var last_sha, obj, readme_sha, _i, _len, _ref;
          _ref = resp.data.tree;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            obj = _ref[_i];
            if (/readme/i.test(obj.path)) readme_sha = obj.sha;
          }
          last_sha = localStorage.getItem("readme_sha");
          if (readme_sha !== last_sha) {
            return $.ajax({
              url: "https://api.github.com/repos/" + _this.options.repo + "/git/blobs/" + readme_sha + "?callback=?",
              type: "jsonp",
              success: function(resp) {
                html = marked(decode64(resp.data.content));
                localStorage.setItem("cached_content", html);
                localStorage.setItem("readme_sha", readme_sha);
                if (!_this.usingCache) return callback(null, html);
                return $.domReady(function() {
                  var refresh_link;
                  var _this = this;
                  refresh_link = $("<a id='refresh' href='#'>There's a new version of the documentation<br>Click here or refresh to see it.</a>");
                  $("body").append(refresh_link);
                  return refresh_link.bind("click", function(event) {
                    event.preventDefault();
                    callback(null, html);
                    return refresh_link.remove();
                  });
                });
              }
            });
          }
        }
      });
    };

    DocumentUp.renderContent = function() {
      var $sections, current_section, current_subsection;
      $("#content").html(this.html);
      current_section = 0;
      current_subsection = 0;
      $sections = $("#sections");
      $sections.empty();
      $("h1, h2, h3, h4, h5, h6").each(function(el) {
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
      return $("pre code").each(function(el) {
        return hljs.initHighlighting(el);
      });
    };

    return DocumentUp;

  })();

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
