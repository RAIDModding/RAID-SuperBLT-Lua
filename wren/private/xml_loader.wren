import "base/native" for Logger, IO, XML
import "base/base" for TweakRegistry

class XMLTweakApplier {
	construct new() {
		_xml_tweaks = {}
	}
	add_tweak(name, ext, path) {
		var full = "%(name).%(ext)"
		if(_xml_tweaks[full] == null) _xml_tweaks[full] = []
		_xml_tweaks[full].add(path)
	}
	tweaks(name, ext) {
		var full = "%(name).%(ext)"
		return _xml_tweaks[full] != null
	}
	tweak_xml(name, ext, xml) {
		var full = "%(name).%(ext)"
		var tweaks = _xml_tweaks[full]
		for(path in tweaks) {
			apply_tweak(name, ext, xml, path)
		}
	}
	apply_tweak(name, ext, xml, tweak_path) {
		var tweaks = []
		XMLTweakApplier.find_tweaks(tweak_path, name, ext, tweaks)

		for(tweak in tweaks) {
			var search_node = null
			var target_node = null

			var elem = tweak.first_child
			while (elem != null) {
				var name = elem.name
				if(name == "search") {
					search_node = elem
				} else if(name == "target") {
					target_node = elem
				} else {
					Fiber.abort("Unknown element type in unknown tweak XML: %(name)")
				}
				elem = elem.next
			}

			if(search_node == null) Fiber.abort("Missing <search> node in unknown tweak XML")
			if(target_node == null) Fiber.abort("Missing <target> node in unknown tweak XML")

			var info = {"count": 0}
			dive_tweak_elem(xml, search_node, search_node.first_child, target_node, info)

			if(info["count"] == 0) {
				Logger.log("Warning: Failed to apply tweak in unknown XML for %(name).%(ext)")
			}
		}

		// Close all the tweaks
		for(tweak in tweaks) {
			tweak.delete()
		}
	}

	dive_tweak_elem(xml, root_search_node, search_node, target_node, info) {
		if(search_node == null) {
			Logger.log("found target, applying...")
			info["count"] = info["count"] + 1
			return root_search_node["multiple"] == "true"
		}

		var elem = xml
		while (elem != null) {
			if(elem.name == search_node.name) {
				var match = true
				for(name in search_node.attribute_names) {
					if(search_node[name] != elem[name]) {
						match = false
						break
					}
				}
				// TODO something with elem.attribute_names == search_node.attribute_names

				if(match) {
					var continue = dive_tweak_elem(elem.first_child, root_search_node, search_node.next, target_node, info)
					if(!continue) return false
				}
			}
			elem = elem.next
		}

		return true
	}

	static find_tweaks(path, name, ext, tweaks) {
		var data = IO.read(path)
		var xml = XML.new(data)
		var root = xml.first_child // <?xml?> -> <tweak/tweaks>
		var tweaked = false
		if(root.name == "tweaks") {
			var elem = root.first_child
			while (elem != null) {
				if(handle_tweak_element(name, ext, elem, tweaks)) tweaked = true
				elem = elem.next
			}
		} else if(root.name == "tweak") {
			if(handle_tweak_element(name, ext, root, tweaks)) tweaked = true
		} else {
			Fiber.abort("Unknown tweak root type in %(path): %(root.name)")
		}
		if(!tweaked) xml.delete()
	}

	static handle_tweak_element(name, ext, elem, tweaks) {
		if(name != handle_idstring(elem["name"])) return false
		if(ext != handle_idstring(elem["extension"])) return false

		tweaks.add(elem)
		return true
	}

	static handle_idstring(input) {
		if(input[0] == "#") {
			return input[1..16]
		} else {
			return IO.idstring_hash(input)
		}
	}
}

var ExecTodo = []
var Tweaker = XMLTweakApplier.new()

class XMLLoader {
	static init() {
		for (mod in IO.listDirectory("mods", true)) {
			var path = "mods/%(mod)/supermod.xml"
			if (IO.info(path) == "file") {
				var data = IO.read(path)
				var xml = XML.new(data)
				var elem = xml.first_child.first_child // <?xml?> -> <mod> -> first elem
				while (elem != null) {
					var name = elem.name
					if(name == "include") {
						// TODO include logic
					} else if(name == "wren") {
						handle_wren_tag(mod, elem)
					} else if(name == "tweak") {
						handle_tweak_file(mod, elem["definition"])
					} else {
						Fiber.abort("Unknown element type in %(path): %(name)")
					}
					elem = elem.next
				}
				xml.delete()
			}
		}

		for (file in ExecTodo) {
			Logger.log("Loading module %(file)")
			IO.dynamic_import(file)
		}
	}

	static handle_wren_tag(mod, tag) {
		var elem = tag.first_child
		while (elem != null) {
			var name = elem.name
			if(name == "base-path") {
				// TODO set base path
			} else if(name == "init") {
				ExecTodo.add(elem["file"])
			} else {
				Fiber.abort("Unknown element type in %(mod):<wren>: %(name)")
			}
			elem = elem.next
		}
	}

	static handle_tweak_file(mod, filename) {
		var path = "mods/%(mod)/%(filename)"
		var data = IO.read(path)
		var xml = XML.new(data)
		var root = xml.first_child // <?xml?> -> <tweak/tweaks>
		if(root.name == "tweaks") {
			var elem = root.first_child
			while (elem != null) {
				handle_tweak_element(mod, path, elem)
				elem = elem.next
			}
		} else if(root.name == "tweak") {
			handle_tweak_element(mod, path, root)
		} else {
			Fiber.abort("Unknown tweak root type in %(path): %(root.name)")
		}
		xml.delete()
	}

	static handle_tweak_element(mod, path, root) {
		var name = XMLTweakApplier.handle_idstring(root["name"])
		var extension = XMLTweakApplier.handle_idstring(root["extension"])
		Tweaker.add_tweak(name, extension, path)
	}
}

TweakRegistry.RegisterXMLTweaker(Tweaker)

XMLLoader.init()
