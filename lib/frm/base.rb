module FRM
  class Base
    def initialize
      @retries = 3
    end
    
    def compute_md5(string)
      Digest::MD5.hexdigest(string)
    end
    
    def compute_sha1(string)
      Digest::SHA1.hexdigest(string)
    end
    
    def compute_sha2(string)
      Digest::SHA2.hexdigest(string)
    end

    def run(command)
      output = `#{command} 2>&1`.chomp
      unless $?.success?
        STDERR.puts "failed to run command: #{command}"
        STDERR.puts "output was: "
        STDERR.puts output
        raise "failed to run command: #{command}"
      end
      return output
    end

    # TODO:
    # there has to be a better way to use gpg withen ruby. found many
    # broken solutions :\ 
    def gpg_clearsign(message)
      run "echo '#{message}' | gpg --clearsign"
    end

    # TODO: same as above
    def gpg_detached(message)
      run "echo '#{message}' | gpg -abs"
    end

    # TODO: same as above
    def gpg_export_pubkey
      run "gpg --armor --export"
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
    
    def handle_errors(&block)
      retries = 0
      begin
        yield
      rescue Object => error_object
        if retries < @retries
          sleep(2**retries * 1) #exponential backoff, 1s base
          retries += 1
          STDERR.puts "encountered error #{error_object.inspect}, retrying attempt #{retries}."
          retry
        else
          logger.error "encountered error #{error_object.inspect}, aborting."
          raise error_object
        end
      end
    end

    private 
    
  end
end
