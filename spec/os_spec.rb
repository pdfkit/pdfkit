#encoding: UTF-8
require 'spec_helper'
require 'rbconfig'

describe 'OS' do
  subject { PDFKit::OS }

  describe 'host_is_windows?' do
    it 'is callable' do
      expect(subject).to respond_to(:host_is_windows?)
    end

    def test_is_windows(bool, host_os)
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)

      expect(subject.host_is_windows?).to be bool
    end

    it 'returns true if the host_os is set to "mswin"' do
      test_is_windows(true, 'mswin')
    end

    it 'returns true if the host_os is set to "msys"' do
      test_is_windows(true, 'msys')
    end

    it 'returns false if the host_os is set to "linux-gnu"' do
      test_is_windows(false, 'linux-gnu')
    end

    it 'returns false if the host_os is set to "darwin14.1.0"' do
      test_is_windows(false, 'darwin14.1.0')
    end
  end

  describe 'shell_escape_for_os' do
    it 'is callable' do
      expect(subject).to respond_to(:shell_escape_for_os)
    end

    it 'calls shelljoin on linux' do
      args = double(:shelljoin)
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('linux-gnu')

      expect(args).to receive(:shelljoin)
      PDFKit::OS.shell_escape_for_os(args)
    end

    it 'calls shelljoin on darwin14.1.10' do
      args = double(:shelljoin)
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('darwin14.1.10-gnu')

      expect(args).to receive(:shelljoin)
      PDFKit::OS.shell_escape_for_os(args)
    end

    it 'escapes special characters on Windows' do
      args = ['foo|bar', 'biz(baz)', 'foo<baz>bar', 'hello^world&goodbye']
      allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return('mswin')

      escaped_args = PDFKit::OS.shell_escape_for_os(args)
      expect(escaped_args).to eq('foo^|bar biz^(baz^) foo^<baz^>bar hello^^world^&goodbye')
    end
  end
end
