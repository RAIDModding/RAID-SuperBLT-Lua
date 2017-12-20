
class Logger {
	foreign static log(text)
}

class IO {
	foreign static listDirectory(path, dirs)
	foreign static info(path) // returns: none, file, dir
	foreign static read(path) // get file contents
	foreign static dynamic_import(path) // import a file dynamically
}

