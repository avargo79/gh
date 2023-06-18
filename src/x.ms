import_code("/home/asmith/src/ui.src")
import_code("/home/asmith/src/io.src")
import_code("/home/asmith/src/wifi.src")
import_code("/home/asmith/src/net.src")
import_code("/home/asmith/src/hacks.src")

//////////////////////////////////////////////////////////////////////
//  Helper functions
//////////////////////////////////////////////////////////////////////
__isNumeric = function(val)
    locals.validCharacters = "1234567890"
    for c in val
        if locals.validCharacters.indexOf(c) == null then return false
    end for
    return true
end function

__isValidInput = function(input, options)
    if not input then return false
    if input.val > options.len then return false
    if input.val < 0 then return false

	return true
end function

__find = function(searchKeys, collection)
    if not collection or collection.len == 0 then return null

    results = []
    for item in collection
        found = []
        for search in searchKeys
            for pair in search
                // user_input("Search: " + pair.key +" = " + str(pair.value) + " item: " + str(item[pair.key]))
                if item.hasIndex(pair.key) and str(item[pair.key]) == str(pair.value) then
                    found.push(pair.key)
                end if
            end for
        end for 
        if found.len == searchKeys.len then results.push(item)
    end for

    return results
end function

//////////////////////////////////////////////////////////////////////
//  Main Menu
//////////////////////////////////////////////////////////////////////
mainMenu = function(_)
    menu.Title = "Main Menu"
    menu.Prompt = "-> "
    menu.InfoLines = []
    menu.MenuItems = []
    menu.refresh = @mainMenu

    menu.addMenuItem("1", "WiFi", @wifiMenu)
    menu.addMenuItem("2", "Net", @netMenu)
    menu.addMenuItem("3", "Hack", @__hackLocal)
    menu.addMenuItem(null, " ", @wifiMenu)
    menu.addMenuItem("x", "Exit", @__exit)
end function

__exit = function(_)
    exit()
end function

//////////////////////////////////////////////////////////////////////
//  WiFi Menu
//////////////////////////////////////////////////////////////////////
wifiMenu = function(_)
    menu.Title = "WiFi Menu"
    menu.Prompt = "WiFi -> "
    menu.InfoLines = []
    menu.MenuItems = []
    menu.refresh = @wifiMenu
    current = WIFI.current
    if current then menu.InfoLines.push(current.ESSID + " - " + current.BSSID)

    for network in WIFI.getNetworks()
        cachedInfo = wifiCache.search([{"ESSID": network.ESSID, "BSSID": network.BSSID}])
        if cachedInfo and cachedInfo.len == 1 then
            network.PASSWORD = cachedInfo[0].PASSWORD
        end if

        displayText = network.ESSID + " (" + network.PWR + "%)"
        if network.ESSID == current.ESSID and network.BSSID == current.BSSID then
            displayText = "<color=#4bde5c><u>" + displayText + "</u></color>"
        end if
        menu.addMenuItem(menu.MenuItems.len + 1, displayText, @__selectNetwork, network)
    end for
    menu.addMenuItem(menu.MenuItems.len + 1, "Crack All", @__crackAll)
    menu.addMenuItem(null, " ", @netMenu)
    menu.addMenuItem("x", "Back to Main Menu", @mainMenu)
end function

__wifiUpdateCache = function(network)
    if not network.PASSWORD then return

    cachedInfo = wifiCache.search([{"ESSID": network.ESSID, "BSSID": network.BSSID}])
    if not cachedInfo or cachedInfo.len == 0 then
        cacheData = [network.ESSID, network.BSSID, network.PASSWORD].join(" ")
        wifiCache.add(cacheData)
    end if
end function

__selectNetwork = function(network)
    if not network.PASSWORD then
        network = WIFI.crack(network)
        __wifiUpdateCache(network)
    end if
    if network.PASSWORD then 
        WIFI.connect(network)
        wait(.1)
    end if
end function

__crackAll = function(_)
    for network in WIFI.getNetworks()
        cachedInfo = wifiCache.search([{"ESSID": network.ESSID, "BSSID": network.BSSID}])
        if cachedInfo and cachedInfo.len == 1 then
            network.PASSWORD = cachedInfo[0].PASSWORD
        end if
        if network.PASSWORD then continue
        network = WIFI.crack(network)
        __wifiUpdateCache(network)
    end for
end function

//////////////////////////////////////////////////////////////////////
//  Net Menu
//////////////////////////////////////////////////////////////////////
netMenu = function(_)
    menu.Title = "Net Menu"
    menu.Prompt = "Net -> "
    menu.InfoLines = []
    menu.MenuItems = []
    menu.refresh = @netMenu

    if target and is_valid_ip(target) then
        menu.Title = menu.Title + " - " + target
        whoisData = whois(target).split("\n")
        for data in whoisData
            menu.InfoLines.push(data)
        end for

        ports = NET.scan(target)
        formattedTable = __getPortTable(ports)
        header = formattedTable.pull
        menu.addMenuItem(null, header)

        for line in formattedTable
            if not line or line.trim == "" then continue
            menu.addMenuItem(null, line, null)
        end for

        menu.addCommand("b_bank", @__getBankData)
        menu.addCommand("m_mail", @__getMailData)
        menu.addCommand("p_passwd", @__getPasswdData)
        menu.addCommand("f_file", @__getFileData)
        menu.addCommand("s_shell", @__getShells)
    end if
    
    menu.addMenuItem(null, " ", @netMenu)
    menu.addMenuItem("?", "Show help", @__showHelp)
    menu.addMenuItem("x", "Back to Main Menu", @mainMenu)
end function

__getPortTable = function(ports)
    tableData = "PORT STATUS SERVICE VERSION LAN\n"
    for port in ports
        displayText = [port.PORT, port.STATUS, port.SERVICE, port.VERSION, port.LAN].join(" ") + "\n"
        tableData = tableData + displayText + "\n"
    end for
    return format_columns(tableData).split("\n")
end function

__clearTarget = function(_)
    globals.target = null
end function

__getBankData = function(args)
    user_input("Called get bank data")
end function

__getMailData = function(args)
    user_input("Called get mail data")
end function

__getPasswdData = function(args)
    user_input("Called get passwd data")
end function

__getFileData = function(args)
    user_input("Called get all file data")
end function

__getShells = function(args)
    user_input("Called get shells")
end function

__showHelp = function(args)
    print("[b|bank] port")
    print("[m|mail] port")
    print("[p|passwd] port")
    print("[f|file] port")
    print("[s|shell] port")
    user_input("Press enter to continue...")
end function

//////////////////////////////////////////////////////////////////////
//  Hack
//////////////////////////////////////////////////////////////////////
__hackLocal = function(_)

    libFiles = HACKS.getLocalLibraries()
    for library in libFiles
        memCache = memoryCache.search([{"LIBRARY": library.lib_name, "VERSION": library.version}])
        if not memCache or memCache.len == 0 then
            print("Scanning: " + library.lib_name + " v" + library.version)
            for hack in HACKS.scanLocal(library)
                cacheData = [hack.LIBRARY, hack.VERSION, hack.ADDRESS, hack.VALUE, ""].join(" ")
                memoryCache.add(cacheData)
            end for

            memCache = memoryCache.search([{"LIBRARY": library.lib_name, "VERSION": library.version}])
        end if
        
        for exploit in memCache
            print("Attempting: " + exploit.ADDRESS + " " + exploit.VALUE)
            result = library.overflow(exploit.ADDRESS, exploit.VALUE, "password")
            if result and not exploit.TYPE then 
                if typeof(result) == "number" then result = "priv"
                record = [exploit.LIBRARY, exploit.VERSION, exploit.ADDRESS, exploit.VALUE, ""].join(" ")
                newRecord = [exploit.LIBRARY, exploit.VERSION, exploit.ADDRESS, exploit.VALUE, result].join(" ")
                memoryCache.update(record, newRecord)
            end if
            print("\n")
        end for
    end for
    user_input("Press enter to continue")
end function

//////////////////////////////////////////////////////////////////////
//  Program
//////////////////////////////////////////////////////////////////////
wifiCache = IO.Cache.create(home_dir + "/wifi.cache", "ESSID BSSID PASSWORD")
memoryCache = IO.Cache.create(home_dir + "/memory.cache", "LIBRARY VERSION ADDRESS VALUE TYPE")

metaxploit = IO.getLibrary("metaxploit.so")
if not metaxploit then return exit("Error: Could not find 'metaxploit.so'.")
crypto = IO.getLibrary("crypto.so")
if not crypto then return exit("Error: Could not find 'crypto.so'.")

menu = new UI.Menu

target = null
if params.len > 0 and is_valid_ip(params[0]) then target = params[0]

if target then
    netMenu()
else
    mainMenu()
end if

while true
    clear_screen
    menu.print()
    input = menu.prompt()

    // check for option
    opts = __find([{"Key": input}], menu.MenuItems)
    if opts and opts.len == 1 then
        opt = opts[0]
        opt.Fn(opt.Value)
    end if

    // check for commands
    inputs = input.split(" ")
    for cmd in menu.Commands
        cmdTexts = cmd.Text.split("_")
        if cmdTexts.indexOf(inputs[0]) != null then
            cmd.Fn(inputs[1:])
            break
        end if
    end for
end while