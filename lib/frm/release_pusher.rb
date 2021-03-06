module FRM
  
  class ReleasePusher < Base
    def initialize(package_release,access_key,secret_key,bucket,prefix,public_repo=false)
      @release = package_release.release
      @bucket = bucket
      @prefix = prefix
      @s3 = FRM::S3.new(access_key,secret_key,public_repo)
      push_packages(package_release.packages)
      push_release_files(package_release)
    end

    private


    def push_release_files(package_release)
      release_path = @prefix + "/dists/#{@release}/Release"
      in_release_path = @prefix + "/dists/#{@release}/InRelease"
      gpg_release_path = @prefix + "/dists/#{@release}/Release.gpg"

      unless @s3.exists?(release_path,@bucket)
        STDERR.puts "pushing new release files..."
        @s3.put(release_path,package_release.release_file,@bucket)
        @s3.put(in_release_path,gpg_clearsign(package_release.release_file),@bucket)
        @s3.put(gpg_release_path,gpg_detached(package_release.release_file),@bucket)
        
        
        release_file_path = @prefix + "/dists/#{@release}/" + package_release.component
        @s3.put(release_file_path + '/Release',package_release.short_release_file,@bucket)
        @s3.put(release_file_path + '/Packages',package_release.package_file,@bucket)
        @s3.put(release_file_path + '/Packages.gz',package_release.gzipped_package_file,@bucket)
        
        
        i386_release_file_path = @prefix + "/dists/#{@release}/" + 'main/binary-i386'
        @s3.put(i386_release_file_path + '/Release',package_release.i386_release_file,@bucket)
        @s3.put(i386_release_file_path + '/Packages',package_release.i386_packages_file,@bucket)
        @s3.put(i386_release_file_path + '/Packages.gz',package_release.gzipped_i386_packages_file,@bucket)
        
        # push public key
        @s3.put(@prefix + '/public.key',gpg_export_pubkey,@bucket)
      else
        STDERR.puts "updating releases file"
        release_file = @s3.get(release_path,@bucket)
        File.open('/tmp/in','w'){ |f|
          f.write(release_file)
        }
        in_buffer = File.open('/tmp/in',"r")
        out_buffer = File.open('/tmp/fd',"w")
        STDERR.puts "package_release.packages is #{package_release.packages.inspect}"
        merge_package_file(in_buffer,out_buffer,package_release.packages)

        STDERR.puts "not yet implmented"
        Kernel.exit 1
      end
    end
    

    def push_packages(packages)
      packages.each { |package| push_package(package) }
    end
    
    def push_package(package)
      remote_path = @prefix + '/' + package.info['Filename']
      if @s3.exists?(remote_path,@bucket) 
        unless @s3.etag(remote_path,@bucket) == package.info['MD5sum']
          error_message = <<EOE
trying to overwrite this package file: #{remote_path}
local md5 is #{package.info['MD5sum']}
remote md5 (etag) is #{@s3.etag(remote_path,@bucket)}
EOE
          raise error_message
        end
      else
        @s3.put(remote_path,package.content,@bucket)
      end
    end
    

  end
  
end
