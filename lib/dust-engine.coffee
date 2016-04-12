path                       = require 'path'
fs                         = require 'fs'
HOMEDIR                    = path.join(__dirname,'..')
IS_INSTRUMENTED            = fs.existsSync( path.join(HOMEDIR,'lib-cov') )
LIB_DIR                    = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
Util                       = require('inote-util').Util
FileUtil                   = require('inote-util').FileUtil
ObjectUtil                 = require('inote-util').ObjectUtil
yargs                      = require 'yargs'
DEFAULT_TEMPLATE_EXTENSION = ".dust"

# Lazily require `dustjs-linkedin` so that this file can be
# instantiated without having `dustjs-linkedin` available.
# (In that case the `options.dust` value must be provided in
# the DustEngine constructor.)
maybe_require_dustjs_linkedin = ()->
  require('dustjs-linkedin')

# Lazily require `dustjs-helpers` so that this file can be
# instantiated without having `dustjs-helpers` available.
maybe_require_dustjs_helpers = ()->
  require('dustjs-helpers')

# Lazily require `common-dustjs-helpers` so that this file can be
# instantiated without having `common-dustjs-helpers` available.
# (In that case the string-valued `common-dustjs-helpers`
# element of the `options.helpers` array passed to the DustEngine
# constructor will is not supported, as this require will fail.
maybe_require_common_dustjs_helpers = ()->
  require('common-dustjs-helpers').CommonDustjsHelpers

class DustEngine

  #
  # Create a new instance of the DustEngine.
  #
  # Note that the underlying `dust` processor will be availble as `this.dust`.
  #
  #---------
  # OPTIONS
  #---------
  #
  #  * `dust` - The dust.js template processor for example, as returned by
  #       `require('dustjs-linkedin')` or `require('dust-helpers')`. When
  #        omitted `require('dustjs-linkedin')` is used.
  #
  #  * `helpers` - A list (array) of "helpers" to register with the dust
  #       template processor.  Items in the list may be:
  #         - A function, in which case `element(dust)` will be invoked
  #         - An object containing one of the following functions,
  #           in which case `element.method(dust)` will be invoked.
  #             - `export_to`
  #             - `exportTo`
  #             - `set_dust`
  #             - `setDust`
  #         - The string `common-dustjs-helpers`, in which case the
  #           `CommonDustjsHelpers` library from
  #           <https://github.com/rodw/common-dustjs-helpers>
  #           will be loaded and registered with `dust`.
  #         - The string `dustjs-helpers`, in which case the helpers from
  #           <https://github.com/linkedin/dustjs-helpers>
  #           will be loaded and registered with `dust` IF AND ONLY IF
  #           options.dust was not previously set.
  #
  #  * `preserve_newlines` - when `true`, all `\n` characters found in templates
  #       will be converted to `{~n}` prior to processing the template.
  #
  #  * `use_cache` - when `true`, "compiled" templates will be cached (by name
  #       or filename); otherwise no caching will be applied, including dust's
  #       own internal cache
  #
  #  * `base_context` - when provided, the given object will be used as the
  #       root context for all template processing.  The context supplied with
  #       an individual call to `render` will be layered "on top" of this one.
  #
  #  * `base_options` - when provided, the given object will provide default
  #       values passed to dust's `on_load` callback.  The options passed
  #       as the second argument to `on_load` will be merged onto the
  #       `base_options` value, such that the given values will override
  #       those found in `base_options`.
  #
  #  * `template_root` - when provided, template paths will be considered
  #       relative to this directory. Defaults to the current working directory.
  #
  #  * `template_extension` - extension added to the end of template names when
  #       looking for templates as files.  Defaults to `.dust`. For example,
  #       by default, when loading a template via `{>foo/}` will look for a file
  #       named `foo.dust` (relative to the template root).  Pass the value `false`
  #       (or an empty string) to disable this automatic appending.
  #
  #  * `no_onload` - when `true`, the DustEngine will not set the `onLoad`
  #       "callback" dust uses when attempting to load a previously unknown
  #       template.  You probably only want to do this if you've set a
  #       custom `dust.onLoad` function for some reason, otherwise "including"
  #       templates via `{>template_name/}` and so on is not likely to work.
  #
  #  * `template_not_found` - when a function is provided, if the DustEngine's
  #       `onLoad` function is asked to load a template that it cannot find,
  #       it will delegate to the `template_not_found` method (rather than
  #       throwing an exception).  The signature of the `template_not_found`
  #       method is the same as dust's `onLoad` function, namely:
  #       `(template_name, options, function callback(err,template_content)`).
  #
  constructor:(options)->
    options ?= {}
    if options.dust?
      @dust = options.dust
    else
      if @_array_includes_match options.helpers, /^dustjs(-|_)?helpers$/i
        @dust = maybe_require_dustjs_helpers()
      else
        @dust = maybe_require_dustjs_linkedin()
    if options.helpers?
      unless Array.isArray(options.helpers)
        options.helpers = [options.helpers]
      for helper in options.helpers
        if typeof helper is 'function'
          helper(@dust)
        else if helper.export_to? and typeof helper.export_to is 'function'
          helper.export_to(@dust)
        else if helper.exportTo?  and typeof helper.exportTo is 'function'
          helper.exportTo(@dust)
        else if helper.set_dust?  and typeof helper.set_dust is 'function'
          helper.set_dust(@dust)
        else if helper.setDust?   and typeof helper.setDust is 'function'
          helper.setDust(@dust)
        else if typeof helper is 'string' and /^common(-|_)?dust(-|_)?js(-|_)?helpers$/i.test helper
          (new (maybe_require_common_dustjs_helpers())()).export_to @dust
    @template_root = @_get_template_root(options)
    @template_extension = @_get_template_extension(options)
    @preserve_newlines = @_get_preserve_newlines(options)
    @template_not_found = @_get_tempate_not_found(options)
    @use_cache = @_get_use_cache(options)
    if @use_cache
      @cache = {}
    @base_context = @_get_base_context(options)
    @base_options = @_get_base_options(options)
    if @_get_on_load(options)
      @dust.onLoad = @_get_on_load(options)
    else unless @_get_no_onload(options)
      @dust.onLoad = (t,o,c)=>@on_load(t,o,c) # dust relies on onLoad.length to determine whether or not to pass options, so force the signature directly (otherwise the CoffeeScript-generated signature doens't match)

  # When caching is enabled, returns the "compiled" (function)
  # version of the template with the given name (or path) or
  # `null` if no such template is available.
  get_cached_template:(key)=>
    template = null
    if @use_cache
      cached = @cache[key]
      if cached? and typeof cached is 'function'
        template = cached
    return template

  # When caching is enabled, sets the "compiled" (function)
  # version of the template with the given key
  # othewise clears DUST's cache to prevent caching
  set_cached_template:(key,template)=>
    if @use_cache
      @cache[key] = template
    else
      @dust.cache = {}

  # This is the "callback" function that is registered as
  # `dust.onLoad` by default.
  #
  # It will attempt to discover the specified template
  # based on the `template_root` and `template_extension`
  # defined in the options passed to the DustEngine
  # constructor, set in the given `options` or set
  # in the current `base_options`.
  #
  # Callback signature: (err,template_as_string)
  on_load:(template_name,options,callback)=>
    if typeof options is 'function' and not callback?
      callback = options
      options = null
    options ?= {}
    if @base_options?
      options = ObjectUtil.merge(@base_options,options)
    template_root = @_get_template_root(options)
    template_path = @_resolve_template_path(template_root,template_name)
    @_maybe_check_that_file_exists template_path, template_name, options, callback, ()=>
      fs.readFile template_path, { encoding: (options.encoding ? 'utf8') }, (err,data)=>
        if err?
          callback(err)
        else
          data = data?.toString?()
          if @_get_preserve_newlines(options)
            data = data.replace /\n/g, "\n{~n}"
          callback(null,data)

  # loads AND compiles
  # Callback signature: (err,compiled_template)
  load_template:(template_name,options,callback)=>
    if typeof options is 'function' and not callback?
      callback = options
      options = null
    @on_load template_name, options, (err,data)=>
      if err?
        callback(err)
      else
        template = @compile_template(data)
        if options.template_name? and not @_get_ignore_cache(options)
          @set_cached_template(template_name,template)
        callback(null,template)

  # compiles the given `template_string` into a dust template function
  compile_template:(template_string)=>@dust.compileFn(template_string)

  # executes the given `template` (a template name or pre-compiled function)
  # for the given context (if any)
  render_template:(template,context,callback)=>
    if typeof context is 'function' and not callback?
      callback = context
      context = null
    unless typeof template is 'function'
      template = @compile_template(template)
    ctx = @create_dust_context(context)
    template(ctx,callback)

  # get the specified template from the cache, or load it if necessary
  get_template:(template_name,options,callback)=>
    if typeof options is 'function' and not callback?
      callback = options
      options = null
    options ?= {}
    unless @_get_ignore_cache(options)
      cached = @get_cached_template(template_name)
    if cached?
      callback(null,cached)
    else
      @load_template(template_name,options,callback)

  create_dust_context:(ctx,meta_ctx)=>
    if Array.isArray(ctx) and ctx.length is 2 and not meta_ctx?
      meta_ctx = ctx[1]
      ctx = ctx[0]
    base =  @dust.makeBase(@base_context,meta_ctx)
    return base.push(ctx)

  render_for_express:(view_name, context, callback)=>
    @get_template view_name, (err,template)=>
      if err?
        callback(err)
      else
        @render_template(template,context,callback)

  # Use the dust engine to render the given `template_string` for the given `context`.
  # Callback signature: (err,content)
  render_dust_template_from_string:(template_string,context,options,callback)=>
    if typeof options is 'function' and not callback?
      callback = options
      options = null
    else if typeof context is 'function' and not options? and not callback?
      callback = context
      context = null
    options ?= {}
    preserve_newlines = @_get_preserve_newlines(options)
    if preserve_newlines
      template_string = template_string.replace /\n/g, "\n{~n}"
    template = @compile_template(template_string)
    if options.template_name? and not @_get_ignore_cache(options)
      @set_cached_template(options.template_name,template)
    @render_template(template,context,callback)

  # Callback signature: (err,content)
  render:(template_file,context,options,callback)=>
    @render_dust_template_from_file(template_file,context,options,callback)

  # Use the dust engine to render the template in the given `template_file` for the given `context`.
  # Callback signature: (err,content)
  render_dust_template_from_file:(template_file,context,options,callback)=>
    if typeof options is 'function' and not callback?
      callback = options
      options = null
    options ?= {}
    template_path = @_resolve_template_path(@_get_template_root(options),template_file)
    @_maybe_check_that_file_exists template_path, template_file, options, callback, ()=>
      fs.readFile template_path, { encoding: (options.encoding ? 'utf8') }, (err,template_string)=>
        if err?
          callback(err)
        else
          template_string = template_string?.toString()
          options.template_name ?= template_file
          @render_dust_template_from_string(template_string,context,options,callback)


  # determines template root based on the given options, this.template_root or process.cwd()
  _get_template_root:(options = {})=>
    options.template_root ? options.template_dir ? options.view_root ? options.view_dir ? options.viewroot ? @template_root ? process.cwd()

  # determines the template extension based on the given options, this.template_extension and the default (`.dust`)
  _get_template_extension:(options = {})=>
    extension = options.template_extension ? options.templateExtension ? options.template_ext ? options.templateExt ? @template_extension
    unless extension is false or extension is ''
      extension ?= DEFAULT_TEMPLATE_EXTENSION
      unless /^\./.test extension
        extension = ".#{extension}"
    return extension

  # determines the "ignore_cache" value based on the given options
  _get_ignore_cache:(options = {})=>
    Util.truthy_string(options.no_cache ? options.disable_cache or options.ignore_cache ? options.noCache ? options.disableCache ? options.ignoreCache ? options.cache in [false,'false'] ? false)

  # determines the "on_onload" value based on the given options
  _get_no_onload:(options = {})=>
    Util.truthy_string(options.no_onload or options.no_onLoad or options.noOnload or options.noOnLoad or ((options.onLoad is false) or (options.onload is false) or (options.on_load is false)))

  # determines the "reserve_newlines" value based on the given options
  _get_preserve_newlines:(options = {})=>
    Util.truthy_string(options.preserve_newlines ? options.preserveNewlines ? @preserve_newlines ? false)

  # determines the "use_cache" value based on the given options
  _get_use_cache:(options = {})=>
    Util.truthy_string(options.use_cache ? options.useCache ? @use_cache ? false)

  # determines the "base_context" value based on the given options
  _get_base_context:(options = {})=>
    options.base_context ? options.baseContext ? @base_context ? {}

  # determines the "base_options" value based on the given options
  _get_base_options:(options = {})=>
    options.base_options ? options.baseOptions ? @base_options ? {}

  # determines the "on_load" value based on the given options
  _get_on_load:(options = {})=>
    options.onLoad ? options.on_load ? options.onload ? null

  # determines the "template_not_found" value based on the given options
  _get_template_not_found:(options = {})=>
    options.template_not_found ? options.templateNotFound ? options.templatenotfound ? @template_not_found ? null

  # when `_get_template_not_found(options)` returns a non-null value,
  # check that `filename` exists.  If the file at `filename` cannot be found,
  # invokes `template_not_found(template_name,options,original_callback)`
  # otherwise invokes `cb()`
  _maybe_check_that_file_exists:(filename,template_name,options,original_callback,cb)=>
    template_not_found = @_get_tempate_not_found(options)
    if template_not_found?
      fs.exists filename, (exists)=>
        if exists
          cb()
        else
          template_not_found(template_name,options,original_callback)
    else
      cb()

  # computes the filename (and path) for `template_name`
  # relative to the `template_root` (if specified).
  # note that `.dust` is automatically appended to the
  # template name if the template name doesn't already end
  # in `.dust`.
  _resolve_template_path:(template_root,template_name)=>
    if template_root? and not template_name?
      template_name = template_root
      template_root = null
    template_root ?= @template_root
    if @template_extension and not @_string_ends_with(template_name, @template_extension)
      template_name = "#{template_name}.dust"
    if template_root?
      template_path = path.resolve(template_root,template_name)
    else
      template_path = path.resolve(template_name)
    return template_path

  # returns `true` if `str` ends with `suffix`
  _string_ends_with:(str,suffix)=>
    (str.substr(-1 * suffix.length) is suffix)

  # returns `true` if some string in `list` matches the given `pattern`
  _array_includes_match:(list,pattern)=>
    list ?= []
    if typeof list is 'string'
      return pattern.test list
    else
      for elt in list
        if pattern.test elt
          return true
      return false

  @main:()=>
    ERROR_INVALID_CLP   = 1
    ERROR_CONTEXT_PARSE = 2
    ERROR_DURING_RENDER = 3
    # READ COMMAND LINE PARAMETERS
    argv       = null
    # verbose logging
    ERROR = -1
    WARN  = 0
    LOG   = 1
    INFO  = 2
    DEBUG = 3
    FINE  = 4
    vlog = (level,args...)=>
      if level is ERROR
        console.error args...
      else
        if level <= argv.verbose
          args = args.map (arg)=>
            if arg? and arg.constructor is Object
              return JSON.stringify(arg,null,2)
            else
              return arg
          console.log args...
    options    = {}
    options.t  = { alias: "template",          describe: "Dust template", required:true }
    options.r  = { alias: "template-root",     describe: "Root directory for relative template paths; defaults to parent of template" }
    options.j  = { alias: "context-json",      describe: "Dust context as a JSON string" }
    options.c  = { alias: "context",           describe: "Dust context as a JSON file" }
    options.o  = { alias: "output",            describe: "Output file; defaults to stdout" }
    options.q  = { alias: "quiet",             describe: "Be less chatty.", boolean:true, default:false }
    options.n  = { alias: "preserve-newlines", describe: "When truthy, newlines in templates will be preserved.", boolean:true, default:false }
    arg_parser = yargs.options(options)
    arg_parser.help().alias('h','help')
    arg_parser.count('verbose').alias('v','verbose').describe('verbose',"Be more chatty")
    arg_parser.usage('Usage: $0 [OPTIONS]')
    argv       = arg_parser.argv
    vlog FINE, "Read the following from the command line:", argv
    # NORMALIZE COMMAND LINE PARAMETERS
    if argv.quiet
      argv.verbose = argv.v = 0
    if argv.output is "-"
      argv.o = argv.output = null
    # HANDLE HELP
    if argv.help
      yargs.showHelp()
      process.exit(0)
    # CHECK COMMAND LINE PARAMETERS
    if argv.j? and argv.c?
      vlog ERROR, "ERROR: Cannot use both --context and --context-json at the same time."
      process.exit ERROR_INVALID_CLP
    # PARSE CONTEXT
    context = null
    if argv.j?
      vlog INFO, "Reading context from command line."
      try
        context = JSON.parse(argv.j)
      catch err
        vlog ERROR, "ERROR trying to load context from --context-json JSON string."
        vlog ERROR, "error:",err
        vlog ERROR, "input:",argv.j
        process.exit ERROR_CONTEXT_PARSE
    else if argv.c
      vlog INFO, "Reading context from file at '#{argv.c}'."
      try
        context = FileUtil.load_json_file_sync(argv.c)
      catch err
        vlog ERROR, "ERROR trying to load context from JSON file at '#{argv.c}'."
        vlog ERROR, "error:",err
        process.exit ERROR_CONTEXT_PARSE
    vlog DEBUG, "Read the following context:", context
    # PARSE TEMPLATE ROOT
    template =  argv.t
    if argv.r?
      root = argv.r
      template = path.resolve(root,template)
    else
      root = path.dirname(template)
      template = path.relative(root,template)
    vlog INFO, "Using template root '#{root}'. Resolved template to '#{template}'."
    secondary_opts = {template_root:root,preserve_newlines:argv.n,helpers:["CommonDustjsHelpers","DustjsHelpers"]}
    context = [context,secondary_opts]
    vlog DEBUG, "Full context:", context
    vlog LOG, "Rendering template at '#{template}' (relative to template root)."
    engine = new DustEngine(secondary_opts)
    engine.render template, context, (err,content)=>
      if err?
        vlog ERROR, "ERROR while processing template at '#{template}'."
        vlog ERROR, "error:",err
        process.exit ERROR_DURING_RENDER
      else
        if argv.o?
          vlog INFO, "Writing to '#{argv.o}'"
          fs.writeFile argv.o, content, (err)=>
            if err?
              vlog ERROR, "ERROR while writing output to '#{argv.o}'."
              vlog ERROR, "error:",err
              process.exit ERROR_DURING_WRITE
            else
              vlog LOG, "Output written to '#{argv.o}'"
              process.exit 0
        else
          console.log content
          process.exit 0


exports.DustEngine = DustEngine
exports.INSTANCE = new DustEngine()
exports__express = exports.INSTANCE.render_for_express

if require.main is module
  DustEngine.main()
