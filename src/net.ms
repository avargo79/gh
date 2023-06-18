
__search = function(ports, searchKeys)
    if not ports or ports.len == 0 then return []

    // headers = []
    // item1 = ports[0]
    // for pair in item1
    //     for key in pair
    //         headers.push(key)
    //     end for
    // end for
    // user_input("Headers: " + headers)

    results = []
    for port in ports
        // for header in headers
        //     index = headers.indexOf(header)
        //     port[header] = fields[index]
        // end for

        for key in searchKeys
            found = []
            for val in key
                if port[val.key] == val.value then found.push(val.key)
            end for
            if found.len == key.len then results.push(port)
        end for
    end for

    return results
end function

__scan = function(ipAddress)
    isLanIp = is_lan_ip( ipAddress )
    router = get_router( ipAddress )

    if router == null then exit("nmap: ip address not found")
    ports = []

    if isLanIp then
        router_ip = router.local_ip
        for lan in router.devices_lan_ip
            ports = ports + router.device_ports(lan)
        end for
    else
        router_ip = router.public_ip
        for port in router.used_ports
            ports.push(port)
        end for
    end if

    results = []
    results.push({"PORT": 0, "STATUS": "open", "SERVICE": "router_kernel", "VERSION": router.kernel_version, "LAN": router_ip})
    for port in ports
        service_info = router.port_info(port)
        service = service_info.split(" ")[0]
        version = service_info.split(" ")[1]
        lan_ip = port.get_lan_ip
        port_status = "open"
        if(port.is_closed and not isLanIp) then
            port_status = "closed"
        end if

        res = {"PORT": port.port_number, "STATUS": port_status, "SERVICE": service, "VERSION": version, "LAN": lan_ip}
        if results.indexOf(res) == null then
            // user_input("Dupe: " + res)
            results.push(res)
        end if
        // f = __search(results, [{"PORT": port.port_number}, {"LAN": lan_ip}])
        // if not f or f.len == 0 then results.push({"PORT": port.port_number, "STATUS": port_status, "SERVICE": service, "VERSION": version, "LAN": lan_ip})
        // results.push(res)
    end for

   return results
end function

__getExploits = function(ipAddress, port = 0)
    metaxploit = IO.getLibrary("metaxploit.so")
    if not metaxploit then return null

    netsession = metaxploit.net_use(ipAddress, port)
    if not netsession then exit("Error: Cannot get net session.")

    library = netsession.dump_lib
    if not library then exit("Error: Cannot dump library.")

    print("Getting remote hacks: <color=#A50000><b>" + library.lib_name + ":" + library.version + "</b></color>")
    addresses = metaxploit.scan(library)

    exploits = []	
    for mem in addresses
        memInfo = metaxploit.scan_address(library, mem)
        strings = memInfo.split("Unsafe check: ")
        for string in strings
            if string == strings[0] then continue

            value = string[string.indexOf("<b>")+3:string.indexOf("</b>")]
            values = values + [value]
            exploit = {"LIB": library.lib_name, "VER": library.version, "MEM": mem, "VAL": value}

            exploits.push(exploit)
        end for
    end for

    return exploits
end function

NET = {}
NET.scan = @__scan
NET.getExploits = @__getExploits