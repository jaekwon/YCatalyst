(function() {
  var include;
  include = function(filename) {
    var script;
    script = document.createElement('script');
    script.src = filename;
    script.type = 'text/javascript';
    return $(document.head).append(script);
  };
  $(document).ready(function() {
    var root;
    include("/static/record.js");
    if ($('[data-root="true"]').length > 0) {
      root = $('[data-root="true"]:eq(0)');
      return $.ajax({
        cache: false,
        type: "GET",
        url: "/r/" + (root.attr('id')) + "/recv",
        dataType: "json",
        error: function() {
          return alert("error");
        },
        success: function(data) {
          if (data) {
            return alert(data);
          }
        }
      });
    }
  });
}).call(this);
