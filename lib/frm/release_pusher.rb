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


      i386_release_file_path = @prefix + "/dists/#{@release}/" + 'main/binary-i386'
      @s3.put(i386_release_file_path + '/Release',package_release.i386_release_file,@bucket)
      @s3.put(i386_release_file_path + '/Packages',package_release.i386_packages_file,@bucket)
      @s3.put(i386_release_file_path + '/Packages.gz',package_release.gzipped_i386_packages_file,@bucket)
      # push public key
      @s3.put(@prefix + '/public.key',gpg_export_pubkey,@bucket)
    end
    

    def push_packages(packages)
      packages.each { |package| push_package(package) }
    end
    
    def push_package(package)
      remote_path = @prefix + '/' + package.repo_filename
      if @s3.exists?(remote_path,@bucket) 
        unless @s3.etag(remote_path,@bucket) == package.md5
          error_message = <<EOE
trying to overwrite this package file: #{remote_path}
local md5 is #{package.md5}
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
