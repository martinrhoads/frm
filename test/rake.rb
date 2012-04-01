@@frm_test_base = File.join @frm_base, 'test'

require File.join @@frm_test_base, 'lib', 'test'

namespace :test do
  
  desc "run the s3 test"
  task :s3 do
    require File.join @frm_base, 'lib', 'frm'
    require File.join @@frm_test_base, 's3'
  end
  
  desc "run the deb test"
  task :deb do
    require File.join @frm_base, 'lib', 'frm'
    require File.join @@frm_test_base, 'deb'
  end


  desc "run the old deb test"
  task :old_deb do
    require File.join @frm_base, 'lib', 'frm'
    require File.join @@frm_test_base, 'deb_test'
  end
  
end

