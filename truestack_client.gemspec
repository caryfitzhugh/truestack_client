# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "truestack_client/version"

Gem::Specification.new do |s|
  s.name        = "truestack_client"
  s.version     = TruestackClient::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Greenfry Labs"]
  s.email       = ["gems@greenfrylabs.com"]
  s.homepage    = "http://www.truestack.com"
  s.summary     = %q{Client thread-safe library which connects to the truestack backend}
  s.description = %q{Client library which is thread-safe, which connects to the truestack backend.  Uses websockets or POSTs depending on what is available.}

  s.rubyforge_project = "truestack_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
