# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rdbms_sampler/version"

Gem::Specification.new do |s|
  s.name        = "rdbms_sampler"
  s.version     = RdbmsSampler::VERSION
  s.authors     = ["Christian Rishoj"]
  s.email       = ["christian@rishoj.net"]
  s.homepage    = "https://github.com/crishoj/rdbms_sampler"
  s.summary     = %q{Extract a sample of records from a database while maintaining referential integrity.}
  s.description = %q{Ever found yourself wanting a modest amount of fresh rows from a production database for development purposes, but
put back by the need to maintain referential integrity in the extracted data sample? This data sampler utility will
take care that referential dependencies are fulfilled by recursively fetching any rows referred to by the sample.}

  s.rubyforge_project = "rdbms_sampler"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "schema_plus_foreign_keys"
  s.add_dependency "activerecord"
  s.add_dependency "commander"
  s.add_dependency "mysql2"

  s.add_development_dependency "pry"
end
