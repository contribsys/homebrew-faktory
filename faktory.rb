class Faktory < Formula
  desc "High-performance background job server"
  homepage "https://github.com/contribsys/faktory"
  url "https://github.com/contribsys/faktory/tarball/v1.4.0-1"
  sha256 "a6d2da95e4394330bd308305d4bd3fa974e9e0b3167c57cd39b58f6f74a704b9"

  depends_on "redis"
  depends_on "go" => :build

  resource "ego" do
    url "https://github.com/benbjohnson/ego/archive/v0.4.0.tar.gz"
    sha256 "4f4124af8e213b8af1954238a357216f5a2d7e433adc645a961bb8e18e8fa357"
  end

  resource "bindata" do
    url "https://github.com/go-bindata/go-bindata/archive/v3.1.3.tar.gz"
    sha256 "c9115e60995ecba15568c9f8052e77764f2b87b7b362cafd900cfc9829cba7e8"
  end

  def install
    go_bin_path = "#{buildpath}/bin"
    ENV["GOPATH"] = buildpath

    (buildpath/"src/github.com/contribsys/faktory").install buildpath.children

    mkdir go_bin_path
    ENV.prepend_path "PATH", go_bin_path

    resource("ego").stage do |stage|
      (buildpath/"src/github.com/benbjohnson/ego").install Pathname("#{stage.staging.tmpdir}/ego-0.4.0").children
      cd "#{buildpath}/src/github.com/benbjohnson/ego" do
        system "go", "build", "-o", "#{go_bin_path}/ego", "./cmd/ego"
      end
    end

    resource("bindata").stage do |stage|
      (buildpath/"src/github.com/go-bindata/go-bindata").install Pathname("#{stage.staging.tmpdir}/go-bindata-3.1.3").children
      cd "#{buildpath}/src/github.com/go-bindata/go-bindata" do
        system "go", "build", "-o", "#{go_bin_path}/go-bindata", "./go-bindata"
      end
    end

    cd "src/github.com/contribsys/faktory" do
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
