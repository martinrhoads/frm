my_dir = File.dirname __FILE__
STDERR.puts "#{File.join my_dir, 's3'}"
#require File.join my_dir, 'base'


module FRM
  class S3  < Base
    attr_reader :max_retries
    @connection
    def initialize(access_key_id,secret_access_key,server='s3.amazonaws.com')
      require 'aws/s3'
      @max_retries = 10
      @connection = AWS::S3::Base.establish_connection!(:access_key_id     => access_key_id,
                                                        :secret_access_key => secret_access_key,
                                                        :server => server )
    end
    
    def key?(key,bucket)
      AWS::S3::S3Object.exists?(key,bucket)
    end
    
    def put(key,value,bucket)
      @max_retries.times do |i|
        begin
          AWS::S3::S3Object.store(key,value,bucket,:server => 's3-us-west-1.amazonaws.com',:access => :public_read)
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
          value = AWS::S3::S3Object.value(key,bucket)
          return value
        rescue Object => o
          print_retry(__method__,o)
        end
        raise "could not get object!!!" if i == (@max_retries - 1)
      end
      raise "could not get object!!!"
    end
    
    def get_stream(key,bucket)
      @max_retries.times do |i|
        begin
          stream = AWS::S3::S3Object.stream(key,bucket)
          return stream
        rescue Object => o
          print_retry(__method__,o)
        end
        raise "could not get object!!!" if i == (@max_retries - 1)
      end
      raise "could not get object!!!"
    end
    
    def delete(key,bucket)
      begin
        AWS::S3::S3Object.delete(key,bucket)
        true
      rescue Object => o
        print_retry(__method__,o)
      end
    end

    def move(old_key,new_key,vucket)
      begin
        AWS::S3::S3Object.rename(old_key,new_key,bucket)
        return
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
