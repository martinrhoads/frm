DEFAULT_HOST =  's3-us-west-1.amazonaws.com' # stupid hack to point to
# the right region

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

  class PackageRelease < Base
    attr_reader :packages, :standards_version, :priority, :package_file, :gzipped_package_file, :release_file, :short_release_file, :component, :release
    def initialize(packages={},release='natty',component='main/binary-amd64')
      @release = release
      @component = component
      @standards_version = standards_version
      @priority = priority
      @packages = []
      packages.each { |package| @packages << Package.new(package,@release) }
      @package_file = generate_package_file
      @gzipped_package_file = generate_gzip_pipe(@package_file).read
      @short_release_file = generate_short_release_file
      @release_file = generate_release_file
    end
    
    private
    
    def generate_release_file()
      partial_release_file = "Origin: apt.cloudscaling.com
Label: apt repository #{@release}
Codename: #{@release}
Date: Thu, 22 Dec 2011 00:29:55 UTC
Architectures: amd64
Components: main universe multiverse
Description: Cloudscaling APT repository
MD5Sum:
 #{compute_md5(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_md5(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_md5(@short_release_file)} #{@short_release_file.size} #{@component}/Release
SHA1:
 #{compute_sha1(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_sha1(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_sha1(@short_release_file)} #{@short_release_file.size} #{@component}/Release
SHA256:
 #{compute_sha2(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_sha2(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_sha2(@short_release_file)} #{@short_release_file.size} #{@component}/Release
"
      return partial_release_file
    end

    def generate_short_release_file
      "Component: main
Origin: apt.cloudscaling.com
Label: apt repository #{@release}
Architecture: amd64
Description: Cloudscaling APT repository
"
    end
    

    def filename(package)
      filename = File.basename package.path
      shortname = `dpkg --field #{package.path} Package`.chomp
      first_letter = shortname[0]
      package.repo_filename = "pool/main/#{first_letter}/#{shortname}/#{filename}"
    end
    
    def generate_package_file()
      package_file = ''
      @packages.each { |package| package_file << generate_package_stub(package) }
      return package_file
    end
    
    def generate_package_stub(package)
      package_stub = ''
      package_stub << `dpkg --field #{package.path}`
      package_stub << "Filename: #{filename(package)}\n"
      package_stub << "Size: #{package.size}\n"
      package_stub << "MD5sum: #{package.md5}\n"
      package_stub << "SHA1: #{package.sha1}\n"
      package_stub << "SHA256: #{package.sha2}\n"
      package_stub << "\n"
      return package_stub
    end
  end

  class ReleasePusher < Base
    def initialize(package_release,access_key,secret_key,bucket,prefix,server='s3-us-west-1.amazonaws.com')
      @release = package_release.release
      @bucket = bucket
      @prefix = prefix
      @s3 = FRM::S3.new(access_key,secret_key,server)
      push_packages(package_release.packages)
      push_release_files(package_release)
    end

    private


    def push_release_files(package_release)
      # TODO: un-hardcode this
      release_path = @prefix + "/dists/#{@release}/Release"
      @s3.put(release_path,package_release.release_file,@bucket)

      in_release_path = @prefix + "/dists/#{@release}/InRelease"
      @s3.put(in_release_path,gpg_clearsign(package_release.release_file),@bucket)

      gpg_release_path = @prefix + "/dists/#{@release}/Release.gpg"
      @s3.put(gpg_release_path,gpg_detached(package_release.release_file),@bucket)

      release_file_path = @prefix + "/dists/#{@release}/" + package_release.component
      @s3.put(release_file_path + '/Release',package_release.short_release_file,@bucket)
      @s3.put(release_file_path + '/Packages',package_release.package_file,@bucket)
      @s3.put(release_file_path + '/Packages.gz',package_release.gzipped_package_file,@bucket)
    end
    

    def push_packages(packages)
      packages.each { |package| push_package(package) }
    end
    
    def push_package(package)
      remote_path = @prefix + '/' + package.repo_filename
      @s3.put(remote_path,package.content,@bucket)
    end
    

  end
  
  
  
  class Deb  < Base
    
    def initialize()
    end
    
    def generate_package_file(in_packages=[])
      packages = in_packages.sort { |a,b| a['Package'] <=> b['Package'] }
      package_file = ''
      packages.each { |package| package_file << generate_package_stub(package) }
      return package_file
    end

    
    def generate_package_stub(in_package={})
      package = in_package.dup
      package_stub = ''
      description = package.delete('Description') || "no description given"
      path_to_deb = package.delete 'path_to_deb'
      section = package.delete 'section'
      package["Filename"] = "pool/#{section}/#{package['Package'][0]}/#{package['Package']}/#{package['Package']}_#{package['Version']}_#{package['Architecture']}.deb"
      package["Size"] = File.new(path_to_deb).size
      package["MD5sum"] = self.compute_md5 File.read path_to_deb
      package["SHA1"] = compute_sha1 File.read path_to_deb
      package["SHA256"] = compute_sha2 File.read path_to_deb
      package["Description"] = description
      package.each { |key,value| package_stub << generate_package_line(key,value) }
      package_stub << "\n"
      return package_stub
    end
    
    
    def generate_package_release
      return "Component: main
Origin: apt.cloudscaling.com
Label: apt repository natty
Architecture: amd64
Description: Cloudscaling APT repository
"
    end
    
    
    def generate_package_line(key='',value='')
      valid_options = %w{Package Version Architecture Maintainer Standards-Version Homepage Priority Depends Filename Size SHA256 SHA1 MD5sum Description}
      raise "Bogus option passed: #{key}" unless valid_options.include?(key)                
      
      case key
      when 'Depends'
        return "Depends: #{value.join(', ')}\n"
      when 'Maintainer'
        return "Maintainer: <#{value}>\n"
      else
        return "#{key}: #{value}\n"
      end
    end
    
  end
  
end
