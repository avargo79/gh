//////////////////////////////////////////////////////////////////////
//  IO
//////////////////////////////////////////////////////////////////////
__getComputer = function(shell = null)
	if not shell then shell = get_shell
	return shell.host_computer
end function

__readFile = function(filePath, createIfNotExist = false)
	computer = __getComputer()
	
	if createIfNotExist and not filePath then 
		computer.touch(parent_path(filePath), fileName)
		filePath = parent_path(filePath) + "/" + fileName
	end if

	file = computer.File(filePath)
	rows = file.get_content.split(char(10))
	if rows.len == 0 then return null
	
	return rows
end function

__getFile = function(filePath)
	computer = __getComputer()
	return computer.File(filePath)
end function

__createFile = function(filePath)
	computer = __getComputer()
	
	if not __getFile(filePath) then 
		path = filePath[: filePath.lastIndexOf("/")]
    	fileName = filePath[filePath.lastIndexOf("/")+1:]
		computer.touch(path, fileName)
	end if

	return __getFile(filePath)
end function

__writeFile = function(filePath, data, append = false)
	computer = __getComputer()
	file = __createFile(filePath)
	
	if append then 
		newData = []
		fileData = file.get_content.split(char(10))
		fileData.push(data)
		for line in fileData
			if not line then continue
			newData.push(line)
		end for
		data = newData.join(char(10))
	end if

	file.set_content(data)
end function

__overwriteFile = function(filePath, data)
	computer = __getComputer()
	
	if computer.File(filePath) then computer.File(filePath).delete
	path = filePath[: filePath.lastIndexOf("/")]
	fileName = filePath[filePath.lastIndexOf("/")+1:]
	computer.touch(path, fileName)
	file = computer.File(filePath)
	file.set_content(data)
end function

__findFilePath = function(fileName)
	computer = __getComputer()
    searchPaths = [parent_path(program_path), home_dir, "/bin", "/lib"]

	result = null
	for searchPath in searchPaths
		files = computer.File(searchPath).get_files()
		for file in files
			if file.name != fileName then continue
			result = file.path
			break
		end for
        if result then break
	end for
	return result
end function

__getLibFiles = function()
	computer = __getComputer()
	folder = computer.File("/lib")
	if not folder.is_folder then return print("ERROR: /lib is not a folder")
	
	results = []
	for file in folder.get_files()
		fileExt = file.path[file.path.lastIndexOf("."):]
		if fileExt != ".so" then continue

		results.push(file.path)
	end for

	return results
end function

__getLibrary = function(libname = "metaxploit.so")
	libpaths = ["/lib/", parent_path(program_path) + "/"]
	lib = null
	for libpath in libpaths
		lib = include_lib(libpath + libname)
		if lib then
			break
		end if
	end for

	return lib
end function

//////////////////////////////////////////////////////////////////////
//  Cache
//////////////////////////////////////////////////////////////////////
__createCache = function(filePath, keys)
    if typeof(keys) != "string" then return "Usage: Cache.create([filePath], [keys])"
    if not IO.getFile(filePath) then IO.writeFile(filePath, keys)

    result = new IO.Cache
    result.path = filePath
    result.file = IO.getFile(filePath)

    return result
end function

__searchCache = function(searchKeys)
    if not self.file then return "Cache not yet created"
    results = []

    lines = IO.readFile(self.path)
    if not lines or lines.len < 1 then return print("File: '" + self.path + "' does not contain headers")

    headers = lines.pull.split(" ")
    lines = IO.readFile(self.path)
    if lines and lines.len < 2 then return results
    for line in lines
        fields = line.split(" ")
        obj = {}

        for header in headers
            index = headers.indexOf(header)
            obj[header] = fields[index]
        end for

        for key in searchKeys
            found = []
            for val in key
                if obj[val.key] == val.value then found.push(val.key)
            end for
            if found.len == key.len then results.push(obj)
        end for
    end for

    return results
end function

__addCache = function(value)
    if not self.file then return "Cache not yet created"

    IO.writeFile(self.path, value, true)
end function

__updateCache = function(oldValue, newValue)
    if not self.file then return "Cache not yet created"
	newContent = []
	content = IO.readFile(self.path)
	for line in content
		if line == oldValue then
			newContent.push(newValue)
		else
			newContent.push(line)
		end if
	end for
    IO.writeFile(self.path, newContent.join(char(10)))
end function

//////////////////////////////////////////////////////////////////////
//  Namespace setup
//////////////////////////////////////////////////////////////////////
IO = {}
IO.findFilePath = @__findFilePath
IO.readFile = @__readFile
IO.getFile = @__getFile
IO.writeFile = @__writeFile
IO.overwriteFile = @__overwriteFile
IO.createFile = @__createFile
IO.getLibrary = @__getLibrary
IO.getLibraryFiles = @__getLibFiles

IO.Cache = {}
IO.Cache.path = ""
IO.Cache.file = null
IO.Cache.create = @__createCache
IO.Cache.search = @__searchCache
IO.Cache.add = @__addCache
IO.Cache.update = @__updateCache