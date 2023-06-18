//////////////////////////////////////////////////////////////////////
//  Helper functions
//////////////////////////////////////////////////////////////////////
// cacheFileName = "wifi.cache"

__current = function()
    computer = get_shell.host_computer
    router = get_router

    if router and computer.is_network_active and computer.active_net_card == "WIFI" then
        router = get_router 
        return { "ESSID": router.essid_name, "BSSID": router.bssid_name, "PWR": "", "PASSWORD": "" }
    end if

    return null
end function

__getNetworks = function()
    computer = get_shell.host_computer
	networks = []
	for network in computer.wifi_networks("wlan0")
		if not network then continue

		//BSSID PWR ESSID
		networkInfo = network.split(" ")
        networkPwr = (networkInfo[1] + "").remove("%")
        
		networks.push({"BSSID": networkInfo[0], "PWR": networkPwr.to_int, "ESSID": networkInfo[2], "PASSWORD": ""})
	end for
	networks.sort("PWR")
    networks.reverse
	
    return networks
end function

__connect = function(network)
    computer = get_shell.host_computer

    result = computer.connect_wifi("wlan0", network.BSSID, network.ESSID, network.PASSWORD)
    if typeof(result) == "string" then user_input("Failed connecting: " + result)
end function

__crack = function(network)
    computer = get_shell.host_computer
    
	// Use crypto
	crypt = IO.getLibrary("crypto.so")
	if not crypt then exit("crypto.so not found")

	// Crack wifi password.
    requestACKs = ceil(300000 / network.PWR) + 100
    print("Requesting " + requestACKs + " from " + network.ESSID)

	crypt.airmon("start", "wlan0")
	crypt.aireplay(network.BSSID, network.ESSID, requestACKs)
	crypt.airmon("stop", "wlan0")
	network.PASSWORD = crypt.aircrack(home_dir + "/file.cap")
    computer.File(home_dir + "/file.cap").delete

    return network
end function

//////////////////////////////////////////////////////////////////////
//  Namespace setup
//////////////////////////////////////////////////////////////////////
WIFI = {}
WIFI.current = @__current
WIFI.getNetworks = @__getNetworks
WIFI.connect = @__connect
WIFI.crack = @__crack
