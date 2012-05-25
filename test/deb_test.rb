#!/usr/bin/env ruby

require 'minitest/autorun'

my_dir = File.dirname __FILE__
require File.join my_dir, 'deb'

class TestReleasePusher < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    @tempfile3 = File.open('/tmp/martin_1.2.3.4_amd64.deb','w+') { |f| f.write 'martin' }
    
    hashes = []
    hashes << File.join(@@frm_test_base, 'debs', 'frm_foo-1.0.0.deb')
    hashes << File.join(@@frm_test_base, 'debs', 'frm_bar-1.0.0.deb')
    
    @package_release = FRM::PackageRelease.new(hashes)
    @release_pusher = FRM::ReleasePusher.new(@package_release,'abcd','1234',\
                                             'some-bucket','testing/tmp/martin/foo')
  end

  def test
#    puts "@release_pusher.inspect = #{@release_pusher.inspect}"
  end
  
end

  class TestPackageRelease < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo_1.2.68_amd64.deb','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar_1.2.3.4_amd64.deb','w+') { |f| f.write 'bar' }
    
    hashes = []
    hashes << File.join(@@frm_test_base, 'debs', 'frm_foo-1.0.0.deb')
    hashes << File.join(@@frm_test_base, 'debs', 'frm_bar-1.0.0.deb')
    
    @package_release = FRM::PackageRelease.new(hashes)
  end
  
  def test()
    correct_output = "Package: frm-foo
Version: 1.0
License: unknown
Vendor: martin@host-c1e5ea34
Architecture: amd64
Maintainer: <martin@host-c1e5ea34>
Installed-Size: 0
#Pre-Depends: 
Section: default
Priority: extra
Homepage: http://example.com/no-uri-given
Description: no description given
Filename: pool/main/f/frm-foo/frm_foo-1.0.0.deb
Size: 716
MD5sum: 0faf8cabf49a615adacbe6d80c4aee3b
SHA1: 78c6be70488c78d63b6eb233f891e80d3af0b779
SHA256: 5f0de3c65226c13e9c215478ba784afe54b0592aa46766ff19b1140644bbda71

Package: frm-bar
Version: 1.0
License: unknown
Vendor: martin@host-c1e5ea34
Architecture: amd64
Maintainer: <martin@host-c1e5ea34>
Installed-Size: 0
#Pre-Depends: 
Section: default
Priority: extra
Homepage: http://example.com/no-uri-given
Description: no description given
Filename: pool/main/f/frm-bar/frm_bar-1.0.0.deb
Size: 716
MD5sum: b21df912829a23f9846ddd022fc74c74
SHA1: 0592c2eb2f3f5a830109d63b83ab438c7c258d14
SHA256: 131f5d16fdd7ddf8bf9c4983d77022b268c02b2864ce9a9f841704631417515d

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
    correct_release_file = "Origin: apt.cloudscaling.com
Label: apt repository natty
Codename: natty
Date: Thu, 22 Dec 2011 00:29:55 UTC
Architectures: amd64
Components: main universe multiverse
Description: Cloudscaling APT repository
MD5Sum:
 c0ff97432f4ac04c99b2ddee0a1d5fed 986 main/binary-amd64/Packages
 5bfa5912649f52c32d2e740fc727ebd5 462 main/binary-amd64/Packages.gz
 79dd2fee35fba7255dcd40e1f6529591 134 main/binary-amd64/Release
SHA1:
 2ecb580a151f0cf625016352b2a474b787cc0ac3 986 main/binary-amd64/Packages
 80a6c1f004fb7b6bcb1ce3f86d16e53b5735ac84 462 main/binary-amd64/Packages.gz
 6d932af9af761f418e5374f73dcd09badb4fe57e 134 main/binary-amd64/Release
SHA256:
 ae8b50085f2405febff78f86fe7d89d93d9ff94ceccfbfa975c0bd79e63ce385 986 main/binary-amd64/Packages
 cb8501ace11b9bdbfd0d65006a116313f5c6fda625d6383a549e80b982fc6eac 462 main/binary-amd64/Packages.gz
 690b44df6fe65f40f260b73394e87804df78c9ccf13999889259faeed3eec40d 134 main/binary-amd64/Release
"
    assert @package_release.release_file == correct_release_file
  end

end


class TestPackage < MiniTest::Unit::TestCase
  def setup
    @tempfile1 = File.open('/tmp/foo','w+') { |f| f.write 'foo' }
    @tempfile2 = File.open('/tmp/bar','w+') { |f| f.write 'bar' }

    package = File.join(@@frm_test_base, 'debs', 'frm_foo-1.0.0.deb')
    
    @package1 = FRM::Package.new(package)
  end
  
  def test_bad_file()
    bad_package = "/some/bad/path"
    assert_raises(RuntimeError) { FRM::Package.new(bad_package) } 
  end
  
  def test_good_file()
    assert Digest::MD5.hexdigest(@package1.content) == '0faf8cabf49a615adacbe6d80c4aee3b'
  end

  def test_hashes()
    assert @package1.md5 == '0faf8cabf49a615adacbe6d80c4aee3b'
    assert @package1.sha1 == '78c6be70488c78d63b6eb233f891e80d3af0b779'
    assert @package1.sha2 == '5f0de3c65226c13e9c215478ba784afe54b0592aa46766ff19b1140644bbda71'
    
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
             },
             {
               "Package" => "qqq",
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
correct_output = 'Package: bar
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

Package: foo
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

Package: qqq
Version: 1.2.3.4
Architecture: amd64
Maintainer: <support@cloudscaling.com>
Homepage: http://www.cloudscaling.com
Priority: extra
Depends: one, two, three
Filename: pool/main/q/qqq/qqq_1.2.3.4_amd64.deb
Size: 3
MD5sum: 37b51d194a7513e45b56f6524f2d51f2
SHA1: 62cdb7020ff920e5aa642c3d4066950dd1f01f4d
SHA256: fcde2b2edba56bf408601fb721fe9b5c338d10ee429ea04fae5511b68fbf8fb9
Description: no description given

'
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
    package_file = File.open File.join @@frm_test_base, 'Packages.txt'
    read_buffer, write_buffer = IO.pipe
    merged_list = @deb.merge_package_file(package_file,write_buffer,@hash)
    assert true
  end
  
  
end
