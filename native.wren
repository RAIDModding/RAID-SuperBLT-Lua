
class Logger {
	foreign static log(text)
}

class IO {
	foreign static listDirectory(path, dirs)
	foreign static info(path) // returns: none, file, dir
	foreign static read(path) // get file contents
	foreign static dynamic_import(path) // import a file dynamically
}

foreign class XML {
	construct new(text) {}
	foreign static try_parse(text) // Basically a fancy constructor

	foreign type
	foreign text
	foreign text=(val)
	foreign string
	foreign name
	foreign name=(val)
	foreign [name] // attribute
	foreign [name]=(val) // attribute
	foreign attribute_names

	foreign create_element(name)
	foreign delete()

	// Structure accessors
	foreign next
	foreign prev
	foreign parent
	foreign child
	foreign last_child
}
