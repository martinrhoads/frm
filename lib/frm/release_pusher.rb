module FRM
  
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
    

    def merge_release_files(package_release)
      
      #TODO: check for previous release file and merge in
      if @s3.key?(release_file_path + '/Packages.gz',@bucket)
        merged_package_file

        package_release.overwrite_package_file(merged_package_file)
      end

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
  
end
