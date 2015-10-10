require 'rbconfig'

class PDFKit
  module OS
    def self.host_is_windows?
      !(RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince/).nil?
    end

    def self.shell_escape_for_os(args)
      if (host_is_windows?)
        # Windows reserved shell characters are: & | ( ) < > ^
        # See http://technet.microsoft.com/en-us/library/cc723564.aspx#XSLTsection123121120120
        args.map { |arg| arg.gsub(/([&|()<>^])/,'^\1') }.join(" ")
      else
        args.shelljoin
      end
    end
  end
end
