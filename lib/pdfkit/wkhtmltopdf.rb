# frozen_string_literal: true

class PDFKit
  class WkHTMLtoPDF
    attr_reader :options
    # Pulled from: 
    # https://github.com/wkhtmltopdf/wkhtmltopdf/blob/6a57c1449797d6cb915921fb747f3ac36199241f/docs/usage/wkhtmltopdf.txt#L104
    REPEATABLE_OPTIONS = %w[--allow --bypass-proxy-for --cookie --custom-header --post --post-file --run-script --replace].freeze
    SPECIAL_OPTIONS = %w[cover toc].freeze

    def initialize(options)
      @options = options
    end
  
    def normalize_options
      # TODO(cdwort,sigmavirus24): Make this method idempotent in a future release so it can be called repeatedly
      normalized_options = {}
  
      @options.each do |key, value|
        next if !value
  
        # The actual option for wkhtmltopdf
        normalized_key = normalize_arg key
        normalized_key = "--#{normalized_key}" unless SPECIAL_OPTIONS.include?(normalized_key)
  
        # If the option is repeatable, attempt to normalize all values
        if REPEATABLE_OPTIONS.include? normalized_key
          normalize_repeatable_value(normalized_key, value) do |normalized_unique_key, normalized_value|
            normalized_options[normalized_unique_key] = normalized_value
          end
        else # Otherwise, just normalize it like usual
          normalized_options[normalized_key] = normalize_value(value)
        end
      end
  
      @options = normalized_options
    end

    def error_handling?
      @options.key?('--ignore-load-errors') ||
        # wkhtmltopdf v0.10.0 beta4 replaces ignore-load-errors with load-error-handling
        # https://code.google.com/p/wkhtmltopdf/issues/detail?id=55
        %w(skip ignore).include?(@options['--load-error-handling'])
    end

    def options_for_command
      @options.to_a.flatten.compact
    end
  
    private
  
    def normalize_arg(arg)
      arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
    end
  
    def normalize_value(value)
      case value
      when nil
        nil
      when TrueClass, 'true' #ie, ==true, see http://www.ruby-doc.org/core-1.9.3/TrueClass.html
        nil
      when Hash
        value.to_a.flatten.collect{|x| normalize_value(x)}.compact
      when Array
        value.flatten.collect{|x| x.to_s}
      else
        value.to_s
      end
    end
  
    def normalize_repeatable_value(option_name, value)
      case value
      when Hash, Array
        value.each do |(key, val)|
          yield [[option_name, normalize_value(key)], normalize_value(val)]
        end
      else
        yield [[option_name, normalize_value(value)], nil]
      end
    end
  end
end
