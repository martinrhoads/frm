module FRM
  class Package < Base
    attr_accessor :repo_filename
    attr_reader :path, :content, :md5, :sha1, :sha2 , :size, :release
    def initialize(path,release='natty')
      raise "you need to specify a path!!!" if path.nil?
      @path = path
      raise "Can not find file '#{path}'" unless File.exists?(path)
      @release = release
      begin
        @content = File.read(path)
      rescue Object => o
        STDERR.puts "Could not open file '#{path}'. Exiting..."
        STDERR.puts o.inspect
        STDERR.puts o.backtrace
        raise "Could not open file '#{path}'. Exiting..."
      end
      @size = File.size(@path)
      @md5 = compute_md5(@content)
      @sha1 = compute_sha1(@content)
      @sha2 = compute_sha2(@content)
    end
  end
end
