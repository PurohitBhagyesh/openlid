cask "openlid" do
  version "1.0.0"
  sha256 "03b26d5def2552b154b54272b2f3721ec52fe0e66c510376b0af1891f24c9304"

  url "https://openlid.devs.li/downloads/OpenLid-Universal.zip"
  name "OpenLid"
  desc "Keep your laptop running with the lid closed"
  homepage "https://openlid.devs.li/"

  livecheck do
    url "https://github.com/PurohitBhagyesh/openlid"
    strategy :github_latest
  end

  depends_on macos: :ventura

  app "OpenLid.app"
  binary "openlid"

  zap trash: [
    "~/.config/openlid",
    "~/Library/Preferences/li.devs.openlid.plist",
    "~/Library/Preferences/com.openlid.app.plist",
    "~/Library/Caches/li.devs.openlid",
    "/etc/sudoers.d/openlid",
  ]
end
