@frm_test_base = File.join @frm_base, 'test'

namespace :test do
  
  desc "run the s3 test"
  task :s3 do
    require File.join @frm_base, 'lib', 'frm'
    require File.join @frm_test_base, 's3'
  end
  
end

