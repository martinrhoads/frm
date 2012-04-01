module FRM
  class Base
    # my_dir = File.dirname __FILE__
    # require File.join my_dir, 's3'
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
      # while (next_stub = parse_package_stub in_pipe)
      #   STDERR.puts "next_stub[0] = #{next_stub[0]}"
      # end
    end
  end
end
