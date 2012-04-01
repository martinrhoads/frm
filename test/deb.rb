#!/usr/bin/env ruby

require 'minitest/autorun'
require 'mock-aws-s3'

class TestReleasePusher < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    @tempfile3 = File.open('/tmp/martin_1.2.3.4_amd64.deb','w+') { |f| f.write 'martin' }
    
    hashes = []
    hashes << File.join(@@frm_test_base, 'debs', 'frm_foo-1.0.0.deb')
    hashes << File.join(@@frm_test_base, 'debs', 'frm_bar-1.0.0.deb')
    
    @package_release = FRM::PackageRelease.new(hashes)
    @release_pusher = FRM::ReleasePusher.new(@package_release,'1234','abcd',\
                                             'some-bucket','testing/tmp/frm')
  end

  def test

  end
  
end
 
