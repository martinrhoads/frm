require 'zlib'
require 'tempfile'
require 'digest/md5'
require 'digest/sha1'
require 'digest/sha2'
require 'logger'
require 'net/ntp'

require_relative 'frm/base'
require_relative 'frm/s3'
require_relative 'frm/package'
require_relative 'frm/arch_release'
require_relative 'frm/release_pusher'
require_relative 'frm/deb'


module FRM
  class Release < Base

    def initialize(opts={})
      super()
      @opts = opts
      @opts[:component] ||= 'main'
      @opts[:origin] ||= 'FRM'
      @opts[:label] ||= 'FRM'
      @opts[:description] = "FRM apt repo"
      @opts[:release] ||= run ". /etc/lsb-release && echo $DISTRIB_CODENAME"
      handle_errors{@time = Net::NTP.get("us.pool.ntp.org").time.getutc}

      case run("uname -m")
      when "x86_64"
        @opts[:arch] ||= 'amd64'
      else
        @opts[:arch] ||= run "uname -m"
      end

      @opts[:remote_store] = FRM::S3.new(opts)
      @arch_releases = [ArchRelease.new(opts)]
      @arch_releases << ArchRelease.new(arch: 'i386',remote_store: @opts[:remote_store]) \
        if @opts[:arch] == 'amd64'

      @release_file = release_file
      @in_release_file = gpg_clearsign(release_file)
      @release_gpg_file = gpg_detached(release_file)

      @release_file_path = "dists/#{@opts[:release]}/Release"
      @in_release_file_path = "dists/#{@opts[:release]}/InRelease"
      @release_gpg_file_path = "dists/#{@opts[:release]}/Release.gpg"

    end

    def push
      @arch_releases.each {|arch_release| arch_release.push}
      @opts[:remote_store].put(@release_file_path,@release_file)
      @opts[:remote_store].put(@in_release_file_path,@in_release_file)
      @opts[:remote_store].put(@release_gpg_file_path,@release_gpg_file)
      
      # push public key
      @opts[:remote_store].put('public.key',gpg_export_pubkey)
    end

    def merge
    end
    
    private 


    # ubuntu precicse 64 wants i386 debs by default :\
    def generate_i386_stubs()
    end

    def release_file()
      partial_release_file = <<EOF
Origin: #{@opts[:origin]}
Label: #{@opts[:label]}
Codename: #{@opts[:release]}
Date: #{@time.getutc.strftime("%a, %d %b %Y %H:%M:%S UTC")}
Architectures: #{@arch_releases.collect{|r| r.opts[:arch]}.join(' ')}
Components: #{@opts[:component]}
Description: #{@opts[:description]}
EOF

      %w{MD5Sum SHA1 SHA256}.each do |hash|
        partial_release_file << "#{hash}:\n"
        @arch_releases.each do |arch_release|
          %w{package gzipped_package release}.each do |file|
            partial_release_file << " #{arch_release.opts["#{file}_file_#{hash.downcase}".to_sym]} "
            partial_release_file << arch_release.opts["#{file}_file_size".to_sym].to_s
            partial_release_file << " "
            partial_release_file << arch_release.opts["#{file}_file_path".to_sym]
            partial_release_file << "\n"
          end
        end
      end
      return partial_release_file
    end
    
  end
end
