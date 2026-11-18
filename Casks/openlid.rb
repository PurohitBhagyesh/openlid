cask "openlid" do
  version "1.0.0"
  sha256 "bd0068a85cf4746b856ca0d10f5bce0e62fc0fdc03a7f2a15de522626415a508"

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
