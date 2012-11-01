require 'aws-sdk'

module FRM
  class S3  < Base

    attr_reader :max_retries, :s3, :acl

    def initialize(access_key_id,secret_access_key,public_repo=false)
      @max_retries = 10
      AWS.config(:access_key_id => access_key_id, 
                 :secret_access_key => secret_access_key)
      @s3 = AWS::S3.new
      @acl = public_repo ? :public_read : :private
    end

    
    def key?(key,bucket)
      @s3.buckets[bucket].objects[key].exists?
    end

    
    def put(key,value,bucket)
      @max_retries.times do |i|
        begin
          @s3.buckets[bucket].objects[key].write(value,acl: @acl)
          return true
        rescue Object => o
          print_retry(__method__,o)
        end
        raise "could not put object!!!" if i == (@max_retries - 1)
      end
      raise "could not put object!!!"
    end
    
    
    def get(key,bucket)
      @max_retries.times do |i|
        begin
          return @s3.buckets[bucket].objects[key].read
        rescue Object => o
          print_retry(__method__,o)
        end
        raise "could not get object!!!" if i == (@max_retries - 1)
      end
      raise "could not get object!!!"
    end
    
    
    def delete(key,bucket)
      begin
        @s3.buckets[bucket].objects[object].delete
        return true
      rescue Object => o
        print_retry(__method__,o)
      end
    end


    def move(old_key,new_key,bucket)
      begin
        @s3.buckets[bucket].objects[old_key].move_to(new_key)
        return true
      rescue Object => o
        print_retry(__method__,o)
      end
    end

    protected

    def print_retry(action,error)
      STDERR.puts "coudld not #{action} object because of:"
      STDERR.puts error.inspect
      STDERR.puts ", retrying..."
      sleep 2
    end
    
  end
end
