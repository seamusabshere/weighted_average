# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "weighted_average/version"

Gem::Specification.new do |s|
  s.name        = "weighted_average"
  s.version     = WeightedAverage::VERSION
  s.authors     = ["Seamus Abshere", "Andy Rossmeissl", "Ian Hough", "Matt Kling"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/weighted_average"
  s.summary = %Q{Perform weighted averages. Rails 3 only.}
  s.description = %Q{Perform weighted averages, even across associations. Rails 3 only because it uses ARel.}

  s.rubyforge_project = "weighted_average"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activerecord', '~>3'
  s.add_runtime_dependency 'activesupport', '~>3'
  s.add_runtime_dependency 'arel', '~>2'
  
  s.add_development_dependency 'cohort_scope', '>=0.0.2'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mysql'
end


