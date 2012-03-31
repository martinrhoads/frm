#!/usr/bin/env ruby

require 'minitest/autorun'

my_dir = File.dirname __FILE__
require File.join my_dir, 'deb'

class TestReleasePusher < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    @tempfile3 = File.open('/tmp/martin_1.2.3.4_amd64.deb','w+') { |f| f.write 'martin' }
    
    hashes = %w{
                /home/martin/sheep/modules/substratum/debs/pod-services-0.5.0-967-amd64.deb
                /home/martin/sheep/modules/substratum/debs/cs-chef-0.9.1-1782-all.deb
                /home/martin/sheep/modules/substratum/debs/ruby1.9.2-1-amd64.deb
              }

    
    @package_release = FRM::PackageRelease.new(hashes)
    @release_pusher = FRM::ReleasePusher.new(@package_release,'1234','abcd',\
                                             'some-bucket','testing/tmp/frm')
  end

  def test

  end
  
end
 
