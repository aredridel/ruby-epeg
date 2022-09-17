require 'mkmf'

require 'timeout'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

$CFLAGS << " #{ENV["CFLAGS"]}"
$CFLAGS << " -g"
$CFLAGS << " -O3" unless $CFLAGS[/-O\d/]
$CFLAGS << " -Wall -Wno-comment"

cmake_flags = [ ENV["CMAKE_FLAGS"] ]

def sys(cmd)
  puts " -- #{cmd}"
  unless ret = xsystem(cmd)
    raise "ERROR: '#{cmd}' failed"
  end
  ret
end

# Thrown when we detect CMake is taking too long and we killed it
class CMakeTimeout < StandardError
end

def self.run_cmake(timeout, args)
  # Set to process group so we can kill it and its children
  pgroup = Gem.win_platform? ? :new_pgroup : :pgroup
  pid = Process.spawn("cmake #{args}", pgroup => true)

  Timeout.timeout(timeout) do
    Process.waitpid(pid)
  end

rescue Timeout::Error
  # Kill it, #detach is essentially a background wait, since we don't actually
  # care about waiting for it now
  Process.kill(-9, pid)
  Process.detach(pid)
  raise CMakeTimeout.new("cmake has exceeded its timeout of #{timeout}s")
end

MAKE = if Gem.win_platform?
  # On Windows, Ruby-DevKit only has 'make'.
  find_executable('make')
else
  find_executable('gmake') || find_executable('make')
end

if !MAKE
  abort "ERROR: GNU make is required to build epeg."
end

CWD = File.expand_path(File.dirname(__FILE__))
EPEG_DIR = File.join(CWD, 'epeg')

if !find_executable('cmake')
  abort "ERROR: CMake is required to build epeg."
end

Dir.chdir(EPEG_DIR) do
  Dir.mkdir("build") if !Dir.exist?("build")

  Dir.chdir("build") do
	# On Windows, Ruby-DevKit is MSYS-based, so ensure to use MSYS Makefiles.
	generator = "-G \"MSYS Makefiles\"" if Gem.win_platform?
	run_cmake(5 * 60, ".. #{cmake_flags.join(' ')} #{generator}")
	sys(MAKE)
  end
end

# Prepend the vendored epeg build dir to the $DEFLIBPATH.
$DEFLIBPATH.unshift("#{EPEG_DIR}/build")
dir_config('epeg', "#{EPEG_DIR}", "#{EPEG_DIR}/build")

unless have_library 'epeg' and have_header 'Epeg.h'
  abort "ERROR: Failed to build epeg"
end

create_makefile('epeg')
