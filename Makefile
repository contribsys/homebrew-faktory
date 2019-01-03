# Example: make VER=0.9.4-1
default:
	@[ "${VER}" != "" ] || (echo "Need a version" && exit 127)
	@[ -f v$(VER) ] || curl -LO https://github.com/contribsys/faktory/tarball/v$(VER)
	@ruby -rerb -e 'version = "$(VER)"; sha = `shasum -a 256 -p v#{version}`.split[0].strip; puts ERB.new(File.read("faktory.erb")).result(binding)' > faktory.rb
