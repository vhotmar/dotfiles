-- Auto-reload config on changes to any .lua file in this directory.
local function reloadConfig(files)
	local doReload = false
	for _, file in pairs(files) do
		if file:sub(-4) == ".lua" then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

configWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.config/hammerspoon/", reloadConfig):start()

local function tableLength(t)
	local n = 0
	for _ in pairs(t) do
		n = n + 1
	end
	return n
end

local sendEscape = false
local prevModifiers = {}

controlEscapeModifierTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(evt)
	local currModifiers = evt:getFlags()

	if currModifiers["ctrl"] and tableLength(currModifiers) == 1 and tableLength(prevModifiers) == 0 then
		-- Control just became the only active modifier: arm Escape.
		sendEscape = true
	elseif prevModifiers["ctrl"] and tableLength(currModifiers) == 0 and sendEscape then
		-- Control released in isolation: fire Escape.
		sendEscape = false
		hs.eventtap.keyStroke({}, "escape", 0)
	else
		sendEscape = false
	end

	prevModifiers = currModifiers
	return false
end)
controlEscapeModifierTap:start()

controlEscapeCancelTap = hs.eventtap.new({
	hs.eventtap.event.types.keyDown,
	hs.eventtap.event.types.leftMouseDown,
	hs.eventtap.event.types.rightMouseDown,
	hs.eventtap.event.types.otherMouseDown,
}, function(evt)
	sendEscape = false
	return false
end)
controlEscapeCancelTap:start()

hs.alert.show("Hammerspoon config loaded")

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)
