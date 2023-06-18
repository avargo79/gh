__line = "=========="*6

//////////////////////////////////////////////////////////////////////
//  Menu functions
//////////////////////////////////////////////////////////////////////
__createMenu = function(title)
    return new UI.Menu
end function

__printTitle = function()
    print(__line)
	print("==  " + self.Title);
	print(__line)
end function

__printInfo = function()
    if not self.InfoLines or self.InfoLines.len == 0 then return

    for info in self.InfoLines
        print("==  " + info)
    end for
    print(__line)
end function

__printMenuItems = function()
    if not self.MenuItems or self.MenuItems.len == 0 then return

    for menuItem in self.MenuItems
        if menuItem.Key then
            print("==  " + menuItem.Key + ": " + menuItem.Text)
        else
            print("==  " + menuItem.Text)
        end if
    end for
end function

__printFooter = function()
	print(__line)
end function

__print = function()
    self.refresh()
	self.__printTitle()
	self.__printInfo()
	self.__printMenuItems()
	self.__printFooter()
end function

__addMenuItem = function(key, text, callback, value = null)
    locals.option = new UI.MenuItem
    option.Key = key
    option.Text = text
    option.Value = value
    option.Fn = @callback

    self.MenuItems.push(option)
    return self.MenuItems.len
end function

__addCommand = function(cmds, callback)
    locals.command = new UI.Command
    command.Text = cmds
    command.Fn = @callback

    self.Commands.push(command)
    return self.Commands.len
end function

__prompt = function()
    return user_input(self.Prompt)
end function

__clear = function()
   self.InfoLines = []
   self.MenuItems = []
end function

//////////////////////////////////////////////////////////////////////
//  Namespace setup
//////////////////////////////////////////////////////////////////////
UI = {}

UI.Menu = { "Title": "Menu" }
UI.Menu.MenuItems = []
UI.Menu.InfoLines = []
UI.Menu.Commands = []
UI.Menu.Prompt = "-> "

UI.Menu.__printTitle = @__printTitle
UI.Menu.__printInfo = @__printInfo
UI.Menu.__printMenuItems = @__printMenuItems
UI.Menu.__printFooter = @__printFooter

UI.Menu.print = @__print
UI.Menu.clear = @__clear
UI.Menu.addMenuItem = @__addMenuItem
UI.Menu.addCommand = @__addCommand
UI.Menu.prompt = @__prompt
UI.Menu.refresh = null

UI.MenuItem = { }
UI.MenuItem.Key = null
UI.MenuItem.Text = ""
UI.MenuItem.Value = null
UI.MenuItem.Fn = null

UI.Command = { }
UI.Command.Text = ""
UI.Command.Fn = null