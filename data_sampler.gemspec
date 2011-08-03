# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "data_sampler/version"

Gem::Specification.new do |s|
  s.name        = "data_sampler"
  s.version     = DataSampler::VERSION
  s.authors     = ["Christian Rishøj"]
  s.email       = ["christian@rishoj.net"]
  s.homepage    = "https://github.com/crishoj/data_sampler"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "data_sampler"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "schema_plus"
  s.add_dependency "activerecord"
end
