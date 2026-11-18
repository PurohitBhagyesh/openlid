cask "openlid" do
  version "1.0.0"
  sha256 "651858d0a5d100a24b1fd1154fbf9a33402029b09a3e7d1a5b3a6865c9289e8c"

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
