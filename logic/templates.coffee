###
# YCatalyst
# Copyright(c) 2011 Jae Kwon (jae@ycatalyst.com)
# MIT Licensed
###

coffeekup = require '../static/coffeekup'
coffeescript = require 'coffee-script'
sass = require 'sass'
utils = require '../utils'
Markz = require('../static/markz').Markz
config = require '../config'

# autoreloading of templates for development environment
template_mtimes = {}
template_require = (filename) ->
  path = require.resolve("../templates/#{filename}.coffee")
  if config.env and config.env == 'development'
    stat = require('fs').statSync(path)
    if not template_mtimes[path] or template_mtimes[path] < stat.mtime
      console.log "loading templates/#{filename}.coffee template..."
      template_mtimes[path] = stat.mtime
      delete require.cache[path]
  return require(path)

exports.render_layout = (template, context, req, res) ->
  # helper to render with layout, mind the closure. much like 'render :partial' in rails.
  # this way you can always call 'render' from within template code, and
  # the closure will be carried through.
  _render = (template, context) ->
    # these should be rather static entities that extend the language as a DSL.
    # typical dynamic parameters should go in 'context'.
    locals =
      require: require
      render: _render
      static_file: utils.static_file
      Markz: Markz
    if req?
      context.current_user = req.current_user
    tmpl_module = template_require(template)
    # compile the coffeekup render fn
    if not tmpl_module._compiled_fn?
      if not tmpl_module.template?
        throw new Error "The template file #{template} does not export a 'template' coffeekup function"
      try
        tmpl_module._compiled_fn = coffeekup.compile tmpl_module.template, dynamic_locals: true
      catch err
        console.log "err in compiling #{template}: " + err
        throw err
    # plugin: sass
    if tmpl_module.sass and not tmpl_module["_compiled_sass"]?
      try
        tmpl_module["_compiled_sass"] = _csass = sass.render(tmpl_module.sass)
        if not _csass
          console.log "Warning: sass for template is empty: #{template}"
      catch err
        console.log "err in compiling sass for #{template}: " + err
        throw err
    # plugin: coffeescript
    if tmpl_module.coffeescript and not tmpl_module["_compiled_coffeescript"]?
      try
        if typeof tmpl_module.coffeescript == 'function'
          tmpl_module["_compiled_coffeescript"] = "(#{""+tmpl_module.coffeescript})();"
        else
          tmpl_module["_compiled_coffeescript"] = coffeescript.compile(tmpl_module.coffeescript)
      catch err
        console.log "err in compiling coffeescript for #{template}: " + err
        throw err
    # compile the body
    html = ''
    try
      html += tmpl_module._compiled_fn(context: context, locals: locals)
      if tmpl_module._compiled_coffeescript
        html += "\n<script type='text/javascript'>#{tmpl_module._compiled_coffeescript}</script>"
      if tmpl_module._compiled_sass
        html += "\n<style type='text/css'>#{tmpl_module._compiled_sass}</style>"
    catch err
      console.log "err in rendering #{template}: " + err
      throw err
    return html

  layout_context = {}
  layout_context.title = 'YCatalyst' if not context.title?
  layout_context.body_template = template
  layout_context.body_context = context
  layout_context.current_user = req.current_user
  html = _render('layout', layout_context)
  if res?
    res.writeHead 200, status: 'ok'
    res.end html

