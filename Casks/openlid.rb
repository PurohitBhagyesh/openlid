cask "openlid" do
  version "1.0.0"
  sha256 "b6d4516709c9ccebace83360093be20c0b459e05b03e09ec0db8eb8cf5eb5cab"

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
