import "base/native" for Logger, IO, XML

var Tweakers = []
var XMLTweakers = []

class BaseTweaker {
	static tweak(name, ext, text) {
		for (tweaker in Tweakers) {
			var result = tweaker.tweak_text(name, ext, text)
			if(result != null) text = result
		}
		var interestedTweakers = []
		for (tweaker in XMLTweakers) {
			if(tweaker.tweaks(name, ext)) {
				interestedTweakers.add(tweaker)
			}
		}
		if(interestedTweakers.count > 0) {
			Logger.log("XML-Tweaking Bundle File %(name).%(ext)")
			var xml = XML.new(text)
			for (tweaker in interestedTweakers) {
				tweaker.tweak_xml(name, ext, xml)
			}
			text = xml.string
			xml.delete()
		}
		return text
	}
}

class TweakRegistry {
	static RegisterTextTweaker(tweaker) {
		Tweakers.add(tweaker)
	}
	static RegisterTweaker(tweaker) {
		XMLTweakers.add(tweaker)
	}
}

var ExecMods = []

{
	for (mod in IO.listDirectory("mods", true)) {
		if (IO.info("mods/%(mod)/wren/init.wren") == "file") {
			ExecMods.add(mod)
		}
	}

	for (mod in ExecMods) {
		Logger.log("Loading mod %(mod)")
		IO.dynamic_import("%(mod)/init")
	}
}
