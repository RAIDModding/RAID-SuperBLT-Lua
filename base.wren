import "base/native" for Logger, IO

var Tweakers = []

class BaseTweaker {
	static tweak(name, ext, text) {
		for (tweaker in Tweakers) {
			var result = tweaker.tweak(name, ext, text)
			if(result != null) text = result
		}
		//if(ext.startsWith("5438de")) Logger.log("Loading %(name).%(ext)")
		return text
	}
}

class TweakRegistry {
	static RegisterTweaker(tweaker) {
		Tweakers.add(tweaker)
	}
}

var ExecMods = []

{
	for (mod in IO.listDirectory("mods", true)) {
		if (IO.info("mods/%(mod)/tweaker.wren") == "file") {
			ExecMods.add(mod)
		}
	}

	for (mod in ExecMods) {
		Logger.log("Loading mod %(mod)")
		IO.dynamic_import("%(mod)/tweaker")
	}
}
