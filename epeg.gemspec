lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "epeg"
  spec.version       = 1.0
  spec.authors       = ["Aria Stewart"]
  spec.email         = ["aredridel@dinhe.net"]
  spec.summary       = %q{Ruby extension for the epeg library.}
  spec.homepage      = "http://github.com/aredridel/ruby-epeg"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["."]
  spec.extensions    = ["extconf.rb"]
end
