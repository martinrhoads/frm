module FRM
  
  class ArchRelease < Base
    attr_reader :opts

    def initialize(opts={})
      super()
      @opts = opts
      @opts[:packages] = []
      @opts[:package_paths] ||= []
      @opts[:release] ||= run ". /etc/lsb-release && echo $DISTRIB_CODENAME"
      @opts[:component] ||= 'main'
      @opts[:origin] ||= 'FRM'
      @opts[:lablel] ||= 'FRM'
      @opts[:description] = "FRM apt repo"
      @opts[:package_paths].each { |path| @opts[:packages] << Package.new(path) }
      case run("uname -m")
      when "x86_64"
        @opts[:arch] ||= 'amd64'
      else
        @opts[:arch] ||= run "uname -m"
      end
      raise "you need to pass a remote_store object that responds to exists? and get"\
         unless @opts[:remote_store] \
           and @opts[:remote_store].respond_to? 'exists?' \
           and @opts[:remote_store].respond_to? 'get'

      @opts[:release_file_path] = "#{@opts[:component]}/binary-#{@opts[:arch]}/Release"
      @opts[:package_file_path] = "#{@opts[:component]}/binary-#{@opts[:arch]}/Packages"
      @opts[:gzipped_package_file_path] = "#{@opts[:component]}/binary-#{@opts[:arch]}/Packages.gz"

      @opts[:package_file] = merge_package_files
      @opts[:gzipped_package_file] = generate_gzip_pipe(@opts[:package_file]).read
      @opts[:release_file] = release_file

           STDERR.puts "release file is : \n#{@opts[:release_file]}"

      @opts[:package_file_size] = @opts[:package_file].size
      @opts[:gzipped_package_file_size] = @opts[:gzipped_package_file].size
      @opts[:release_file_size] = @opts[:release_file].size

      @opts[:package_file_md5sum] = compute_md5(@opts[:package_file])
      @opts[:gzipped_package_file_md5sum] = compute_md5(@opts[:gzipped_package_file])
      @opts[:release_file_md5sum] = compute_md5(@opts[:release_file])

      @opts[:package_file_sha1] = compute_sha1(@opts[:package_file])
      @opts[:gzipped_package_file_sha1] = compute_sha1(@opts[:gzipped_package_file])
      @opts[:release_file_sha1] = compute_sha1(@opts[:release_file])

      @opts[:package_file_sha256] = compute_sha2(@opts[:package_file])
      @opts[:gzipped_package_file_sha256] = compute_sha2(@opts[:gzipped_package_file])
      @opts[:release_file_sha256] = compute_sha2(@opts[:release_file])
    end

    def push
      @opts[:packages].each do |p| 
        if @opts[:remote_store].exists?(p.info['Filename']) 
          STDERR.puts "package #{p.path} already exists"
          unless @opts[:remote_store].etag(p.info['Filename']) == p.info['MD5sum']
            raise <<EOE
trying to overwrite this package file: #{remote_path}
local md5 is #{package.info['MD5sum']}
remote md5 (etag) is #{@s3.etag(remote_path,@bucket)}
EOE
          end
        else
          STDERR.puts "pushing package #{p.path}"
          @opts[:remote_store].put(p.info['Filename'],p.content)
        end
      end
      STDERR.puts "pushing arch release files"
      @opts[:remote_store].put(File.join("dists/#{@opts[:release]}/",@opts[:release_file_path]),@opts[:release_file])
      @opts[:remote_store].put(File.join("dists/#{@opts[:release]}/",@opts[:gzipped_package_file_path]),@opts[:gzipped_package_file])
      @opts[:remote_store].put(File.join("dists/#{@opts[:release]}/",@opts[:package_file_path]),@opts[:package_file])
    end
    
    private

    def release_file
      return <<-EOF
Component: #{@opts[:component]}
Origin: #{@opts[:origin]}
Label: #{@opts[:lablel]}
Architecture: #{@opts[:arch]}
Description: #{@opts[:description]}
EOF
    end

    def previous_package_file
      return @opts[:remote_store].get(@opts[:package_file_path]) \
        if @opts[:remote_store].exists? @opts[:package_file_path]
      return ""
    end

    
    # given a package file as a string, parse out the next package
    def parse_package_stub(package_file='')

      # find the first package header
      stub_start = package_file.index(/^Package: /)
      return nil if stub_start.nil?

      # find the end of the first package section
      stub_end = package_file.index(/^\n/,stub_start)
      raise "could not parse #{package_file}" if stub_end.nil?

      # extract out the next stub
      stub = package_file.slice(stub_start,stub_end)
      raise "could not parse #{package_file}" if stub.nil?

      # pull out the package line from the stub
      package_line = stub[/^Package: .*$/]
      raise "could not parse #{package_file}" if package_line.nil?

      # pull out the name of the package
      package = package_line.sub('Package: ','').strip
      raise "could not read package name from #{stub}" if package.empty?

      return convert_stub_to_hash(stub), stub_end, package
    end


    # recursive function to merge two sets of packages
    def merge_package_files(opts={})

      # initial settings
      opts[:previous_package_file] ||= previous_package_file
      opts[:new_packages] ||= @opts[:packages].collect{|p| p.to_h}.sort{|a,b| a['Package'] <=> b['Package'] }
      opts[:new_package_file] ||= ""

      # if we are at the end of both the old package list and the new set of packages then finish
      return opts[:new_package_file] \
        if opts[:previous_package_file].strip.empty? \
          and opts[:new_packages].empty? 

      # if we don't have any new packages to add then return the current list with the old appended
      return (opts[:new_package_file] << opts[:previous_package_file]) \
        if opts[:new_packages].empty?
          
      # parse next package stub
      stub, stub_end, next_package = parse_package_stub(previous_package_file)

      # if we don't have and more old packages to add then return the
      # current list with the new appended
      return (opts[:new_package_file] << opts[:new_packages].collect{|p| FRM::Package.hash_to_stub(p)}.join("\n")) if stub.nil?

      # compare the next previous existing pacakge to the next new package
      case next_package <=> opts[:new_packages]['Package']
      when -1 
        opts[:new_package_file] << stub
        opts[:previous_package_file].slice(stub_end)
      when 1
        opts[:new_package_file] << opts[:new_packages].shift.to_stub
      when 0
        # both packages have the same name

        previous_version_line = stub[/^Version: .*$/]
        raise "could not get version from package stub: \n#{stub}" if previous_version_line.nil?

        previous_version = previous_version_line.sub('Version: ','').strip
        raise "could not get version from package stub: \n#{stub}" if previous_version.empty?

        newer_version = opts[:new_packages][Version]
        raise "previous version #{previous_version} is newer than #{newer_version}"
        
        opts[:new_package_file] << opts[:new_packages].shift.to_stub
      end

      return merge_package_files(opts)
    end

  end
end
