require 'aws-sdk'

module FRM
  class S3  < Base

    def initialize(opts={})
      super()
      @opts = opts.dup
      puts "@opts.inspect is #{@opts.inspect}"
      @opts[:public_repo] ||= false
      @opts[:acl] = @opts[:public_repo] ? :public_read : :private
      @opts[:access_key_id] ||= ENV['AWS_ACCESS_KEY_ID']
      @opts[:secret_access_key] ||= ENV['AWS_SECRET_ACCESS_KEY']
      raise "you either need to pass an aws_access_key option or set the AWS_ACCESS_KEY environment variable" if @opts[:access_key_id].nil?
      raise "you either need to pass an aws_secret_key option or set the AWS_SECRET_KEY environment variable" if @opts[:secret_access_key].nil?
      raise "you need to pass in a bucket param" unless @opts[:bucket]
      raise "you need to pass in a prefix param" unless @opts[:prefix]
      @opts[:prefix] = @opts[:prefix] +  '/' unless @opts[:prefix][-1] == '/'
      AWS.config(:access_key_id => @opts[:access_key_id],
                 :secret_access_key => @opts[:secret_access_key])
      @s3 = AWS::S3.new
    end
    
    def exists?(relative_path)
      handle_errors do
        return @s3.buckets[@opts[:bucket]].objects[full_path(relative_path)].exists?
      end
    end

    def etag(relative_path)
      quoted_etag = ""
      handle_errors do
        quoted_etag = @s3.buckets[@opts[:bucket]].objects[full_path(relative_path)].etag
      end
      # stupid method call is actually putting quotes in the string,
      # so let's remove those:
      return quoted_etag.gsub(/"/,'')
    end

    def put(relative_path,value)
      handle_errors do
        @s3.buckets[@opts[:bucket]].objects[full_path(relative_path)].write(value,acl: @opts[:acl]) #
      end
      return true
    end

    def get(relative_path)
      handle_errors do
        return @s3.buckets[@opts[:bucket]].objects[full_path(relative_path)].read
      end
    end

    def delete(relative_path)
      handle_errors do
        @s3.buckets[@opts[:bucket]].objects[full_path(relative_path)].delete
      end
      return true
    end

    def move(old_relative_path,new_relative_path)
      handle_errors do
        @s3.buckets[@opts[:bucket]].objects[full_path(old_relative_path)].move_to(new_relative_path)
      end
      return true
    end

    protected

    def full_path(relative_path="")
      return @opts[:prefix] + relative_path
    end

  end
end

