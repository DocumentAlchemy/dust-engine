## About this library

This repository contains a simple Dust.js template processor that can be run from the command-line, invoked from code, or registered with Express.js as a rendering engine.

This module is available under an [MIT-license](https://raw.githubusercontent.com/DocumentAlchemy/dust-engine/master/LICENSE.txt) and published on npm as [`dust-engine`](https://www.npmjs.com/package/dust-engine).

Instructions for using dust-engine can be found below.

Also note that dust-engine truly is a pretty simple utility.  There's only one file, and that file is only a couple hundred lines long, so you may find it informative to [review the code directly](https://github.com/DocumentAlchemy/dust-engine/blob/master/lib/dust-engine.coffee).

### Quick Start

You can use dust-engine in three ways.  Here's how to get up & running with each of them:

#### A) As a command-line Dust template processor

##### 1. Install dust-engine:

```bash
npm install dust-engine
```

##### 2. Create a simple test template:

```bash
echo "Hello {name}!" > example.dust
```

##### 3. Process the template:

```bash
dust-engine -t example.dust -j '{"name":"World"}'
```

yielding:

```
Hello World!
```

being written to stdout.

Use `dust-engine --help` for more options.

#### B) As an Express.js templating engine

##### 1. Register dust-engine with your Express.js app as a view rendering engine:

```javascript
app.engine('dust', require('dust-engine').renderForExpress);
app.set('view engine', 'dust');
```

##### 2. Use it in your routes to render templates:

```javascript
app.get('/hello/:name',function(req,res) {
  res.render( "hello", {name:req.param('name')} );
});
```


#### C) As a JavaScript library

##### C.1) Rendering templates in files:

```javascript
var render = require('dust-engine').render;
render( "my-template", {my:"context"}, function(err,output) {
  console.log(output);
});
```

##### C.2) Rendering templates from strings:

```javascript
var renderString = require('dust-engine').renderString;
renderString( "Hello {name}!", {my:"context"}, function(err,output) {
  console.log(output);
})
```

##### C.3) Configuring Options

```javascript
var DustEngine = require('dust-engine').DustEngine;
var options = {
  template_extension : '.dustjs',
  template_root      : './templates',
  preserve_newlines  : true,
  helpers            : [ 'dustjs-helpers', myCustomHelpers ]
};
var engine = new DustEngine(options);

engine.render( "my-template", context, function(err,output) {
  console.log(output);
})

engine.renderString( "Hello {name}!", context, function(err,output) {
  console.log(output);
})
```

### Installing

Dust-engine is published on npm as **[`dust-engine`](https://www.npmjs.com/package/dust-engine)**.

<br>It can be installed via:

```bash
npm install -g dust-engine
```

This installs the `dust-engine` program into your "global" `node_modules/.bin`.

<br>To add dust-engine as a dependency of your project, run:

```bash
npm install --save dust-engine
```

or add a line like:

```json
"dust-engine": "latest"
```

to the `dependencies` or `devDependencies` section of your `package.json`.

This will make the engine available via `require('dust-engine')`.


### Using

If you are in a hurry, the "Quick Start" section above is a good way to get started.

In this section we'll describe the library in more detail.


#### Components

Unlike many Node.js/JavaScript modules, `require("dust-engine")` doesn't return a constructor or single function.  Instead, it returns a small map that defines several different entry points.  Which entry point is best depends upon what you want to do.

Given `var DustEngine = require("dust-engine")`, then:

 * `DustEngine.render` is a function for rendering Dust templates from files.

 * `DustEngine.renderString` is a function for rendering Dust templates from strings.

 * `DustEngine.renderForExpress` is a function suitable for passing to the Express.js `engine()` function.

 * `DustEngine.DustEngine` a constructor for `DustEngine` instances (particularly useful if you want full control over configuration)


The `render` and `renderString` functions have the signature `(template, [context, [options,]], callback)`, where:

 * `template` is filename of the "root" template to render (a fully-specified path or relative to the "template-root" directory, with or without the `.dust` extension) or, in the case of `renderString`, a string containing the template to be rendered.

 * `context` is an optional map that serves as the initial Dust.js context.

 * `options` is an optional map of "engine" options that are used to control Dust.js, the dust-engine or both (for the duration of this template rendering). (This is described in more detail below.)

 * `callback` is a callback function with the signature `(err, content)`.

The `renderForExpress` function has the (Express-mandated) signature `(viewName, context, callback)`.

The `DustEngine` constructor has the signature `(options)` (described in more detail below).


#### Configuration Options

The `DustEngine` constructor and `render[String]` functions accept several options that can change the engine's behavior or configuration

 * **`dust`** - The dust.js template processor for example, as returned by `require('dustjs-linkedin')` or `require('dustjs-helpers')`. When omitted, `require('dustjs-linkedin')` is used. (Only respected in the constructor. Cannot be used in `render` or `renderString`.)

 * **`helpers`** -  A list (array) of helper-function-libraries to register with the dust.js template processor.  (Only respected in the constructor. Cannot be used in `render` or `renderString`.) Items in the list may be:

    * A function, in which case `element(dust)` will be invoked.

    * An object containing one of the following functions, in which case `element.method(dust)` will be invoked.
       - `export_to`
       - `exportTo`
       - `set_dust`
       - `setDust`

   * The string `dustjs-helpers`,  in which case the helpers from <https://github.com/linkedin/dustjs-helpers> will be loaded and registered with dust *IF AND ONLY IF* `options.dust` was not previously set.

   * The string `common-dustjs-helpers`, in which case the `CommonDustjsHelpers` library from <https://github.com/rodw/common-dustjs-helpers>.

   * (Let us know through an issue or pull request if you'd like to add other "special" helper-library identifiers to this list. But remember that you can register an arbitrary helper using the function or object options, and if push comes to shove, the underlying `dust` instance created by or passed to `DustEngine` is accessible as an instance variable named `dust`.)

* **`preserve_newlines`** - when `true`, all `\n` characters found in templates will be converted to `{~n}` prior to processing the template.

* **`trim_trailing_newline`** - when `true`, a single actual newline character (`\n`, not `{~n}`) at the end of a template file will be stripped off (to avoid adding unintended whitespace due to a newline added to the end of a file by a text editor).

* **`use_cache`** - when `true`, "compiled" templates will be cached (by name or filename); otherwise no caching will be applied, including dust's own internal cache.

* **`ignore_cache`** - when `true`, templates will not be loaded from the dust-engine cache, but existing cached templates will not be removed from the cache either.

* **`base_context`** - when provided, the given object will be used as the root context for all template processing.  The context supplied with an individual call to `render` will be layered "on top" of this one.

* **`base_options`** - when provided, the given object will provide default values passed to dust's `on_load` callback.  The options passed as the second argument to `on_load` will be merged onto the `base_options` value, such that the given values will override those found in `base_options`.

* **`template_root`** - when provided, template paths will be considered relative to this directory. Defaults to the current working directory.

* **`template_extension`** - extension added to the end of template names when looking for templates as files (if it isn't already present in the provided filename).  Defaults to `.dust`. For example, by default, when loading a template via `{>foo/}` will look for a file named `foo.dust` (relative to the template root).  Pass the value `false` (or an empty string) to disable this automatic appending.

* **`no_onload`** - when `true`, the DustEngine will not set the `onLoad` "callback" dust uses when attempting to load a previously unknown template.  You probably only want to do this if you've set a custom `dust.onLoad` function for some reason, otherwise "including" templates via `{>template_name/}` and so on is not likely to work.

* **`template_not_found`** - when a function is provided, if the DustEngine's `onLoad` function is asked to load a template that it cannot find, it will delegate to the `template_not_found` method (rather than throwing an exception).  The signature of the `template_not_found` method is the same as dust's `onLoad` function, namely: `(template_name, options, function callback(err,template_content)`).

* **`template_name`** - the name (key) to cache the "compiled" template under, which defaults to the fully-specified template filename when a file-based template is rendered.   (Only respected in the render-time methods. Cannot be used in the engine constructor.)


#### Other Notes

 * Relative paths in `{>include_tags/}` are _always_ interpreted as being relative to the "template root".

 * The template passed to the `renderString` method can reference files in `{>include_tags/}`.

 * The `template_name` option can be used to compile and cache string-based templates that can later be referenced by `{>template_name/}`.

 * The "engine options" can be set in the Express.js `res.render` call by passing an *array* of the form `[context, options]` as the second argument to `res.render` (rather than just `context`).

 * The parameters for the command-line `dust-engine` program are described in the in-app help.  Run `dust-engine --help` to see them.

 * There are a handful of other methods in `DustEngine` that you might be interested in, such as `load_template`, `compile_template`, `render_template` and `get_template`. As mentioned above, DustEngine is really a pretty small and simple class, so you may find it informative to [review the code directly](https://github.com/DocumentAlchemy/dust-engine/blob/master/lib/dust-engine.coffee).

 * This repository follows the "gitflow" convention of doing development within the `develop` branch.  The `master` branch only contains "released" versions of the code, `develop` is where all the fun happens.

### Licensing

This module is made available under an MIT license, as described in [LICENSE.txt](https://github.com/DocumentAlchemy/dust-engine/blob/master/LICENSE.txt).


## About Dust.js

Dust is a JavaScript-based templating engine first developed by [Aleksander Williams (akdubya on GitHub)](http://akdubya.github.io/dustjs/) and now maintained by engineers from  [LinkedIn](https://github.com/linkedin/dustjs), PayPal and elsewhere.

Both [akdubya's page](http://akdubya.github.io/dustjs/) and LinkedIn's branded <https://dustjs.com> provide a comprehensive introduction to Dust's design and concepts, so we won't attempt that here.


## About DocumentAlchemy

Document Alchemy provides an easy-to-use API for generating, transforming, converting and processing documents in various formats, including:

 * MS Office documents such as Microsoft Word, Excel and PowerPoint.
 * Open source office documents such Apache OpenOffice Writer, Calc and Impress.
 * Adobe's Portable Document Format (PDF)
 * HTML, Markdown and other text formats
 * Images such as PNG, JPEG, GIF and others.

More information, [free, online document conversion tools](https://documentalchemy.com/demo) that demonstrate some of DocumentAlchemy's functionality, and [interactive documentation of our document processing API](https://documentalchemy.com/api-doc) can be found at <https://documentalchemy.com>.

You can follow us on Twitter at [@DocumentAlchemy](http://twitter.com/DocumentAlchemy).

![](https://documentalchemy.com/images/beakers-61x64.png)
