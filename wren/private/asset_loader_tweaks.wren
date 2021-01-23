// This import will cause an error on older versions of the DLL
import "base/native/DB_001" for DBManager, DBForeignFile
import "base/native/internal_001" for Internal
import "base/private/xml_loader" for Tweaker
import "base/native" for Logger, XML

// Disable the old tweaking system so we don't double-up on tweaks
Internal.tweaker_enabled = false

class TweakLoader {
	construct new(){}
	load_file(name, ext) {
		Logger.log("XML-Tweaking (DB) Bundle File %(name).%(ext)")

		var orig = DBManager.load_asset_contents("@" + name, "@" + ext)
		if (orig == null) {
			Fiber.abort("Failed to tweak file %(name).%(ext): original file could not be found!")
		}

		var xml = XML.new(orig)
		Tweaker.tweak_xml(name, ext, xml)
		var tweaked = xml.string
		xml.delete()

		return DBForeignFile.from_string(tweaked)
	}
}
var loader = TweakLoader.new()

for (tweak in Tweaker.tweaked_files) {
	var parts = tweak.split(".")
	var name = parts[0]
	var ext = parts[1]
	Logger.log("Register tweak: %(name).%(ext)")

	var hook = DBManager.register_asset_hook("@" + name, "@" + ext)
	hook.wren_loader = loader
}