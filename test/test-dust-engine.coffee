path                = require 'path'
fs                  = require 'fs'
HOMEDIR             = path.join __dirname, '..'
IS_INSTRUMENTED     = fs.existsSync(path.join(HOMEDIR,'lib-cov'))
LIB_DIR             = if IS_INSTRUMENTED then path.join(HOMEDIR,'lib-cov') else path.join(HOMEDIR,'lib')
DATA_DIR            = path.join HOMEDIR, "test", "data"
should              = require 'should'
DustEngine          = require(path.join(LIB_DIR,'dust-engine')).DustEngine

describe 'DustEngine',->

  it "exists", (done)=>
    should.exist DustEngine
    done()

  it "can be initialized", (done)=>
    de = new DustEngine()
    should.exist(de)
    should.exist(de.render_for_express)
    done()

  it "can render a dust template from a string", (done)=>
    de = new DustEngine()
    template = "Hello {name}!"
    context = {name:"World"}
    de.render_dust_template_from_string template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports renderString as an alias for render_dust_template_from_string", (done)=>
    de = new DustEngine()
    template = "Hello {name}!"
    context = {name:"World"}
    de.renderString template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports render_for_express", (done)=>
    de = new DustEngine({template_root:DATA_DIR})
    template = "hello-world"
    context = {name:"World"}
    de.render_for_express template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports \"extra context\" options within render_for_express", (done)=>
    de = new DustEngine()
    template = "hello-world"
    context = {name:"World"}
    options = {template_root:DATA_DIR}
    de.render_for_express template, [context, options], (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "doesn't preserve newlines (in render) by default", (done)=>
    de = new DustEngine()
    template = "\nHello\n{name}!\n"
    context = {name:"World"}
    de.renderString template, context, (err, output)=>
      should.not.exist err
      output.should.equal "HelloWorld!"
      done()

  it "supports preserve_newlines option during construction (string variant)", (done)=>
    de = new DustEngine(preserve_newlines:true)
    template = "\nHello\n{name}!\n"
    context = {name:"World"}
    de.renderString template, context, (err, output)=>
      should.not.exist err
      output.should.equal "\nHello\nWorld!\n"
      done()

  it "supports preserve_newlines option during render (string variant)", (done)=>
    de = new DustEngine()
    template = "\nHello\n{name}!\n"
    context = {name:"World"}
    options = {preserve_newlines:true}
    de.renderString template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "\nHello\nWorld!\n"
      done()

  it "can preserve newlines in dust variables", (done)=>
    de = new DustEngine()
    template = "\nHello\n{name}!\n"
    context = {name:"\nWorld"}
    options = {preserve_newlines:true}
    de.renderString template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "\nHello\n\nWorld!\n"
      done()

  it "can render a dust template from a file", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hello-world.dust")
    context = {name:"World"}
    de.render_dust_template_from_file template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports renderFile as an alias for render_dust_template_from_file", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hello-world.dust")
    context = {name:"World"}
    de.renderFile template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()


  it "supports render as an alias for renderFile", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hello-world.dust")
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports preserve_newlines option during construction (file variant)", (done)=>
    de = new DustEngine(preserve_newlines:true)
    template = path.join(DATA_DIR,"hello-world-newlines.dust")
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "\nHello\nWorld!\n"
      done()

  it "supports preserve_newlines option during render (file variant)", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hello-world-newlines.dust")
    context = {name:"World"}
    options = {preserve_newlines:true}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "\nHello\nWorld!\n"
      done()

  it "finds templates without the .dust extension", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hello-world")
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "allows template_extension to override the .dust extension (constructor case)", (done)=>
    de = new DustEngine(template_extension:".dustjs")
    template = path.join(DATA_DIR,"hi-world")
    context = {name:"you"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hi there, you!"
      done()

  it "allows template_extension to override the .dust extension (render case)", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hi-world")
    context = {name:"you"}
    options = {template_extension:".dustjs"}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "Hi there, you!"
      done()

  it "adds a dot to template_extension if it doesn't already have one", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hi-world")
    context = {name:"you"}
    options = {template_extension:"dustjs"}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "Hi there, you!"
      done()

  it "allows template_extension=false to prevent adding an extension (constructor case)", (done)=>
    de = new DustEngine(template_extension:false)
    template = path.join(DATA_DIR,"hi-world.dustjs")
    context = {name:"you"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hi there, you!"
      done()

  it "allows template_extension=false to prevent adding an extension (render case)", (done)=>
    de = new DustEngine()
    template = path.join(DATA_DIR,"hi-world.dustjs")
    context = {name:"you"}
    options = {template_extension:false}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "Hi there, you!"
      done()

  it "supports templates identified relative to the template-root (constructor case)", (done)=>
    de = new DustEngine(template_root:DATA_DIR)
    template = "hello-world"
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports templates identified relative to the template-root (render case)", (done)=>
    de = new DustEngine()
    template = "hello-world"
    context = {name:"World"}
    options = {template_root:DATA_DIR}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports templates identified relative to the template-root (render overrides constructor)", (done)=>
    de = new DustEngine(template_root:"foobar")
    template = "hello-world"
    context = {name:"World"}
    options = {template_root:DATA_DIR}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal "Hello World!"
      done()

  it "supports template includes (file to file case)", (done)=>
    de = new DustEngine({template_root:DATA_DIR})
    template = "parent"
    context = {name:"Newman"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello Newman, this is the parent template.\nHello Newman, this is the child template."
      done()

  it "supports template includes (string to file case)", (done)=>
    de = new DustEngine({template_root:DATA_DIR})
    template = "Hello {name}, this is the parent template.{~n}{>child/}"
    context = {name:"Newman"}
    de.renderString template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello Newman, this is the parent template.\nHello Newman, this is the child template."
      done()

  it "always resolves template paths relative to the tempalte_root value", (done)=>
    de = new DustEngine({template_root:DATA_DIR})
    template = "sub-folder-one/grandparent"
    context = {name:"Newman"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal "Hello Newman, this is the grandparent template.\nHello Newman, this is the parent template.\nHello Newman, this is the child template."
      done()

  it "preserves newlines in included files (construction case)", (done)=>
    de = new DustEngine(preserve_newlines:true,template_root:DATA_DIR)
    template = "sub-folder-one/parent-of-newlines"
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal 'This\ntemplate\nis\ncalled\n"parent of\nnewlines"\nbecause\nthe template\nthat it includes\nhas extra newlines\nadded to it.\n\nHello\nWorld!\n\nThis is text after the include.\n'
      done()

  it "can trim the trailing newline from a file (construction case)", (done)=>
    de = new DustEngine(preserve_newlines:true,trim_trailing_newline:true,template_root:DATA_DIR)
    template = "sub-folder-one/parent-of-newlines"
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal 'This\ntemplate\nis\ncalled\n"parent of\nnewlines"\nbecause\nthe template\nthat it includes\nhas extra newlines\nadded to it.\n\nHello\nWorld!\nThis is text after the include.'
      done()

  it "preserves newlines in included files (render case)", (done)=>
    de = new DustEngine()
    template = "sub-folder-one/parent-of-newlines"
    context = {name:"World"}
    options = {preserve_newlines:true, template_root:DATA_DIR}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal 'This\ntemplate\nis\ncalled\n"parent of\nnewlines"\nbecause\nthe template\nthat it includes\nhas extra newlines\nadded to it.\n\nHello\nWorld!\n\nThis is text after the include.\n'
      done()

  it "can trim the trailing newline from a file (render case)", (done)=>
    de = new DustEngine(template_root:DATA_DIR)
    template = "sub-folder-one/parent-of-newlines"
    context = {name:"World"}
    options = {preserve_newlines:true,trim_trailing_newline:true}
    de.render template, context, options, (err, output)=>
      should.not.exist err
      output.should.equal 'This\ntemplate\nis\ncalled\n"parent of\nnewlines"\nbecause\nthe template\nthat it includes\nhas extra newlines\nadded to it.\n\nHello\nWorld!\nThis is text after the include.'
      done()

  it "automatically loads helper functions defined by known names, objects with a setDust method, and functions", (done)=>
    helper_list = []
    helper_list.push "common-dustjs-helpers"
    set_dust_called = false
    helper_list.push {
      set_dust:(d)=>
        should.exist d
        set_dust_called = true
    }
    setDust_called = false
    helper_list.push {
      setDust:(d)=>
        should.exist d
        setDust_called = true
    }
    helper_list.push "dustjs-helpers"
    function_called = false
    helper_list.push (d)=>
      should.exist d
      function_called = true
    export_to_called = false
    helper_list.push {
      export_to:(d)=>
        should.exist d
        export_to_called = true
    }
    exportTo_called = false
    helper_list.push {
      exportTo:(d)=>
        should.exist d
        exportTo_called = true
    }
    de = new DustEngine(template_root:DATA_DIR, helpers:helper_list)
    template = "template-with-helpers"
    context = {name:"World"}
    de.render template, context, (err, output)=>
      should.not.exist err
      output.should.equal 'Hello WORLD!\nName is equal to "World".\nText at the end of the file.'
      function_called.should.be.ok
      set_dust_called.should.be.ok
      setDust_called.should.be.ok
      export_to_called.should.be.ok
      exportTo_called.should.be.ok
      done()

  it "supports a single helpers parameter as well as an array", (done)=>
    function_called = false
    de = new DustEngine( helpers:((d)=>function_called = true))
    function_called.should.be.ok
    done()

  it "warns when the helpers option is passed to the render function", (done)=>
    de = new DustEngine()
    template = "Hello {name}!"
    context = {name:"World"}
    options = {helpers:["common-dustjs-helpers"]}
    old_console_error = console.error
    try
      error_message = null
      console.error = (args...)->error_message = args.join(" ")
      de.render_dust_template_from_string template, context, options, (err, output)=>
        console.error = old_console_error
        should.not.exist err
        output.should.equal "Hello World!"
        error_message.should.equal "\nWARNING: The 'helpers' option was passed to the DustEngine's render function\n         but that option is only supported during the initialization of the\n         DustEngine instance. It cannot be set at render-time."
        done()
    finally
      console.error = old_console_error # ensure console.error is reset, even if an exception is thrown


  it "can be invoked from the command line", (done)=>
    argv = [
      "node",
      "dust-engine.js"
      "-r"
      DATA_DIR
      "-t"
      "hello-world-newlines"
      "-j"
      JSON.stringify({name:"World"})
      "--preserve-newlines"
    ]
    err_buf = []
    console_err = (args...)->err_buf.push(args.join(" "))
    out_buf = []
    console_log = (args...)->out_buf.push(args.join(" "))
    DustEngine.main argv, console_log, console_err, (exit_code)=>
      exit_code.should.equal 0
      err_buf.length.should.equal 0
      out = out_buf.join("")
      out.should.equal "\nHello\nWorld!\n"
      done()
