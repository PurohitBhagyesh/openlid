class Openlid < Formula
  desc "Keep your laptop running with the lid closed"
  homepage "https://openlid.devs.li/"
  url "https://github.com/PurohitBhagyesh/openlid/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "aed8c52965b6d8456fc296d195fd07252aac0c86d14c1bb39ffd0e0321fdba7e"
  license "MIT"
  head "https://github.com/PurohitBhagyesh/openlid.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/OpenLidCLI" => "openlid"
  end

  test do
    assert_match "OpenLid CLI", shell_output("#{bin}/openlid --help")
  end
end
