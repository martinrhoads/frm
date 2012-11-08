module FRM
  class Package < Base
    attr_reader :path, :content, :info

    def initialize(path)
      @path = path

      raise "you need to pass a path!!!" if path.nil?
      raise "Can not find file: '#{path}'" unless File.exists?(path)
      raise "this system does not have the dpkg binary" unless system 'which dpkg > /dev/null'
      raise "file #{path} is not a deb" unless system "dpkg --field #{path} > /dev/null"

      begin
        @content = File.read(path)
      rescue Object => o
        STDERR.puts "Could not open file '#{path}'. Exiting..."
        STDERR.puts o.inspect
        STDERR.puts o.backtrace
        raise "Could not open file '#{path}'. Exiting..."
      end

      @info = get_package_info
    end

    def to_stub
      @info.collect{|k,v| "#{k}: #{v}"}.join("\n") + "\n\n"
    end

    def self.hash_to_stub(hash)
      hash.collect{|k,v| "#{k}: #{v}"}.join("\n") + "\n\n"
    end

    def to_h
      return @info
    end

    private 

    def get_package_info
      h = {}
      ['Package', 'Version', 'License' ,'Vendor' ,'Architecture' ,'Maintainer', 'Installed-Size' ,'Section', 'Priority', 'Homepage', 'Description' ].each do |value| 
        h[value] = run "dpkg --field #{@path} #{value}"
      end

      h['Filename'] = "pool/main/#{h['Package'][0]}/#{h['Package']}/#{File.basename @path}"
      h['Size'] = File.size(@path)
      h['MD5sum'] = compute_md5(@content)
      h['SHA1'] = compute_sha1(@content)
      h['SHA256'] = compute_sha2(@content)
      return h
    end

  end
end
