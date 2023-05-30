2023-02-27
=================
  * Bump to 0.8.7.3
  * Allow passing a `Pathname` object to the `path` argument by @yujideveloper in https://github.com/pdfkit/pdfkit/pull/522
  * Update repeatable options by @mguidetti in https://github.com/pdfkit/pdfkit/pull/524

2022-10-18
=================
  * Bump to 0.8.7.2
  * Call IO.popen with an Array of command arguments (#519)

2022-10-17
=================
  * Bump to 0.8.7.1
  * Support non-lower-case Content-Type header provided by app (#516)

2022-10-02
=================
  * Bump to 0.8.7
  * Lowercase the header names for rack 3 changes (#511)
  * Partially escaped URLs should be escaped (#509)

2022-04-11
=================
  * Bump to 0.8.6
  * Update ruby and rails versions

2021-01-23
=================
  * Bump to 0.8.5
  * Make `PDFKit::VERSION` public (#484) 
  * Fix to render stylesheets as html safe string on Rails 6 (#483)
      * Adds support for Rails 6

2020-08-16
=================
  * Bump to 0.8.4.3.2
  * Reduce scope of middleware exception handling (#476)

2020-07-05
=================
  * Bump to 0.8.4.3.1
  * Don't override request level Content-Disposition header if it exists (#466)
  * Update rake (#471)
  * Add missing require statements for tempfile (#467)
  * Only grab last line of bundle exec which output (#464)
  * Return 500 status when an exception is caught in middleware (#469)
  * Update Travis CI URL for wkhtmltopf (#473)
  
2020-04-01
=================
  * Bump to 0.8.4.2
  * Improve path detection feedback (#460)
  * Fix typos (#444)
  * Update readme (#439)
  
2019-02-22
=================
  * Bump to 0.8.4.1
  * Make PDFkit threadsafe (#377)
  * Update activesupport (#434)

2019-02-21
=================
  * Bump to 0.8.4
  * Removed support for Ruby < 2.2
  * Xvfb support (#277)
  * Remove 'config.protocol' from the README (#389)

2015-08-26
=================
  * Bump to 0.8.2
  * Fix URI errors for users using PDFKit in contexts with 'uri' not
    already required (thanks christhekeele)

2015-08-20
=================
  * Bump to 0.8.1
  * Fix shell escaping issues for Windows (thanks muness)
  * Fix shell escaping issues for URLs, introduced in 0.5.3 release

2015-07-08
=================
  * Bump to 0.8.0
  * Support Cover and Table Of Contents options (thanks @nicpillinger)
  * Fix repeatings keys with string values
  * Fix caching bug (thanks @jocranford)
  * Fix munging of relative paths (thanks @jocranford)
  * Fix bug where nil values did not stay nil (thanks @tylerITP)

2015-05-06
=================
  * Bump to 0.7.0
  * Fix issue #230 where PDFKit called `bundle exec` without a Gemfile
  * Fix issue #183 where PDFKit broke the path to wkhtmltopdf.exe by escaping
    spaces in paths
  * Improve performance by not storing the PDF in memory if a path is
    provided. Thanks @mikefarah
  * Middleware now infers HTTP or HTTPS from environment for relative URLs

2014-04-20
==================
  * Bump to 0.6.2
  * There was a bug where parsing meta tags would include the option name
    causing an invalid command to be generated. This was fixed in #229 after
    being reported by Frank Oxener.

2014-02-18
==================
  * Bump to 0.6.0
  * Added ability to run wkhtmltopdf without `--quiet`
  * Now handles repeatable options as both config parameters and meta tag
    options
  * Fix status code 2 being treated as failure
  * Escape `\X` in styesheets
  * Allow controllers to set PDFKit-save-pdf
  * Fix Middleware not respecting subdomains in path

2013-06-12
==================
  * Bump to 0.5.4
  * Fix broken page numbers (https://github.com/pdfkit/pdfkit/pull/181)

2013-02-21
==================
  * Bump to 0.5.3
  * Fix security vulnerability due to unsanitized strings being passed to `wkhtmltopdf` (https://github.com/pdfkit/pdfkit/issues/164)

2011-07-02
==================
  * Bump to 0.5.2
  * Fix of dealing with ActiveSupport::SafeBuffer >= 3.0.8.
  * Fix for meta tag options getting dropped in REE 1.8.7.
  * Fix on bundler environment detection.

2011-06-17
==================
  * Bump to 0.5.1
  * Fix for response body coming through as an array.
  * Added root_url configuration for setup where a host my not know its own name.
  * Awareness of Bundler when looking for the wkhtmltopdf executable.
  * Fix for file data getting truncated in Ruby 1.8.6
  * Fix for 0.5.0 release getting stuck rendering all requests as PDFs.
  * More robust meta tag detection.

2010-12-27
==================
  * Bump to 0.5.0
  * Switched to popen - adds support for JRuby and Windows
  * Pulled in support for pdf rendering conditions in middleware via Rémy Coutable
  * Use `which` to try and determine path to wkhtmltopdf
  * Removed wkhtmltopdf auto installer
  * Changed :disable\_smart\_shrinking to false for default options.
  * Added History.md
