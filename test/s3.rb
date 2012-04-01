#!/usr/bin/env ruby

require 'minitest/autorun'
# my_dir = File.dirname __FILE__
# require File.join my_dir, 's3'

require 'mock-aws-s3'

# this is a stupid hack to get the @@bucket region set properly
DEFAULT_HOST =  's3-us-west-1.amazonaws.com'

class TestFRM < MiniTest::Unit::TestCase

  # these credentials only have access inside of cloudscaling-us-west-develop/testing/
  @@access_key_id = 'abcd'
  @@secret_key_id = '1234'
  @@bucket = 'some-bucket'
  @@prefix = 'testing/'
  @@server = 's3-us-west-1.amazonaws.com'
  @@timestamp = rand(9999).to_s

  
  @@key = @@prefix + "testing-" + @@timestamp.to_s
  @@value = "rand: " + @@timestamp

  # we need minitest to run in order
  def self.test_order
    :alpha
  end
  
  def setup
    @frm = FRM::S3.new(@@access_key_id,@@secret_key_id,@@server)
  end

  def test_aput
    assert @frm.put @@key,@@value,@@bucket
  end

  def test_bkey?
    assert @frm.key? @@key,@@bucket
  end

  def test_cget
    assert_equal @@value, @frm.get(@@key,@@bucket)
  end

  def test_ddelete
    assert @frm.delete @@key, @@bucket
  end

  # this is broken :(
  def test_ekey?
    skip 'need to debug key?'
    refute  @frm.key?(@@key,@@bucket)
  end

end
