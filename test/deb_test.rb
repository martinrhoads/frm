#!/usr/bin/env ruby

require 'minitest/autorun'

my_dir = File.dirname __FILE__
require File.join my_dir, 'deb'

class TestReleasePusher < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    @tempfile3 = File.open('/tmp/martin_1.2.3.4_amd64.deb','w+') { |f| f.write 'martin' }
    
    hashes = [{
                "Package" => "foo",
                "Version" => "1.2.68",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "Depends" => %w{one two three},
                "section" => "main",
                "path_to_deb" => '/tmp/foo_1.2.68_amd64.deb',
                "Description" => 'some
 multiline
 description'
              },
              {
                "Package" => "bar",
                "Version" => "1.2.3.4",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "Depends" => %w{one two three},
                "section" => "main",
                "path_to_deb" => '/tmp/bar_1.2.3.4_amd64.deb'
              },
              {
                "Package" => "martin",
                "Version" => "1.2.3.4",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "section" => "main",
                "path_to_deb" => '/tmp/martin_1.2.3.4_amd64.deb'
              },
              {
                "Package" => "cs-chef",
                "Version" => "1.2.3.4",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "section" => "main",
                "path_to_deb" => '/tmp/debs/cs-chef-0.9.1-1782-all.deb'
              }
             ]
    
    @package_release = FRM::PackageRelease.new(hashes)
    @release_pusher = FRM::ReleasePusher.new(@package_release,'abcd','1234',\
                                             'some-bucket','testing/tmp/martin/foo')
  end

  def test
    puts "@release_pusher.inspect = #{@release_pusher.inspect}"
  end
  
end

  class TestPackageRelease < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    
    hashes = [{
                "Package" => "foo",
                "Version" => "1.2.68",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "Depends" => %w{one two three},
                "section" => "main",
                "path_to_deb" => '/tmp/foo_1.2.68_amd64.deb',
                "Description" => 'some
 multiline
 description'
              },
              {
                "Package" => "bar",
                "Version" => "1.2.3.4",
                "Architecture" => "amd64",
                "Maintainer" => "support@cloudscaling.com",
                "Homepage" => "http://www.cloudscaling.com",
                "Priority" => "extra",
                "Depends" => %w{one two three},
                "section" => "main",
                "path_to_deb" => '/tmp/bar_1.2.3.4_amd64.deb'
              }
             ]
    
    @package_release = FRM::PackageRelease.new(hashes)
  end
  
  def test()
    correct_output = "Package: foo
Version: 1.2.68
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Standards-Version: 3.9.1
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/f/foo/foo_1.2.68_amd64.deb
Size: 3
MD5sum: acbd18db4cc2f85cedef654fccc4a4d8
SHA1: 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
Description: some
 multiline
 description

Package: bar
Version: 1.2.3.4
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Standards-Version: 3.9.1
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/b/bar/bar_1.2.3.4_amd64.deb
Size: 3
MD5sum: 37b51d194a7513e45b56f6524f2d51f2
SHA1: 62cdb7020ff920e5aa642c3d4066950dd1f01f4d
SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9
Description: no description given

"
    assert @package_release.package_file == correct_output
  end

  def test_generate_short_release_file
    correct_short_release_file = "Component: main
Origin: apt.cloudscaling.com
Label: apt repository natty
Architecture: amd64
Description: Cloudscaling APT repository
"
    assert @package_release.short_release_file == correct_short_release_file
  end
  
  def test_generate_release
#    skip 'need to finish generate_release function'
    correct_release_file = "Origin: apt.cloudscaling.com
Label: apt repository natty
Codename: natty
Date: Thu, 22 Dec 2011 00:29:55 UTC
Architectures: amd64
Components: main universe multiverse
Description: Cloudscaling APT repository
MD5Sum:
 32aed966f2f629d6229d14cd37da740e 896 main/binary-amd64/Packages
 a2ea734a1d863873d0acd98845bd0573 438 main/binary-amd64/Packages.gz
 79dd2fee35fba7255dcd40e1f6529591 134 main/binary-amd64/Release
SHA1:
 b2f872140a4e651609c1ce7538dba871a4ad49de 896 main/binary-amd64/Packages
 86b1fc7c8905cf35a9ff2544bb277c332e93b7d1 438 main/binary-amd64/Packages.gz
 6d932af9af761f418e5374f73dcd09badb4fe57e 134 main/binary-amd64/Release
SHA256:
 14139ad7300259e51e2c0d75891966d10f9382adbda61c7348990ccf125e4d4f 896 main/binary-amd64/Packages
 67014ee7cc96108af726aae5636d26225c2cd833301765e44cf6cb6ea7719698 438 main/binary-amd64/Packages.gz
 690b44df6fe65f40f260b73394e87804df78c9ccf13999889259faeed3eec40d 134 main/binary-amd64/Release
"
    assert @package_release.release_file == correct_release_file
  end

end


class TestPackage < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar','w+') { |f| f.write 'bar' }

    @hash = {
      "Package" => "foo",
      "Version" => "1.2.68",
      "Architecture" => "amd64",
      "Maintainer" => "support@cloudscaling.com",
      "Homepage" => "http://www.cloudscaling.com",
      "Priority" => "extra",
      "Depends" => %w{one two three},
      "section" => "main",
      "path_to_deb" => '/tmp/foo',
      "Description" => 'some
 multiline
 description'
    }
    
    @package1 = FRM::Package.new(@hash)
  end
  
  def test()
    assert @package1.name == 'foo'
    assert @package1.content == 'foo'
  end

  def test_bad_file()
    bad_hash = {
      "Package" => "foo",
      "Version" => "1.2.68",
      "Architecture" => "amd64",
      "Maintainer" => "support@cloudscaling.com",
      "Homepage" => "http://www.cloudscaling.com",
      "Priority" => "extra",
      "Depends" => %w{one two three},
      "section" => "main",
      "path_to_deb" => '/some/bad/path',
      "Description" => 'some
 multiline
 description'
    }
    assert_raises(RuntimeError) { FRM::Package.new(bad_hash) } 
  end
  
  def test_good_file()
    assert @package1.content == 'foo'
  end

  def test_hashes()
    assert @package1.md5 == 'acbd18db4cc2f85cedef654fccc4a4d8'
    assert @package1.sha1 == '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'
    assert @package1.sha2 == '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae'
    
  end
  
  
end


class TestDeb < MiniTest::Unit::TestCase
  
  def setup
    @deb = FRM::Deb.new()
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    
    @hash = [
             {
               "Package" => "foo",
               "Version" => "1.2.68",
               "Architecture" => "amd64",
               "Maintainer" => "support@cloudscaling.com",
               "Homepage" => "http://www.cloudscaling.com",
               "Priority" => "extra",
               "Depends" => %w{one two three},
               "section" => "main",
               "path_to_deb" => '/tmp/foo_1.2.68_amd64.deb',
               "Description" => 'some
 multiline
 description'
             },
             {
               "Package" => "bar",
               "Version" => "1.2.3.4",
               "Architecture" => "amd64",
               "Maintainer" => "support@cloudscaling.com",
               "Homepage" => "http://www.cloudscaling.com",
               "Priority" => "extra",
               "Depends" => %w{one two three},
               "section" => "main",
               "path_to_deb" => '/tmp/bar_1.2.3.4_amd64.deb'
             }
            ]
  end

  def teardown
    File.delete '/tmp/foo_1.2.68_amd64.deb' if File.exists? '/tmp/foo_1.2.68_amd64.deb'
    File.delete '/tmp/bar_1.2.3.4_amd64.deb' if File.exists? '/tmp/bar_1.2.3.4_amd64.deb'
  end
  
  
  def test_generate_package_stub
    correct_output = "Package: foo
Version: 1.2.68
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/f/foo/foo_1.2.68_amd64.deb
Size: 3
MD5sum: acbd18db4cc2f85cedef654fccc4a4d8
SHA1: 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
Description: some
 multiline
 description

"

    duplicate_hash = @hash[0].dup
    assert @deb.generate_package_stub(duplicate_hash) == correct_output
    assert @hash[0] == duplicate_hash
  end

  
  def  test_generate_package_file
    correct_output = "Package: foo
Version: 1.2.68
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/f/foo/foo_1.2.68_amd64.deb
Size: 3
MD5sum: acbd18db4cc2f85cedef654fccc4a4d8
SHA1: 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
Description: some
 multiline
 description

Package: bar
Version: 1.2.3.4
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/b/bar/bar_1.2.3.4_amd64.deb
Size: 3
MD5sum: 37b51d194a7513e45b56f6524f2d51f2
SHA1: 62cdb7020ff920e5aa642c3d4066950dd1f01f4d
SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9
Description: no description given

"
    assert @deb.generate_package_file(@hash) == correct_output
  end

  def test_gzip
    input = generate_random_string
    gziped_pipe = @deb.generate_gzip_pipe(input)
    output = @deb.gunzip_pipe gziped_pipe
    assert input == output
  end

  
  def test_md5
    input = 'foo'
    assert @deb.compute_md5(input) == 'acbd18db4cc2f85cedef654fccc4a4d8'
  end

  def test_sha1
    input = 'foo'
    assert @deb.compute_sha1(input) == '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33'
  end

  def test_sha256
    input = 'foo'
    assert @deb.compute_sha2(input) == '2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae'
  end

  def test_generate_package_release
    package_release_file = "Component: main
Origin: apt.cloudscaling.com
Label: apt repository natty
Architecture: amd64
Description: Cloudscaling APT repository
"
    assert @deb.generate_package_release == package_release_file
  end
  
  def test_generate_release
    skip 'need to finish generate_release function'
    release_file = "Origin: apt.cloudscaling.com
Label: apt repository natty
Codename: natty
Date: Thu, 22 Dec 2011 00:29:55 UTC
Architectures: amd64
;Components: main universe multiverse
Description: Cloudscaling APT repository
MD5Sum:
 a4b943ff89790ccdc186875dad67827b 5813 main/binary-amd64/Packages
 004fd3f868ebbe7501fb2e1c0c54e2a7 2148 main/binary-amd64/Packages.gz
 79dd2fee35fba7255dcd40e1f6529591 134 main/binary-amd64/Release
SHA1:
 6e03924030eab56cb9735a52ec710537e682bcfc 5813 main/binary-amd64/Packages
 5f2989bae96e148cb5f18accc4357305926ab1e1 2148 main/binary-amd64/Packages.gz
 6d932af9af761f418e5374f73dcd09badb4fe57e 134 main/binary-amd64/Release
SHA256:
 dd8283f06beb4a5fc06ac62d3ae098e5ba2717daef2a15b5f3e9233eb64e0227 5813 main/binary-amd64/Packages
 b197c5a3c1fe6a6d286e9f066a0cade289e3a2fc485c90407179951634788aa8 2148 main/binary-amd64/Packages.gz
 690b44df6fe65f40f260b73394e87804df78c9ccf13999889259faeed3eec40d 134 main/binary-amd64/Release
"
    assert @deb.generate_release == release_file
  end
  
  def generate_random_string
    rand(36**rand(50)).to_s(36)
  end

  def test_parse_package_stub
    input_stub = "Package: foo
Version: 1.2.68
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/f/foo/foo_1.2.68_amd64.deb
Size: 3
MD5sum: acbd18db4cc2f85cedef654fccc4a4d8
SHA1: 0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33
SHA256: 2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae
Description: some
 multiline
 description

Package: bar
Version: 1.2.3.4
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/b/bar/bar_1.2.3.4_amd64.deb
Size: 3
MD5sum: 37b51d194a7513e45b56f6524f2d51f2
SHA1: 62cdb7020ff920e5aa642c3d4066950dd1f01f4d
SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9
Description: no description given

"
    correct_hash = {"Package"=>"foo", "Version"=>"1.2.68", "Architecture"=>"amd64", "Maintainer"=>"<support@cloudscaling.com>", "Homepage"=>"http://www.cloudscaling.com", "Priority"=>"extra", "Depends"=>"one, two, three", "Filename"=>"pool/main/f/foo/foo_1.2.68_amd64.deb", "Size"=>"3", "MD5sum"=>"acbd18db4cc2f85cedef654fccc4a4d8", "SHA1"=>"0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33", "SHA256"=>"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae", "Description"=>"some multiline\n description"}
    read_buffer, write_buffer = IO.pipe
    write_buffer.write input_stub
    write_buffer.close
    assert @deb.parse_package_stub(read_buffer.dup)[0] == correct_hash
    assert_raises(RuntimeError) { @deb.parse_package_stub File.open('/tmp/foo') }
  end

  
  def test_merge_package_file
    package_file = File.open 'Packages.txt'
    read_buffer, write_buffer = IO.pipe

    @deb.merge_package_file(package_file,write_buffer,@hash)
    
  end
  
  
end
