__scanAddress = function(ipaddress, port)
	if not is_valid_ip(ipaddress) then return print("Error: Invalid IP address given.")
	
	metaxploit = IO.getLibrary()
	if not metaxploit then return print("Error: Could not find 'metaxploit.so'.")
	
	netsession = metaxploit.net_use(ipaddress, port)
	if not netsession then return print("Error: Cannot get net session.")
	
	library = netsession.dump_lib
	if not library then return print("Error: Cannot dump library.")

	results = []	
	memLocs = metaxploit.scan(library)
	for memLoc in memLocs
		addressData = metaxploit.scan_address(library, memLoc)
		strings = addressData.split("Unsafe check: ")
		for string in strings
			if string == strings[0] then continue
			
			value = string[string.indexOf("<b>")+3:string.indexOf("</b>")]
            results.push({"LIBRARY": library.lib_name, "VERSION": library.version, "MEMORY_ADDRESS": memLoc, "VALUE": value })
		end for
	end for

	return results
end function

__scanLibrary = function(library)
	metaxploit = IO.getLibrary()
	if not metaxploit then return print("Error: Could not find 'metaxploit.so'.")

	results = []	
	addresses = metaxploit.scan(library)
	for memLoc in addresses
		data = metaxploit.scan_address(library, memLoc)
		strings = data.split("Unsafe check: ")
		for string in strings
			if string == strings[0] then continue
		
			value = string[string.indexOf("<b>")+3:string.indexOf("</b>")]
			results.push({"LIBRARY": library.lib_name, "VERSION": library.version, "ADDRESS": memLoc, "VALUE": value, "TYPE": "" })
		end for
	end for

	return results
end function

__getLocalLibraries = function()
	metaxploit = IO.getLibrary()
	if not metaxploit then return print("Error: Could not find 'metaxploit.so'.")

	computer = __getComputer()
	folder = computer.File("/lib")
	if not folder.is_folder then return print("ERROR: /lib is not a folder")
	
	results = []
	for file in folder.get_files()
		fileExt = file.path[file.path.lastIndexOf("."):]
		if fileExt != ".so" then continue

		library = metaxploit.load(file.path)
		if not library then return print("Error: Cannot dump library.")
		results.push(library)
	end for

	return results
end function

HACKS = {}
HACKS.scanAddress = @__scanAddress
HACKS.scanLocal = @__scanLibrary
HACKS.getLocalLibraries = @__getLocalLibraries
