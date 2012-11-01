# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "frm/version"

Gem::Specification.new do |s|
  s.name        = "frm"
  s.version     = Frm::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Martin Rhoads"]
  s.email       = ["ermal14@gmail.com"]
  s.homepage    = "https://github.com/ermal14/frm"
  s.summary     = %q{Effin Repo Manager}
  s.description = %q{FRM makes it easy to build package repositories on S3}

  s.rubyforge_project = "frm"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["bin"]
  s.require_paths = ["lib"]

  s.add_dependency('aws-sdk')

end

