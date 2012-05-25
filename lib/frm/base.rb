module FRM
  class Base
    
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
      merge(in_pipe,out_pipe,sorted_list)
    end
    
    private 

    def create_package_stub(package_hash)
      return_value = ''
      package_hash.each do |key,value|
        return_value << "#{key}: #{value}\n"
      end
      return_value << "\n"
    end

    def merge(in_pipe,out_pipe,package_list)
      return if out_pipe.closed? 
      return if in_pipe.closed? and package_list.empty

      if package_list.empty? 
        while line = in_pipe.gets
          out_pipe.puts line
        end
        in_pipe.close
        out_pipe.close
        return
      end

      if in_pipe.closed? 
        package_list.each {|package_hash| out_pipe.write(create_package_stub(package_hash)) }
        out_pipe.close 
        return
      end
      
      current_package, stub = parse_package_stub in_pipe

      if current_package['Package'] < package_list.first['Package']
        out_pipe.puts stub
        out_pipe.puts ""
        merge(in_pipe,out_pipe,package_list)
        return
      elsif current_package['Package'] > package_list.first['Package']
        while ( ! package_list.empty? ) and current_package['Package'] > package_list.first['Package'] 
          out_pipe.write create_package_stub(package_list.shift)
        end
      elsif current_package['Package'] == package_list.first['Package']
        out_pipe.write create_package_stub(package_list.shift)
      end
      
      merge(in_pipe,out_pipe,package_list)
      return nil 
    end
    
  end
end
