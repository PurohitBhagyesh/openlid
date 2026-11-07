cask "openlid" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/PurohitBhagyesh/openlid/releases/download/v#{version}/OpenLid-Universal.dmg"
  name "OpenLid"
  desc "Keep your MacBook running with the lid closed without an external display"
  homepage "https://github.com/PurohitBhagyesh/openlid"

  depends_on macos: ">= :ventura"

  app "OpenLid.app"
  binary "#{appdir}/OpenLid.app/Contents/MacOS/OpenLid", target: "openlid"

  zap trash: [
    "~/Library/Preferences/com.openlid.app.plist",
    "/etc/sudoers.d/openlid",
  ]
end

