class Faktory < Formula
  desc "High-performance background job server"
  homepage "https://github.com/contribsys/faktory"
  url "https://github.com/contribsys/faktory/tarball/v1.6.0"
  sha256 "202422b285e60f46dee4ce3bcf0fafd8878dd399c0e335567422c0cb17219768"

  depends_on "redis"
  depends_on "go" => :build

  resource "ego" do
    url "https://github.com/benbjohnson/ego/archive/v0.4.1.tar.gz"
    sha256 "dbae6aa7f5286606e6a21ba81e09a2dfa63616d79edb23db79d07407701a7162"
  end

  def install
    go_bin_path = "#{buildpath}/bin"
    ENV["GOPATH"] = buildpath

    (buildpath/"src/github.com/contribsys/faktory").install buildpath.children

    mkdir go_bin_path
    ENV.prepend_path "PATH", go_bin_path

    resource("ego").stage do |stage|
      (buildpath/"src/github.com/benbjohnson/ego").install Pathname("#{stage.staging.tmpdir}/ego-0.4.1").children
      cd "#{buildpath}/src/github.com/benbjohnson/ego" do
        system "go", "build", "-o", "#{go_bin_path}/ego", "./cmd/ego"
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
