exports.template = ->
  p ->
    text "Drag the link below to your bookmarks bar."
    br()
    br()
    a id: "bookmarklet", href: "javascript: window.location=%22http://ycatalyst.com/submit?url=%22+encodeURIComponent(document.location)+%22&title=%22+encodeURIComponent(document.title)", -> "YCat Submit"

exports.sass = """
  #bookmarklet
    :font-size 1.3em
"""
