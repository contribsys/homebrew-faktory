class Faktory < Formula
  VERSION = "0.9.3-1".freeze

  desc "High-performance background job server"
  homepage "https://github.com/contribsys/faktory"
  url "https://github.com/contribsys/faktory/archive/v#{VERSION}.tar.gz"
  # homebrew can't decipher version in the archive URL, need to manually specify
  version VERSION
  sha256 "68111333ee9e98d45f9e86307b6c8a05112e6519d8593d2afb047b6b97766aa5"

  depends_on "redis"
  depends_on "dep" => :build
  depends_on "go" => :build

  resource "ego" do
    url "https://github.com/benbjohnson/ego/archive/c779759b6d1ac35c9cdfa2681a92c1f6c893a98b.tar.gz"
    sha256 "784d37d39236d86abd3d9513485440b341ac35328982fb1f2cb22d9c30036bcb"
  end

  resource "bindata" do
    url "https://github.com/jteeuwen/go-bindata/archive/v3.0.7.tar.gz"
    sha256 "77a7214479e5ce9004e4afa6d0eb8ce14289030fadc55a3444249ab1fe2c7980"
  end

  def install
    go_bin_path = "#{buildpath}/bin"
    ENV["GOPATH"] = buildpath

    (buildpath/"src/github.com/contribsys/faktory").install buildpath.children

    mkdir go_bin_path
    ENV.prepend_path "PATH", go_bin_path

    resource("ego").stage do |stage|
      (buildpath/"src/github.com/benbjohnson/ego").install Pathname("#{stage.staging.tmpdir}/ego-c779759b6d1ac35c9cdfa2681a92c1f6c893a98b").children
      cd "#{buildpath}/src/github.com/benbjohnson/ego" do
        system "go", "build", "-o", "#{go_bin_path}/ego", "./cmd/ego"
      end
    end

    resource("bindata").stage do |stage|
      (buildpath/"src/github.com/jteeuwen/go-bindata").install Pathname("#{stage.staging.tmpdir}/go-bindata-3.0.7").children
      cd "#{buildpath}/src/github.com/jteeuwen/go-bindata" do
        system "go", "build", "-o", "#{go_bin_path}/go-bindata", "./go-bindata"
      end
    end

    cd "src/github.com/contribsys/faktory" do
      system "dep", "ensure"
      system "go", "generate", "github.com/contribsys/faktory/webui"
      system "go", "build", "-o", bin/"faktory", "./cmd/faktory/daemon.go"
      prefix.install_metafiles
    end
  end


  plist_options :manual => "faktory"

  def plist; <<~EOT
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>Program</key>
        <string>#{bin}/faktory</string>
        <key>RunAtLoad</key>
        <true/>
        <key>EnvironmentVariables</key>
        <dict>
          <key>PATH</key>
          <string>#{HOMEBREW_PREFIX}/sbin:/usr/sbin:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin</string>
        </dict>
      </dict>
    </plist>
    EOT
  end


  test do
    shell_output("#{bin}/faktory -v", 0)
  end
end
