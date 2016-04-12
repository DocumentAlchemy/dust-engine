## About this library

This repository contains a simple Dust.js template processor that can be run from the command-line, invoked from code, or registered with Express.js as a rendering engine.

It is fully functional&mdash;we use it in production every day&mdash;but the documentation is currently a work-in-progress.  For now you'll have to review the (heavily commented) source code to get your bearings. (It's only one file, with fewer than 500 lines including comments.) Check back soon for more user-friendly documentation.


### Quick Start

1. Run `make install` or `npm install` to install the external libraries that are used here.

2. If you don't want to invoke the CoffeeScript files as CoffeeScript, run `make js` to "compile" the .coffee file into a .js file.  (The npm-distributed version of the module already includes the generated JS files.)

3. Create a simple template file for demonstration purposes, e.g. `echo "Hello {name}!" > example.dust`.

4. Run the following to render the template for a given "context":

      coffee lib/dust-engine.coffee -t example.dust -j '{"name":"World"}'

   or

      node lib/dust-engine.js -t example.dust -j '{"name":"World"}'


5. Use `coffee lib/dust-engine.coffee --help` or `node lib/dust-engine.js --help` for more info on the command line invocation.

6. For now, see the comments in [lib/dust-engine.coffee](https://github.com/DocumentAlchemy/dust-engine/blob/master/lib/dust-engine.coffee) for more information about how to use the library from code or Express.js.


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
