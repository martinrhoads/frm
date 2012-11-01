module FRM
  
  class PackageRelease < Base
    attr_reader :packages, :standards_version, :priority, :package_file, :gzipped_package_file, :release_file, :short_release_file, :component, :release, :i386_release_file, :i386_packages_file, :gzipped_i386_packages_file
    def initialize(packages={},release='natty',component='main/binary-amd64')
      @release = release
      @component = component
      @standards_version = standards_version
      @priority = priority
      @packages = []
      packages.each { |package| @packages << Package.new(package,@release) }
      if component == 'main/binary-amd64'
        generate_i386_stubs
      end
      @i386_release_file = <<EOF
Component: main
Origin: apt.cloudscaling.com
Label: apt repository #{@release}
Architecture: i386
Description: Cloudscaling APT repository
EOF
      @i386_packages_file = ""
      @gzipped_i386_packages_file = generate_gzip_pipe(@i386_packages_file).read
      @package_file = generate_package_file
      @gzipped_package_file = generate_gzip_pipe(@package_file).read
      @short_release_file = generate_short_release_file
      @release_file = generate_release_file
    end
    
    private

    
    # ubuntu precicse 64 wants i386 debs by default :\
    def generate_i386_stubs()
    end

    
    def generate_release_file()
      partial_release_file = "Origin: apt.cloudscaling.com
Label: apt repository #{@release}
Codename: #{@release}
Date: Thu, 22 Dec 2011 00:29:55 UTC
Architectures: amd64 i386
Components: main universe multiverse
Description: Cloudscaling APT repository
MD5Sum:
 #{compute_md5(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_md5(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_md5(@short_release_file)} #{@short_release_file.size} #{@component}/Release
 #{compute_md5(@i386_packages_file)} #{@i386_packages_file.size} main/binary-i386/Packages
 #{compute_md5(@gzipped_i386_packages_file)} #{@gzipped_i386_packages_file.size} main/binary-i386/Packages.gz
 #{compute_md5(@i386_release_file)} #{@i386_release_file.size} main/binary-i386/Release
SHA1:
 #{compute_sha1(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_sha1(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_sha1(@short_release_file)} #{@short_release_file.size} #{@component}/Release
 #{compute_sha1(@i386_packages_file)} #{@i386_packages_file.size} main/binary-i386/Packages
 #{compute_sha1(@gzipped_i386_packages_file)} #{@gzipped_i386_packages_file.size} main/binary-i386/Packages.gz
 #{compute_sha1(@i386_release_file)} #{@i386_release_file.size} main/binary-i386/Release
SHA256:
 #{compute_sha2(@package_file)} #{@package_file.size} #{@component}/Packages
 #{compute_sha2(@gzipped_package_file)} #{@gzipped_package_file.size} #{@component}/Packages.gz
 #{compute_sha2(@short_release_file)} #{@short_release_file.size} #{@component}/Release
 #{compute_sha2(@i386_packages_file)} #{@i386_packages_file.size} main/binary-i386/Packages
 #{compute_sha2(@gzipped_i386_packages_file)} #{@gzipped_i386_packages_file.size} main/binary-i386/Packages.gz
 #{compute_sha2(@i386_release_file)} #{@i386_release_file.size} main/binary-i386/Release
"
      return partial_release_file
    end


    def generate_short_release_file
      "Component: main
Origin: apt.cloudscaling.com
Label: apt repository #{@release}
Architecture: amd64
Description: Cloudscaling APT repository
"
    end
    

    def filename(package)
      filename = File.basename package.path
      shortname = run("dpkg --field #{package.path} Package")
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
      package_stub << run("dpkg --field #{package.path}") + "\n"
      package_stub << "Filename: #{filename(package)}\n"
      package_stub << "Size: #{package.size}\n"
      package_stub << "MD5sum: #{package.md5}\n"
      package_stub << "SHA1: #{package.sha1}\n"
      package_stub << "SHA256: #{package.sha2}\n"
      package_stub << "\n"
      return package_stub
    end
  end
end
