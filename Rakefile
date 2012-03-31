require 'bundler'
Bundler::GemHelper.install_tasks

fpm_base = File.dirname __FILE__

namespace :bump do
  
  desc "bump the patch version number"
  task :patch do
    version_file_path = File.join fpm_base, 'lib', 'frm', 'version.rb'
    current_version_file = File.read version_file_path
    current_version_file =~ /VERSION[^\d]+(\d+)\.(\d+)\.(\d+)(\.([^'"]*))?/
    major,minor,patch = $1, $2, $3
    new_version = [$1,$2,$3.to_i+1].join('.')
    new_version_file = current_version_file.sub /VERSION\s*=.*/, %Q{VERSION = "#{new_version}"}
    File.open(version_file_path, 'w') {|f| f.write(new_version_file) }
    puts "bumping version to #{new_version}"
  end
  
end

