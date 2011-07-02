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
