cask "openlid" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/PurohitBhagyesh/openlid/releases/download/v#{version}/OpenLid-Universal.zip"
  name "OpenLid"
  desc "Keep your laptop running with the lid closed (macOS & Windows)"
  homepage "https://openlid.devs.li"

  depends_on macos: ">= :ventura"

  app "OpenLid.app"
  binary "openlid"

  zap trash: [
    "~/Library/Preferences/com.openlid.app.plist",
    "/etc/sudoers.d/openlid",
  ]
end

