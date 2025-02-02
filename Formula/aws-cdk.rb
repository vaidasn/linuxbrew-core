require "language/node"

class AwsCdk < Formula
  desc "AWS Cloud Development Kit - framework for defining AWS infra as code"
  homepage "https://github.com/aws/aws-cdk"
  url "https://registry.npmjs.org/aws-cdk/-/aws-cdk-1.37.0.tgz"
  sha256 "a0051b664ca7ab0cc821ee4138036a1027a89bae3d2acabb844ec18c9d61882e"

  bottle do
    cellar :any_skip_relocation
    sha256 "8ecaece6b48f9eb2eb06aec0cad1880ee5e132af81def418e8a0ee29baa57e42" => :catalina
    sha256 "51207568ac19f589ae524082de4148b6ce30133684be119a3221645d5d105422" => :mojave
    sha256 "69647bb1c4126c5a775afd47607ab2d43b3d058e80dc29e8dc74b2cece2a4ca1" => :high_sierra
    sha256 "ad2941a9b9d6a2a97a58d926c4ca2f0f2ad246be15d47a059cf5f8c3168e38e8" => :x86_64_linux
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    mkdir "testapp"
    cd testpath/"testapp"
    shell_output("#{bin}/cdk init app --language=javascript")
    list = shell_output("#{bin}/cdk list")
    cdkversion = shell_output("#{bin}/cdk --version")
    assert_match "TestappStack", list
    assert_match version.to_s, cdkversion
  end
end
