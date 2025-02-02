class Skaffold < Formula
  desc "Easy and Repeatable Kubernetes Development"
  homepage "https://github.com/GoogleContainerTools/skaffold"
  url "https://github.com/GoogleContainerTools/skaffold.git",
      :tag      => "v1.9.0",
      :revision => "e5ae3f5520c8283155f9b5926da3d0da80b3f3af"
  head "https://github.com/GoogleContainerTools/skaffold.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "d89916168cae8ff74b3a3f61ba119f0d8ac770b5ad1a042737cd27f4083f760f" => :catalina
    sha256 "3e719cdfac383895e92415d030ba521cfcf343f318af838ae460610e2b893083" => :mojave
    sha256 "60b7b73885981a80ec38cfa1e6fb30d4c51faf9ddc222b280586c08c198d21cd" => :high_sierra
    sha256 "343cef7ee89f37e2552d7733e2bf7200555e634d00a29b9c60d26b4a87285560" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    dir = buildpath/"src/github.com/GoogleContainerTools/skaffold"
    dir.install buildpath.children - [buildpath/".brew_home"]
    cd dir do
      system "make"
      bin.install "out/skaffold"

      output = Utils.popen_read("#{bin}/skaffold completion bash")
      (bash_completion/"skaffold").write output

      output = Utils.popen_read("#{bin}/skaffold completion zsh")
      (zsh_completion/"_skaffold").write output

      prefix.install_metafiles
    end
  end

  test do
    output = shell_output("#{bin}/skaffold version --output {{.GitTreeState}}")
    assert_match "clean", output
  end
end
