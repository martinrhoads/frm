DEFAULT_HOST =  's3-us-west-1.amazonaws.com' # stupid hack to point to
# the right region

module FRM

    
  class Base
    my_dir = File.dirname __FILE__
    require File.join my_dir, 's3'
    require 'zlib'
    require 'tempfile'
    require 'digest/md5'
    require 'digest/sha1'
    require 'digest/sha2'
    
    def compute_md5(string)
      Digest::MD5.hexdigest(string)
    end
    
    def compute_sha1(string)
      Digest::SHA1.hexdigest(string)
    end
    
    def compute_sha2(string)
      Digest::SHA2.hexdigest(string)
    end

    # TODO:
    # there has to be a better way to use gpg withen ruby. found many
    # broken solutions :\ 
    def gpg_clearsign(message)
      `echo "#{message}" | gpg --clearsign`
    end

    # TODO: same as above
    def gpg_detached(message)
      `echo "#{message}" | gpg -abs`
    end
    

    def generate_gzip_pipe(contents)
      read_buffer, write_buffer = IO.pipe
      gzip_writer = Zlib::GzipWriter.new write_buffer
      gzip_writer.mtime = 1 # ensure that the header is determinstic
      gzip_writer.write contents
      gzip_writer.close
      read_buffer
    end
    
    def gunzip_pipe(gziped_pipe)
      gzip_reader = Zlib::GzipReader.new gziped_pipe
      unzipped_string = gzip_reader.read
      gzip_reader.close
      return unzipped_string
    end
    
    def parse_package_stub(read_buffer)
      package = {}
      stub = ""
      while line = read_buffer.gets
        return nil if line.strip.empty? 
        raise "bad input" unless (match = line.match /^\w+\-?\w+?: /)
        stub << line
        key = match[0].delete ': ' # if match
        value = match.post_match.strip
        package[key] = value
        if key == 'Description'
          while (line = read_buffer.gets).strip != ""
            package['Description'] << line
            stub << line
          end
          package['Description'].rstrip!
          return package, stub
        end
      end
      nil
    end
    
    def merge_package_file(in_pipe,out_pipe,package_list)
      sorted_list = package_list.sort { |a,b| a['Package'] <=> b['Package'] }
    end
end
  
  
  class Package < Base
    attr_accessor :repo_filename
    attr_reader :path, :content, :md5, :sha1, :sha2 , :size
    def initialize(path)
      puts "path is #{path.inspect}"
      raise "you need to specify a path!!!" if path.nil?
      @path = path
      raise "Can not find file '#{path}'" unless File.exists?(path)
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
    attr_reader :packages, :standards_version, :priority, :package_file, :gzipped_package_file, :release_file, :short_release_file, :component
    def initialize(packages={},component='main/binary-amd64')
      @component = component
      @standards_version = standards_version
      @priority = priority
      @packages = []
      packages.each { |package| @packages << Package.new(package) }
      @package_file = generate_package_file
      @gzipped_package_file = generate_gzip_pipe(@package_file).read
      @short_release_file = generate_short_release_file
      @release_file = generate_release_file
    end
    
    private
    
    def generate_release_file()
      partial_release_file = "Origin: apt.cloudscaling.com
Label: apt repository natty
Codename: natty
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
Label: apt repository natty
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
      @bucket = bucket
      @prefix = prefix
      @s3 = FRM::S3.new(access_key,secret_key,server)
      push_packages(package_release.packages)
      push_release_files(package_release)
    end

    private


    def push_release_files(package_release)
      # TODO: un-hardcode this
      release_path = @prefix + "/dists/natty/Release"
      @s3.put(release_path,package_release.release_file,@bucket)

      in_release_path = @prefix + "/dists/natty/InRelease"
      @s3.put(in_release_path,gpg_clearsign(package_release.release_file),@bucket)

      gpg_release_path = @prefix + "/dists/natty/Release.gpg"
      @s3.put(gpg_release_path,gpg_detached(package_release.release_file),@bucket)

      release_file_path = @prefix + "/dists/natty/" + package_release.component
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
      packages = in_packages.dup
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
    
    
    def generate_release
      return "Origin: apt.cloudscaling.com
     Label: apt repository natty
     Codename: natty
     Date: Thu, 22 Dec 2011 00:29:55 UTC
     Architectures: amd64
     Components: main universe multiverse
     Description: Cloudscaling APT repository
     MD5Sum:
      a4b943ff89790ccdc186875dad67827b 5813 main/binary-amd64/Packages
      004fd3f868ebbe7501fb2e1c0c54e2a7 2148 main/binary-amd64/Packages.gz
      79dd2fee35fba7255dcd40e1f6529591 134 main/binary-amd64/Release
      d41d8cd98f00b204e9800998ecf8427e 0 universe/binary-amd64/Packages
      7029066c27ac6f5ef18d660d5741979a 20 universe/binary-amd64/Packages.gz
      018c8e37146b908a6bde46012a83d4ba 138 universe/binary-amd64/Release
      d41d8cd98f00b204e9800998ecf8427e 0 multiverse/binary-amd64/Packages
      7029066c27ac6f5ef18d660d5741979a 20 multiverse/binary-amd64/Packages.gz
      4680f88c741bad22529909db5be4f608 140 multiverse/binary-amd64/Release
     SHA1:
      6e03924030eab56cb9735a52ec710537e682bcfc 5813 main/binary-amd64/Packages
      5f2989bae96e148cb5f18accc4357305926ab1e1 2148 main/binary-amd64/Packages.gz
      6d932af9af761f418e5374f73dcd09badb4fe57e 134 main/binary-amd64/Release
      da39a3ee5e6b4b0d3255bfef95601890afd80709 0 universe/binary-amd64/Packages
      46c6643f07aa7f6bfe7118de926b86defc5087c4 20 universe/binary-amd64/Packages.gz
      4d428e7ad434df47cffc40cabf8e238ee76ea434 138 universe/binary-amd64/Release
      da39a3ee5e6b4b0d3255bfef95601890afd80709 0 multiverse/binary-amd64/Packages
      46c6643f07aa7f6bfe7118de926b86defc5087c4 20 multiverse/binary-amd64/Packages.gz
      c8a7d2eb24ece57d460106506fcff99cb2ada015 140 multiverse/binary-amd64/Release
     SHA256:
      dd8283f06beb4a5fc06ac62d3ae098e5ba2717daef2a15b5f3e9233eb64e0227 5813 main/binary-amd64/Packages
      b197c5a3c1fe6a6d286e9f066a0cade289e3a2fc485c90407179951634788aa8 2148 main/binary-amd64/Packages.gz
      690b44df6fe65f40f260b73394e87804df78c9ccf13999889259faeed3eec40d 134 main/binary-amd64/Release
      e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 0 universe/binary-amd64/Packages
      59869db34853933b239f1e2219cf7d431da006aa919635478511fabbfc8849d2 20 universe/binary-amd64/Packages.gz
      32f35b1fc2bdc5a11b53abeadaaa77771b15acb5305777484bf4390d697ae5bd 138 universe/binary-amd64/Release
      e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 0 multiverse/binary-amd64/Packages
      59869db34853933b239f1e2219cf7d431da006aa919635478511fabbfc8849d2 20 multiverse/binary-amd64/Packages.gz
      f29816e3a4f90a8b4c688fdb2ac3056d5fb7349857c9ea8da2fbccf8e931baca 140 multiverse/binary-amd64/Release"
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
