class Faktory < Formula
  desc "High-performance background job server"
  homepage "https://github.com/contribsys/faktory"
  url "https://github.com/contribsys/faktory/tarball/v1.9.2"
  sha256 "1686828ed66207c842e3d64289a4e52c6e2ee70452028b864757304563b01ca4"

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

  service do
    run bin/"faktory"
    environment_variables PATH: "#{HOMEBREW_PREFIX}/sbin:/usr/sbin:/usr/bin:/bin:#{HOMEBREW_PREFIX}/bin"
  end

  test do
    shell_output("#{bin}/faktory -v", 0)
  end
end
