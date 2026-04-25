--!nocheck
--!nolint UnknownGlobal

local GetService = function(Name)
	return cloneref(game:GetService(Name))
end

local Get = function(URL)
	return request({ Url = URL, Method = "GET" }).Body
end

local RunService = GetService("RunService")
local InputService = GetService("UserInputService")
local ContextActionService = GetService("ContextActionService")
local HttpService = GetService("HttpService")
local TeleportService = GetService("TeleportService")
local Players = GetService("Players")
local CoreGui = GetService("CoreGui")

local StartUpArgs = getgenv().StartUpArgs or { "Private", "Public" }
local Drawing = loadstring(
	Get(
		"https://gist.githubusercontent.com/0f76/9dc85c8c380d895373dd306fd372fa59/raw/e2abc40c2b5f159d61b10558c86e4f98823e30f5/drawing_extension.lua"
	)
)()

local Tween = loadstring(
	Get(
		"https://gist.githubusercontent.com/0f76/1661258383c3c320ac5af2c9dd923fd5/raw/ee3c79b95eafa3b732127a0a7d37a4dc43b3bd60/custom_tween.lua"
	)
)()

local Handler = { Modules = {} }
do
	Handler.CreateModule = function(moduleName, data)
		local module = data or {}
		Handler.Modules[moduleName] = module
		return module
	end
end

local TotalUnnamedFlags = 0
local Utility = Handler.CreateModule("Utility")
do
	function Utility.TextLength(str, font, fontsize)
		local text = Drawing:new("Text")
		text.Text = str
		text.Font = font
		text.Size = fontsize

		local textbounds = text.TextBounds
		text:Remove()

		return textbounds
	end

	function Utility.SortSmaller(tbl, key)
		table.sort(tbl, function(a, b)
			return a[key] < b[key]
		end)
	end

	function Utility.SortLarger(tbl, key)
		table.sort(tbl, function(a, b)
			return a[key] > b[key]
		end)
	end

	function Utility.FindTriggers(text)
		local triggers = {
			["{hour}"] = os.date("%H"),
			["{minute}"] = os.date("%M"),
			["{second}"] = os.date("%S"),
			["{ap}"] = os.date("%p"),
			["{month}"] = os.date("%b"),
			["{day}"] = os.date("%d"),
			["{year}"] = os.date("%Y"),
			["{fps}"] = GetService("Stats").FrameRateManager:FindFirstChild("RenderAverage")
					and string.format("%.1f", 1000 / GetService("Stats").FrameRateManager.RenderAverage:GetValue()) .. " fps"
				or "nil fps",
			["{ping}"] = GetService("Stats") ~= nil and math.floor(
				GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
			) .. " ms" or "nil ms",
			["{game}"] = StartUpArgs[1],
			["{build}"] = StartUpArgs[2],
			["{uid}"] = game.Players.LocalPlayer.UserId or "nil",
			["{time}"] = os.date("%X", os.time()),
			["{date}"] = os.date("%b. %d, %Y"),
		}

		for a, b in next, triggers do
			text = string.gsub(text, a, b)
		end

		return text
	end
	function Utility.GetCenter(sizeX, sizeY)
		return UDim2.new(0.5, -(sizeX / 2), 0.5, -(sizeY / 2))
	end
	function Utility.Table(tbl, usemt)
		tbl = tbl or {}

		local oldtbl = table.clone(tbl)
		table.clear(tbl)

		for i, v in next, oldtbl do
			if type(i) == "string" then
				tbl[i:lower()] = v
			else
				tbl[i] = v
			end
		end

		if usemt == true then
			setmetatable(tbl, {
				__index = function(t, k)
					return rawget(t, k:lower()) or rawget(t, k)
				end,

				__newindex = function(t, k, v)
					if type(k) == "string" then
						rawset(t, k:lower(), v)
					else
						rawset(t, k, v)
					end
				end,
			})
		end

		return tbl
	end
	function Utility.TableToColor(tbl)
		return Color3.fromRGB(unpack(tbl))
	end
	function Utility.Round(number, float)
		if type(number) == "number" then
			return float * math.floor(number / float)
		end
		return 0
	end
	function Utility.ChangeColor(color, number)
		local r, g, b = color.R * 255, color.G * 255, color.B * 255
		r, g, b = math.clamp(r + number, 0, 255), math.clamp(g + number, 0, 255), math.clamp(b + number, 0, 255)
		return Color3.fromRGB(r, g, b)
	end
	function Utility.NextFlag()
		TotalUnnamedFlags = TotalUnnamedFlags + 1
		return string.format("%.14g", TotalUnnamedFlags)
	end
	function Utility.Rgba(r, g, b, alpha)
		local rgb = Color3.fromRGB(r, g, b)
		local mt = table.clone(getrawmetatable(rgb))

		setreadonly(mt, false)
		local old = mt.__index

		mt.__index = newcclosure(function(self, key)
			if key:lower() == "a" then
				return alpha
			end

			return old(self, key)
		end)

		setrawmetatable(rgb, mt)

		return rgb
	end
	function Utility.Lerp(delta, from, to)
		if delta > 1 then
			return to
		end
		if delta < 0 then
			return from
		end
		return from + (to - from) * delta
	end

	function Utility.NumberLerp(value, ranges)
		if value >= ranges[#ranges].start then
			return ranges[#ranges].number
		end

		local selected = #ranges
		for i = 1, #ranges - 1 do
			if value < ranges[i + 1].start then
				selected = i
				break
			end
		end
		local minnumb = ranges[selected]
		local maxnumb = ranges[selected + 1]
		local lerpValue = (value - minnumb.start) / (maxnumb.start - minnumb.start)
		return Utility.Lerp(lerpValue, minnumb.number, maxnumb.number)
	end
end

local Themes = {
	["Default"] = {
		["Accent"] = Color3.fromRGB(117, 163, 125),
		["Un-Selected"] = Color3.fromRGB(55, 55, 55),
		["Un-Selected_Text"] = Color3.fromRGB(118, 118, 118),
		["Text"] = Color3.fromRGB(175, 175, 175),
		["Risky Text"] = Color3.fromRGB(227, 206, 20),
		["Toggle Background"] = Color3.fromRGB(77, 77, 77),
		["Toggle Background Highlight"] = Color3.fromRGB(88, 88, 88),
	},
}
local ThemeObjects = {}
local Library = {
	Priorities = {},
	Friends = {},
	NotifList = { Ntifs = {}, Interval = 12 },
	Settings = { FolderName = "seere/" .. StartUpArgs[1], DefaultAccent = Color3.fromRGB(255, 255, 255) },
	Drawings = {},
	Theme = table.clone(Themes.Default),
	CurrentColor = nil,
	Flags = {},
	IsOpen = false,
	MouseState = InputService.MouseIconEnabled,
	Cursor = nil,
	Holder = nil,
	Connections = {},
	Notifications = {},
	Gradient = nil,
}
local Decode = (crypt and crypt.base64decode) or base64_decode
local Flags = {}
local ConfigIgnores = {}
--// local VisValues = {}
local Keys = {
	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.LeftControl] = "LC",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.CapsLock] = "CAPS",
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.KeypadOne] = "Num1",
	[Enum.KeyCode.KeypadTwo] = "Num2",
	[Enum.KeyCode.KeypadThree] = "Num3",
	[Enum.KeyCode.KeypadFour] = "Num4",
	[Enum.KeyCode.KeypadFive] = "Num5",
	[Enum.KeyCode.KeypadSix] = "Num6",
	[Enum.KeyCode.KeypadSeven] = "Num7",
	[Enum.KeyCode.KeypadEight] = "Num8",
	[Enum.KeyCode.KeypadNine] = "Num9",
	[Enum.KeyCode.KeypadZero] = "Num0",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.Tilde] = "~",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.RightParenthesis] = ")",
	[Enum.KeyCode.LeftParenthesis] = "(",
	[Enum.KeyCode.Semicolon] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.BackSlash] = "\\",
	[Enum.KeyCode.Comma] = ",",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Asterisk] = "*",
	[Enum.KeyCode.Plus] = "+",
	[Enum.KeyCode.Period] = ".",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
	[Enum.UserInputType.MouseWheel] = "WHEEL",
}
local FadeThings = {}

if not isfolder(Library.Settings.FolderName) then
	makefolder(Library.Settings.FolderName)
	makefolder(Library.Settings.FolderName .. "/configs")
	makefolder(Library.Settings.FolderName .. "/assets")
end

function Utility.Dragify(main, dragoutline, object)
	local start, objectposition, dragging, currentpos

	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			start = input.Position
			dragoutline.Visible = true
			objectposition = object.Position
		end
	end)

	InputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
			currentpos = UDim2.new(
				objectposition.X.Scale,
				objectposition.X.Offset + (input.Position - start).X,
				objectposition.Y.Scale,
				objectposition.Y.Offset + (input.Position - start).Y
			)
			dragoutline.Position = currentpos
		end
	end)

	InputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
			dragging = false
			dragoutline.Visible = false
			if Library.Flags["drag effect"] == "dynamic" then
				Tween.new(
					object,
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{ Position = currentpos }
				):Play()
			else
				object.Position = currentpos
			end
		end
	end)
end

local Images = {
	["gradient"] = Decode(
		"iVBORw0KGgoAAAANSUhEUgAAAfQAAAH0CAYAAADL1t+KAAAACXBIWXMAAAsTAAALEwEAmpwYAAAFr2lUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDIgNzkuMTY0MzYwLCAyMDIwLzAyLzEzLTAxOjA3OjIyICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdEV2dD0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlRXZlbnQjIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjEuMSAoV2luZG93cykiIHhtcDpDcmVhdGVEYXRlPSIyMDIxLTExLTAzVDE2OjA5OjA3WiIgeG1wOk1ldGFkYXRhRGF0ZT0iMjAyMS0xMS0wM1QxNjowOTowN1oiIHhtcDpNb2RpZnlEYXRlPSIyMDIxLTExLTAzVDE2OjA5OjA3WiIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDowZTY1NWJlYy1mZDM4LTM4NDMtOWI2NS04MjAxMzhlMDk1NzEiIHhtcE1NOkRvY3VtZW50SUQ9ImFkb2JlOmRvY2lkOnBob3Rvc2hvcDpiODczZmMzNi00ZmQ4LWI5NDAtYmI4Zi00ZTViYzNhY2RjZWIiIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0ieG1wLmRpZDpiOTUyZTJhMS04NDI3LTM2NDEtODg4YS00Njc3OGYzOTVjYjEiIGRjOmZvcm1hdD0iaW1hZ2UvcG5nIiBwaG90b3Nob3A6Q29sb3JNb2RlPSIzIj4gPHhtcE1NOkhpc3Rvcnk+IDxyZGY6U2VxPiA8cmRmOmxpIHN0RXZ0OmFjdGlvbj0iY3JlYXRlZCIgc3RFdnQ6aW5zdGFuY2VJRD0ieG1wLmlpZDpiOTUyZTJhMS04NDI3LTM2NDEtODg4YS00Njc3OGYzOTVjYjEiIHN0RXZ0OndoZW49IjIwMjEtMTEtMDNUMTY6MDk6MDdaIiBzdEV2dDpzb2Z0d2FyZUFnZW50PSJBZG9iZSBQaG90b3Nob3AgMjEuMSAoV2luZG93cykiLz4gPHJkZjpsaSBzdEV2dDphY3Rpb249InNhdmVkIiBzdEV2dDppbnN0YW5jZUlEPSJ4bXAuaWlkOjBlNjU1YmVjLWZkMzgtMzg0My05YjY1LTgyMDEzOGUwOTU3MSIgc3RFdnQ6d2hlbj0iMjAyMS0xMS0wM1QxNjowOTowN1oiIHN0RXZ0OnNvZnR3YXJlQWdlbnQ9IkFkb2JlIFBob3Rvc2hvcCAyMS4xIChXaW5kb3dzKSIgc3RFdnQ6Y2hhbmdlZD0iLyIvPiA8L3JkZjpTZXE+IDwveG1wTU06SGlzdG9yeT4gPC9yZGY6RGVzY3JpcHRpb24+IDwvcmRmOlJERj4gPC94OnhtcG1ldGE+IDw/eHBhY2tldCBlbmQ9InIiPz4I1RXvAAAIGElEQVR4nO3XsW0gMQADQb6h0Nd/uy5CgfCLmQqYLfhv2zcA4L/283oAAHBP0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASBA0AEgQNABIEDQASDgbPtejwAA7njoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABBwtn2vRwAAdzx0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAg4235fjwAA7njoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABBwtn2vRwAAdzx0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAg4277XIwCAOx46AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAScbd/rEQDAHQ8dAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAALOtt/XIwCAOx46AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAQIOgAECDoABAg6AAScbd/rEQDAHQ8dAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAAIEHQACBB0AAgQdAALOtu/1CADgjocOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAGCDgABgg4AAYIOAAF/LUoEerct0lkAAAAASUVORK5CYII="
	),
}

function Library:Outline(obj, color, zin, ignore)
	local outline = Drawing:new("Square")
	if not ignore then
		table.insert(Library.Drawings, outline)
	end
	outline.Parent = obj
	outline.Size = UDim2.new(1, 2, 1, 2)
	outline.Position = UDim2.new(0, -1, 0, -1)
	outline.ZIndex = zin or obj.ZIndex - 1

	if typeof(color) == "Color3" then
		outline.Color = color
	else
		outline.Color = Library.Theme[color]
		ThemeObjects[outline] = color
	end

	outline.Parent = obj
	outline.Filled = false
	outline.Thickness = 1

	return outline
end
function Library:Create(class, properties, ignore)
	local obj = Drawing:new(class)
	if not ignore then
		table.insert(Library.Drawings, obj)
	end
	for prop, v in next, properties do
		if prop == "Theme" then
			ThemeObjects[obj] = v
			obj.Color = Library.Theme[v]
		elseif obj then
			obj[prop] = v
		end
	end

	return obj
end
function Library:Connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Library.Connections, connection)

	return connection
end
function Library:Disconnect(connection)
	local index = table.find(Library.Connections, connection)
	connection:Disconnect()

	if index then
		table.remove(Library.Connections, index)
	end
end
function Library:Instance(a, b)
	local instance = Instance.new(a)
	if type(b) == "table" then
		for property, value in next, b do
			instance[property] = value
		end
	end
	return instance
end

local ScreenGui = Library:Instance("ScreenGui")
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = true
Library:Instance("ImageButton", {
	Parent = ScreenGui,
	Visible = true,
	Modal = true,
	Size = UDim2.new(1, 0, 1, 0),
	ZIndex = math.huge,
	Transparency = 1,
})

local Cursor1 = Library:Create("Quad", { Filled = true, Theme = "Accent", ZIndex = 1500 })
local Cursor2 = Library:Create("Quad", { Filled = true, Color = Color3.new(), ZIndex = 1499 })

Library:Connect(RunService.RenderStepped, function()
	if Cursor1.Visible then
		local pos = InputService:GetMouseLocation()
		Cursor1.PointA = pos + Vector2.new(0, 3)
		Cursor1.PointB = pos
		Cursor1.PointC = pos + Vector2.new(3, 0)
		Cursor1.PointD = pos + Vector2.new(3, 3)

		Cursor2.PointA = Cursor1.PointA + Vector2.new(1, 1)
		Cursor2.PointB = Cursor1.PointB + Vector2.new(1, 1)
		Cursor2.PointC = Cursor1.PointC + Vector2.new(1, 1)
		Cursor2.PointD = Cursor1.PointD + Vector2.new(1, 1)
	end
end)

function Library:set_open(bool)
	if typeof(bool) == "boolean" then
		--[=[
        for _,v in next, Library.Drawings do
            if v.Transparency ~= 0 then
                task.spawn(function()
                    if bool then
                        local fadein = Tween.new(v, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Transparency = VisValues[v]})
                        fadein:Play()
                    else
                        local fadeout = Tween.new(v, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Transparency = .05})
                        fadeout:Play()
                        VisValues[v] = v.Transparency;
                    end
                end)
            end
        end--]=]
		self.Open = bool
		ScreenGui.Enabled = bool
		self.Holder.Visible = bool
		Cursor1.Visible = bool
		Cursor2.Visible = bool
		local originalState = InputService.MouseIconEnabled
		if bool then
			ContextActionService:BindAction("Scrolling", function()
				return Enum.ContextActionResult.Sink
			end, false, Enum.UserInputType.MouseWheel)
			ContextActionService:BindAction("Input", function()
				return Enum.ContextActionResult.Sink
			end, false, Enum.UserInputType.MouseButton1)
			InputService.MouseIconEnabled = false
		else
			InputService.MouseIconEnabled = originalState
			ContextActionService:UnbindAction("Scrolling")
			ContextActionService:UnbindAction("Input")
		end
	end
end
function Library:ChangeObjectTheme(object, color)
	ThemeObjects[object] = color
	object.Color = Library.Theme[color]
end
function Library:ChangeThemeColor(option, color)
	self.Theme[option] = color

	for obj, theme in next, ThemeObjects do
		if rawget(obj, "exists") == true and theme == option then
			obj.Color = color
		end
	end
end
function Library:LoadConfig(cfg_name)
	if isfile(cfg_name) then
		local file = readfile(cfg_name)
		local config = HttpService:JSONDecode(file)

		for flag, v in next, config do
			local func = Flags[flag]
			if func then
				print(flag)
				func(v)
			end
		end
	end
end

local Pickers = {}
local Drops = {}
local InnerPickers = {}
local AllowedCharacters = {}
local ShiftCharacters = {
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["\\"] = "|",
	[";"] = ":",
	["'"] = '"',
	[","] = "<",
	["."] = ">",
	["/"] = "?",
	["`"] = "~",
}
for i = 32, 126 do
	table.insert(AllowedCharacters, utf8.char(i))
end
function Library.CreateDropdown(
	holder,
	content,
	flag,
	callback,
	default,
	max,
	scrollable,
	scrollingmax,
	section,
	sectioncontent
)
	local dropdown = Library:Create("Square", {
		Filled = true,
		Visible = true,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, -50, 0, 15),
		Position = UDim2.new(0, 23, 1, -17),
		ZIndex = 16,
		Parent = holder,
	})

	holder.MouseEnter:Connect(function()
		dropdown.Color = Color3.fromRGB(27, 27, 27)
	end)

	holder.MouseLeave:Connect(function()
		dropdown.Color = Color3.fromRGB(25, 25, 25)
	end)

	local outline1 = Library:Outline(dropdown, Color3.fromRGB(44, 44, 44), 14)
	Library:Outline(outline1, Color3.new(0, 0, 0), 14)

	local value = Library:Create("Text", {
		Text = "",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0, 2, 0, 0),
		Theme = "Text",
		ZIndex = 16,
		Outline = false,
		Parent = dropdown,
	})

	local icon = Library:Create("Text", {
		Text = "-",
		Transparency = 1,
		Visible = true,
		Parent = dropdown,
		Theme = "Text",
		ZIndex = 16,
		Position = UDim2.new(1, -13, 0, 0),
		Font = 2,
		Size = 13,
		Outline = true,
	})

	local contentframe = Library:Create("Square", {
		Filled = true,
		Visible = false,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 6),
		ZIndex = 18,
		Parent = dropdown,
	})

	table.insert(Drops, contentframe)

	local outline2 = Library:Outline(contentframe, Color3.fromRGB(44, 44, 44), 17)
	Library:Outline(outline2, Color3.new(0, 0, 0), 17)

	local contentholder = Library:Create("Square", {
		Transparency = 0,
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3),
		Parent = contentframe,
	})

	contentholder:AddListLayout(3)

	local mouseover = false
	local opened = false

	dropdown.MouseButton1Click:Connect(function()
		for i, v in next, Drops do
			if v ~= contentframe then
				v.Visible = false
			end
		end
		opened = not opened
		contentframe.Visible = opened
	end)

	local optioninstances = {}
	local count = 0
	local countindex = {}
	local startindex = 0

	local chosen = max and {}

	local function handleoptionclick(option, button, text)
		button.MouseButton1Click:Connect(function()
			for opt, tbl in next, optioninstances do
				if opt ~= option then
					Library:ChangeObjectTheme(tbl.text, "Text")
				end
			end

			chosen = option

			value.Text = option

			Library:ChangeObjectTheme(text, "Accent")

			Library.Flags[flag] = option
			callback(option)
		end)
	end

	local function createoptions(tbl)
		for _, option in next, tbl do
			optioninstances[option] = {}

			countindex[option] = count + 1

			local button = Library:Create("Square", {
				Filled = true,
				Transparency = 0,
				Thickness = 1,
				Theme = "Toggle Background",
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 19,
				Parent = contentholder,
			})

			optioninstances[option].button = button

			local title = Library:Create("Text", {
				Text = option,
				Font = Drawing.Fonts.Plex,
				Size = 13,
				Position = UDim2.new(0, 2, 0, 1),
				Theme = "Text",
				ZIndex = 19,
				Outline = true,
				Parent = button,
			})

			optioninstances[option].text = title

			if scrollable then
				if count < scrollingmax then
					contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
				end
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			count = count + 1
			handleoptionclick(option, button, title)
		end
	end

	createoptions(content)

	if scrollable then
		contentholder:MakeScrollable()
		local scroll_connect = nil

		local scrollbar_outline = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(1, -4, 0, 0),
			Parent = contentframe,
			ZIndex = 20,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(45, 45, 45),
			Filled = true,
		})

		local scrollbar = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 3, count == 0 and 1 or count / scrollingmax, 0),
			Position = UDim2.new(1, -3, 0, 0),
			Parent = contentframe,
			ZIndex = 21,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(65, 65, 65),
			Filled = true,
		})

		local function refreshscroll()
			local scale = startindex / (count > 0 and count or 1)
			scrollbar.Position = UDim2.new(1, -3, scale, 0)
			scrollbar.Size = UDim2.new(0, 3, math.clamp(count == 0 and 1 or 1 / (count / scrollingmax), 0, 1), 0)
		end

		contentholder.MouseEnter:Connect(function()
			scroll_connect = Library:Connect(InputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					local down = input.Position.Z < 0 and true or false
					if down then
						local indexesleft = count - scrollingmax - startindex
						if indexesleft >= 0 then
							startindex = math.clamp(startindex + 1, 0, count - scrollingmax)
							refreshscroll()
						end
					else
						local indexesleft = count - scrollingmax + startindex
						if indexesleft >= count - scrollingmax then
							startindex = math.clamp(startindex - 1, 0, count - scrollingmax)
							refreshscroll()
						end
					end
				end
			end)
		end)

		contentholder.MouseLeave:Connect(function()
			if scroll_connect then
				Library:Disconnect(scroll_connect)
			end
		end)

		refreshscroll()
	end

	local set
	set = function(option)
		for opt, tbl in next, optioninstances do
			if opt ~= option then
				Library:ChangeObjectTheme(tbl.text, "Text")
			end
		end

		if table.find(content, option) then
			chosen = option

			value.Text = option

			Library:ChangeObjectTheme(optioninstances[option].text, "Accent")

			Library.Flags[flag] = chosen
			callback(chosen)
		else
			chosen = nil

			value.Text = ""

			Library.Flags[flag] = chosen
			callback(chosen)
		end
	end

	Flags[flag] = set

	set(default)

	local dropdowntypes = Utility.Table({}, true)

	function dropdowntypes:set(option)
		set(option)
	end

	function dropdowntypes:refresh(tbl)
		content = table.clone(tbl)
		count = 0

		for _, opt in next, optioninstances do
			task.spawn(function()
				opt.button:Remove()
			end)
		end

		table.clear(optioninstances)

		createoptions(tbl)

		if scrollable then
			contentholder:RefreshScrolling()
		end

		value.Text = ""

		if max then
			table.clear(chosen)
		else
			chosen = nil
		end

		Library.Flags[flag] = chosen
		callback(chosen)
	end

	function dropdowntypes:add(option)
		table.insert(content, option)
		local button, text = createoption(option)
		handleoptionclick(option, button, text)
	end

	function dropdowntypes:remove(option)
		if optioninstances[option] then
			count = count - 1

			optioninstances[option].button:Remove()

			if scrollable then
				contentframe.Size = UDim2.new(
					1,
					0,
					0,
					math.clamp(contentholder.AbsoluteContentSize, 0, (scrollingmax * 16) + ((scrollingmax - 1) * 3)) + 6
				)
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			optioninstances[option] = nil

			if max then
				if table.find(chosen, option) then
					table.remove(chosen, table.find(chosen, option))

					local textchosen = {}
					local cutobject = false

					for _, opt in next, chosen do
						table.insert(textchosen, opt)

						if
							Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
							> (dropdown.AbsoluteSize.X - 6)
						then
							cutobject = true
							table.remove(textchosen, #textchosen)
						end
					end

					value.Text = #chosen == 0 and "" or table.concat(textchosen, ", ") .. (cutobject and ", ..." or "")

					Library.Flags[flag] = chosen
					callback(chosen)
				end
			end
		end
	end

	return dropdowntypes
end

function Library.CreateList(
	holder,
	content,
	flag,
	callback,
	default,
	max,
	scrollable,
	scrollingmax,
	section,
	sectioncontent
)
	scrollable = true

	local list = Library:Create("Square", {
		Filled = true,
		Visible = true,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, -50, 0, 15),
		Position = UDim2.new(0, 23, 0, 0),
		ZIndex = 16,
		Transparency = 0,
		Parent = holder,
	})

	local contentframe = Library:Create("Square", {
		Filled = true,
		Visible = true,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = 18,
		Parent = list,
	})

	local outline2 = Library:Outline(contentframe, Color3.fromRGB(44, 44, 44), 17)
	Library:Outline(outline2, Color3.new(0, 0, 0), 17)

	local contentholder = Library:Create("Square", {
		Transparency = 0,
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3),
		Parent = contentframe,
	})

	contentholder:AddListLayout(3)

	local mouseover = false
	local optioninstances = {}
	local count = 0
	local countindex = {}
	local startindex = 0

	local chosen = max and {}

	local function handleoptionclick(option, button, text)
		button.MouseButton1Click:Connect(function()
			for opt, tbl in next, optioninstances do
				if opt ~= option then
					Library:ChangeObjectTheme(tbl.text, "Text")
				end
			end

			chosen = option

			Library:ChangeObjectTheme(text, "Accent")

			Library.Flags[flag] = option
			callback(option)
		end)
	end

	local function createoptions(tbl)
		for _, option in next, tbl do
			optioninstances[option] = {}

			countindex[option] = count + 1

			local button = Library:Create("Square", {
				Filled = true,
				Transparency = 0,
				Thickness = 1,
				Theme = "Toggle Background",
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 19,
				Parent = contentholder,
			})

			optioninstances[option].button = button

			local title = Library:Create("Text", {
				Text = option,
				Font = Drawing.Fonts.Plex,
				Size = 13,
				Position = UDim2.new(0, 2, 0, 1),
				Theme = "Text",
				ZIndex = 19,
				Outline = true,
				Parent = button,
			})

			optioninstances[option].text = title

			if scrollable then
				if count < scrollingmax then
					contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
				end
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			count = count + 1
			handleoptionclick(option, button, title)
		end
	end

	createoptions(content)

	if scrollable then
		contentholder:MakeScrollable()
		local scroll_connect = nil

		local scrollbar_outline = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(1, -4, 0, 0),
			Parent = contentframe,
			ZIndex = 20,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(45, 45, 45),
			Filled = true,
		})

		local scrollbar = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 3, count == 0 and 1 or count / scrollingmax, 0),
			Position = UDim2.new(1, -3, 0, 0),
			Parent = contentframe,
			ZIndex = 21,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(65, 65, 65),
			Filled = true,
		})

		local function refreshscroll()
			local scale = startindex / (count > 0 and count or 1)
			scrollbar.Position = UDim2.new(1, -3, scale, 0)
			scrollbar.Size = UDim2.new(0, 3, math.clamp(count == 0 and 1 or 1 / (count / scrollingmax), 0, 1), 0)
		end

		contentholder.MouseEnter:Connect(function()
			scroll_connect = Library:Connect(InputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					local down = input.Position.Z < 0 and true or false
					if down then
						local indexesleft = count - scrollingmax - startindex
						if indexesleft >= 0 then
							startindex = math.clamp(startindex + 1, 0, count - scrollingmax)
							refreshscroll()
						end
					else
						local indexesleft = count - scrollingmax + startindex
						if indexesleft >= count - scrollingmax then
							startindex = math.clamp(startindex - 1, 0, count - scrollingmax)
							refreshscroll()
						end
					end
				end
			end)
		end)

		contentholder.MouseLeave:Connect(function()
			if scroll_connect then
				Library:Disconnect(scroll_connect)
			end
		end)
		refreshscroll()
	end

	local set
	set = function(option)
		for opt, tbl in next, optioninstances do
			if opt ~= option then
				Library:ChangeObjectTheme(tbl.text, "Text")
			end
		end

		if table.find(content, option) then
			chosen = option

			Library:ChangeObjectTheme(optioninstances[option].text, "Accent")

			Library.Flags[flag] = chosen
			callback(chosen)
		else
			chosen = nil

			Library.Flags[flag] = chosen
			callback(chosen)
		end
	end

	Flags[flag] = set

	set(default)

	local listtypes = Utility.Table({}, true)

	function listtypes:set(option)
		set(option)
	end

	function listtypes:refresh(tbl)
		content = table.clone(tbl)
		count = 0

		for _, opt in next, optioninstances do
			task.spawn(function()
				opt.button:Remove()
			end)
		end

		table.clear(optioninstances)

		createoptions(tbl)

		if scrollable then
			contentholder:RefreshScrolling()
		end

		if max then
			table.clear(chosen)
		else
			chosen = nil
		end

		Library.Flags[flag] = chosen
		callback(chosen)
	end

	function listtypes:add(option)
		table.insert(content, option)
		local button, text = createoption(option)
		handleoptionclick(option, button, text)
	end

	function listtypes:remove(option)
		if optioninstances[option] then
			count = count - 1

			optioninstances[option].button:Remove()

			if scrollable then
				contentframe.Size = UDim2.new(
					1,
					0,
					0,
					math.clamp(contentholder.AbsoluteContentSize, 0, (scrollingmax * 16) + ((scrollingmax - 1) * 3)) + 6
				)
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			optioninstances[option] = nil

			if max then
				if table.find(chosen, option) then
					table.remove(chosen, table.find(chosen, option))

					local textchosen = {}
					local cutobject = false

					for _, opt in next, chosen do
						table.insert(textchosen, opt)

						if
							Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
							> (list.AbsoluteSize.X - 6)
						then
							cutobject = true
							table.remove(textchosen, #textchosen)
						end
					end

					Library.Flags[flag] = chosen
					callback(chosen)
				end
			end
		end
	end

	holder.Size = contentframe.Size

	return listtypes
end

function Library.CreateSlider(cfg)
	local slider = {}
	local name = cfg.name or cfg.Name or nil
	local min = cfg.min or cfg.minimum or 0
	local max = cfg.max or cfg.maximum or 100
	local suffix = cfg.suffix or cfg.Suffix or ""
	local text = cfg.text or ("[value]" .. suffix)
	local float = cfg.float or 1
	local default = cfg.default and math.clamp(cfg.default, min, max) or min

	local flag = cfg.flag or Utility.NextFlag()
	local callback = cfg.callback or function() end
	local lol = cfg.parent or cfg.Parent or nil

	local holder = Library:Create("Square", {
		Parent = lol,
		Visible = true,
		Transparency = 0,
		Size = name and UDim2.new(1, 0, 0, 22) or UDim2.new(1, 0, 0, 12),
		Thickness = 1,
		Filled = true,
		ZIndex = 30,
	})

	local slider_frame = Library:Create("Square", {
		Parent = holder,
		Visible = true,
		Transparency = 1,
		Theme = "Toggle Background",
		Size = UDim2.new(1, -50, 0, 6),
		Thickness = 1,
		Filled = true,
		ZIndex = 30,
		Position = name and UDim2.new(0, 23, 0, 14) or UDim2.new(0, 23, 0, 3),
	})
	do
		local outline = Library:Outline(slider_frame, Color3.fromRGB(0, 0, 0), 30)
	end
	Library:Create("Image", {
		Data = Images.gradient,
		Transparency = 1,
		Visible = true,
		Parent = slider_frame,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 31,
	})

	if name then
		local slider_title = Library:Create("Text", {
			Text = name,
			Parent = holder,
			Visible = true,
			Transparency = 1,
			Theme = "Text",
			Size = 13,
			Center = false,
			Outline = false,
			Font = Drawing.Fonts.Plex,
			Position = UDim2.new(0, 20, 0, -2),
			ZIndex = 30,
		})
	end

	local slider_fill = Library:Create("Square", {
		Parent = slider_frame,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = UDim2.new(1, 0, 1, 0),
		Thickness = 1,
		Filled = true,
		ZIndex = 30,
		Position = UDim2.new(0, 0, 0, 0),
	})

	local slider_value = Library:Create("Text", {
		Text = text,
		Parent = slider_fill,
		Visible = true,
		Transparency = 1,
		Theme = "Text",
		Size = 13,
		Center = true,
		Outline = true,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(1, 0, 0.5, -2),
		ZIndex = 31,
	})

	local slider_drag = Library:Create("Square", {
		Parent = slider_frame,
		Visible = true,
		Transparency = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Thickness = 1,
		Filled = true,
		ZIndex = 30,
		Position = UDim2.new(0, 0, 0, 0),
	})

	local function set(value)
		value = math.clamp(Utility.round(value, float), min, max)

		slider_value.Text = text:gsub("%[value%]", string.format("%.14g", value))

		local sizeX = ((value - min) / (max - min))
		slider_fill.Size = UDim2.new(sizeX, 0, 1, 0)

		Library.Flags[flag] = value
		callback(value)
	end

	Flags[flag] = set
	set(default)

	local sliding = false

	local function slide(input)
		local sizeX = (input.Position.X - slider_frame.AbsolutePosition.X) / slider_frame.AbsoluteSize.X
		local value = ((max - min) * sizeX) + min

		set(value)
	end

	holder.MouseEnter:Connect(function()
		Library:ChangeObjectTheme(slider_frame, "Toggle Background Highlight")
	end)

	holder.MouseLeave:Connect(function()
		Library:ChangeObjectTheme(slider_frame, "Toggle Background")
	end)

	Library:Connect(slider_drag.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			slide(input)
		end
	end)

	Library:Connect(slider_drag.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)

	Library:Connect(slider_fill.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = true
			slide(input)
		end
	end)

	Library:Connect(slider_fill.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			sliding = false
		end
	end)

	Library:Connect(InputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if sliding then
				slide(input)
			end
		end
	end)

	function slider:set(value)
		set(value)
	end

	return slider
end

function Library.CreateMultibox(
	holder,
	content,
	flag,
	callback,
	default,
	max,
	scrollable,
	scrollingmax,
	section,
	sectioncontent
)
	local dropdown = Library:Create("Square", {
		Filled = true,
		Visible = true,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, -50, 0, 15),
		Position = UDim2.new(0, 23, 1, -17),
		ZIndex = 16,
		Parent = holder,
	})

	holder.MouseEnter:Connect(function()
		dropdown.Color = Color3.fromRGB(27, 27, 27)
	end)

	holder.MouseLeave:Connect(function()
		dropdown.Color = Color3.fromRGB(25, 25, 25)
	end)

	local outline1 = Library:Outline(dropdown, Color3.fromRGB(44, 44, 44), 14)
	Library:Outline(outline1, Color3.new(0, 0, 0), 14)

	local value = Library:Create("Text", {
		Text = "",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0, 2, 0, 0),
		Theme = "Text",
		ZIndex = 16,
		Outline = false,
		Parent = dropdown,
	})

	local icon = Library:Create("Text", {
		Text = "-",
		Transparency = 1,
		Visible = true,
		Parent = dropdown,
		Theme = "Text",
		ZIndex = 16,
		Position = UDim2.new(1, -13, 0, 0),
		Font = 2,
		Size = 13,
		Outline = true,
	})

	local contentframe = Library:Create("Square", {
		Filled = true,
		Visible = false,
		Thickness = 0,
		Color = Color3.fromRGB(25, 25, 25),
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 6),
		ZIndex = 18,
		Parent = dropdown,
	})

	table.insert(Drops, contentframe)

	local outline2 = Library:Outline(contentframe, Color3.fromRGB(44, 44, 44), 17)
	Library:Outline(outline2, Color3.new(0, 0, 0), 17)

	local contentholder = Library:Create("Square", {
		Transparency = 0,
		Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3),
		Parent = contentframe,
	})

	contentholder:AddListLayout(3)

	local mouseover = false

	local opened = false
	dropdown.MouseButton1Click:Connect(function()
		for i, v in next, Drops do
			if v ~= contentframe then
				v.Visible = false
			end
		end
		opened = not opened
		contentframe.Visible = opened
	end)

	local optioninstances = {}
	local count = 0
	local countindex = {}
	local startindex = 0

	local chosen = max and {}

	local function handleoptionclick(option, button, text)
		button.MouseButton1Click:Connect(function()
			if max then
				if table.find(chosen, option) then
					table.remove(chosen, table.find(chosen, option))

					local textchosen = {}
					local cutobject = false

					for _, opt in next, chosen do
						table.insert(textchosen, opt)

						if
							Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
							> (dropdown.AbsoluteSize.X - 18)
						then
							cutobject = true
							table.remove(textchosen, #textchosen)
						end
					end

					value.Text = #chosen == 0 and "none"
						or table.concat(textchosen, ", ") .. (cutobject and ", ..." or "")

					Library:ChangeObjectTheme(text, "Text")

					Library.Flags[flag] = chosen
					callback(chosen)
				else
					if #chosen == max then
						Library:ChangeObjectTheme(optioninstances[chosen[1]].text, "Text")

						table.remove(chosen, 1)
					end

					table.insert(chosen, option)

					local textchosen = {}
					local cutobject = false

					for _, opt in next, chosen do
						table.insert(textchosen, opt)

						if
							Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
							> (dropdown.AbsoluteSize.X - 18)
						then
							cutobject = true
							table.remove(textchosen, #textchosen)
						end
					end

					value.Text = #chosen == 0 and "none"
						or table.concat(textchosen, ", ") .. (cutobject and ", ..." or "")

					Library:ChangeObjectTheme(text, "Accent")

					Library.Flags[flag] = chosen
					callback(chosen)
				end
			end
		end)
	end

	local function createoptions(tbl)
		for _, option in next, tbl do
			optioninstances[option] = {}

			countindex[option] = count + 1

			local button = Library:Create("Square", {
				Filled = true,
				Transparency = 0,
				Thickness = 1,
				Theme = "Toggle Background",
				Size = UDim2.new(1, 0, 0, 16),
				ZIndex = 19,
				Parent = contentholder,
			})

			optioninstances[option].button = button

			local title = Library:Create("Text", {
				Text = option,
				Font = Drawing.Fonts.Plex,
				Size = 13,
				Position = UDim2.new(0, 2, 0, 1),
				Theme = "Text",
				ZIndex = 19,
				Outline = true,
				Parent = button,
			})

			optioninstances[option].text = title

			if scrollable then
				if count < scrollingmax then
					contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
				end
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			count = count + 1
			handleoptionclick(option, button, title)
		end
	end

	createoptions(content)

	if scrollable then
		contentholder:MakeScrollable()
		local scroll_connect = nil

		local scrollbar_outline = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(1, -4, 0, 0),
			Parent = contentframe,
			ZIndex = 20,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(45, 45, 45),
			Filled = true,
		})

		local scrollbar = Library:Create("Square", {
			Transparency = 1,
			Size = UDim2.new(0, 3, count == 0 and 1 or count / scrollingmax, 0),
			Position = UDim2.new(1, -3, 0, 0),
			Parent = contentframe,
			ZIndex = 21,
			Parent = contentframe,
			Thickness = 1,
			Color = Color3.fromRGB(65, 65, 65),
			Filled = true,
		})

		local function refreshscroll()
			local scale = startindex / (count > 0 and count or 1)
			scrollbar.Position = UDim2.new(1, -3, scale, 0)
			scrollbar.Size = UDim2.new(0, 3, math.clamp(count == 0 and 1 or 1 / (count / scrollingmax), 0, 1), 0)
		end

		contentholder.MouseEnter:Connect(function()
			scroll_connect = Library:Connect(InputService.InputChanged, function(input)
				if input.UserInputType == Enum.UserInputType.MouseWheel then
					local down = input.Position.Z < 0 and true or false
					if down then
						local indexesleft = count - scrollingmax - startindex
						if indexesleft >= 0 then
							startindex = math.clamp(startindex + 1, 0, count - scrollingmax)
							refreshscroll()
						end
					else
						local indexesleft = count - scrollingmax + startindex
						if indexesleft >= count - scrollingmax then
							startindex = math.clamp(startindex - 1, 0, count - scrollingmax)
							refreshscroll()
						end
					end
				end
			end)
		end)

		contentholder.MouseLeave:Connect(function()
			if scroll_connect then
				Library:Disconnect(scroll_connect)
			end
		end)
		refreshscroll()
	end

	local set
	set = function(option)
		if max then
			option = type(option) == "table" and option or {}
			table.clear(chosen)

			for opt, tbl in next, optioninstances do
				if not table.find(option, opt) then
					Library:ChangeObjectTheme(tbl.text, "Text")
				end
			end

			for i, opt in next, option do
				if table.find(content, opt) and #chosen < max then
					table.insert(chosen, opt)

					Library:ChangeObjectTheme(optioninstances[opt].text, "Accent")
				end
			end

			local textchosen = {}
			local cutobject = false

			for _, opt in next, chosen do
				table.insert(textchosen, opt)

				if
					Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
					> (dropdown.AbsoluteSize.X - 6)
				then
					cutobject = true
					table.remove(textchosen, #textchosen)
				end
			end

			value.Text = #chosen == 0 and "none" or table.concat(textchosen, ", ") .. (cutobject and ", ..." or "")

			Library.Flags[flag] = chosen
			callback(chosen)
		end
	end

	Flags[flag] = set

	set(default)

	local dropdowntypes = Utility.Table({}, true)

	function dropdowntypes:set(option)
		set(option)
	end

	function dropdowntypes:refresh(tbl)
		content = table.clone(tbl)
		count = 0

		for _, opt in next, optioninstances do
			task.spawn(function()
				opt.button:Remove()
			end)
		end

		table.clear(optioninstances)

		createoptions(tbl)

		if scrollable then
			contentholder:RefreshScrolling()
			refreshscroll()
		end

		value.Text = "none"

		if max then
			table.clear(chosen)
		else
			chosen = nil
		end

		Library.Flags[flag] = chosen
		callback(chosen)
	end

	function dropdowntypes:add(option)
		table.insert(content, option)
		local button, text = createoption(option)
		handleoptionclick(option, button, text)
	end

	function dropdowntypes:remove(option)
		if optioninstances[option] then
			count = count - 1

			optioninstances[option].button:Remove()

			if scrollable then
				contentframe.Size = UDim2.new(
					1,
					0,
					0,
					math.clamp(contentholder.AbsoluteContentSize, 0, (scrollingmax * 16) + ((scrollingmax - 1) * 3)) + 6
				)
			else
				contentframe.Size = UDim2.new(1, 0, 0, contentholder.AbsoluteContentSize + 6)
			end

			optioninstances[option] = nil

			if max then
				if table.find(chosen, option) then
					table.remove(chosen, table.find(chosen, option))

					local textchosen = {}
					local cutobject = false

					for _, opt in next, chosen do
						table.insert(textchosen, opt)

						if
							Utility.TextLength(table.concat(textchosen, ", ") .. ", ...", Drawing.Fonts.Plex, 13).X
							> (dropdown.AbsoluteSize.X - 6)
						then
							cutobject = true
							table.remove(textchosen, #textchosen)
						end
					end

					value.Text = #chosen == 0 and "none"
						or table.concat(textchosen, ", ") .. (cutobject and ", ..." or "")

					Library.Flags[flag] = chosen
					callback(chosen)
				end
			end
		end
	end

	return dropdowntypes
end

function Library.ObjectColorPickerInner(default, defaultalpha, parent, count, flag, callback, offset)
	local icon = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Color = default,
		Parent = parent,
		Transparency = 1,
		Size = UDim2.new(0, 17, 0, 9),
		Position = UDim2.new(1, -44 - (count * 17) - (count * 6), 0, 4 + offset),
		ZIndex = 30,
	})

	local outline = Library:Outline(icon, Color3.fromRGB(0, 0, 0))

	local gradient = Library:Create("Image", {
		Data = Images.gradient,
		Transparency = 1,
		Visible = true,
		Parent = icon,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 30,
	})

	local window = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = icon,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(0, 206, 0, 180),
		Visible = false,
		Position = UDim2.new(1, -185 + (count * 20) + (count * 6), 1, 6),
		ZIndex = 32,
	})

	table.insert(InnerPickers, window)

	local outline1 = Library:Outline(window, Color3.fromRGB(50, 50, 50), 33)
	Library:Outline(outline1, Color3.fromRGB(0, 0, 0), 33)

	local saturation = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = window,
		Color = default,
		Size = UDim2.new(0, 154, 0, 150),
		Position = UDim2.new(0, 6, 0, 8),
		ZIndex = 34,
	})

	Library:Outline(saturation, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 35,
		Parent = saturation,
		Data = Decode(
			"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"
		),
	})

	local saturationpicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = saturation,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 2, 0, 2),
		ZIndex = 36,
	})

	Library:Outline(saturationpicker, Color3.fromRGB(0, 0, 0))

	local hueframe = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = window,
		Size = UDim2.new(0, 15, 0, 150),
		Position = UDim2.new(0, 165, 0, 8),
		ZIndex = 34,
	})

	Library:Outline(hueframe, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 35,
		Parent = hueframe,
		Data = Decode(
			"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"
		),
	})

	local huepicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = hueframe,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 36,
		Visible = false,
	})

	Library:Outline(huepicker, Color3.fromRGB(0, 0, 0))

	local alphaframe = Library:Create("Square", {
		Filled = true,
		Thickness = 1,
		Size = UDim2.new(0, 15, 0, 150),
		Position = UDim2.new(1, -20, 0, 8),
		ZIndex = 36,
		Parent = window,
	})

	Library:Outline(alphaframe, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 36,
		Transparency = 1,
		Parent = alphaframe,
		Data = Decode(
			"iVBORw0KGgoAAAANSUhEUgAAAAkAAABuCAYAAAD1YDnyAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAFMSURBVFhHvZMhTMNQFEX/WOZwKBwON4dDNMHN4XBzc3M43BwOh8PhULip1s3hcLg53Nxcue9mIy/ty/8kDfcktzlpsv97xEZ1XacjVVUdLKWmaQ6W0slfNmrbdgIh/tf+1PCX3YUvu7MPP4WQQR8evuzO6s4gRFN3DiG5unFpvaOjWd0FhOTqwiv8ekdHs7pLCNHUTSFEU3cFIZq6awjR1N1AiKZuBiG5uuLsEX6Hn9XdQkiurjh7hFf4Wd0dhGjq5hCiqVtAiKZuCSGaunsI0dQ9QMjguuKsbgUhg+uKs7pHCNHUPUGIpu4ZQjR1LxCiqXuFEE3dG4Ro6t4hJFcX/mv9ekdHs7o1hOTqwiv8ekdHs7rfOzR1GwjR1H1AiKbuE0I0dV8QoqnbQkiurjh7hN/hZ3XfEJKrK84e4RV+VreDEE3dHkL+uy6NfwDz0OfO0eCa+AAAAABJRU5ErkJggg=="
		),
	})

	local alphapicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = alphaframe,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 37,
		Visible = true,
	})

	Library:Outline(alphapicker, Color3.fromRGB(0, 0, 0))

	local rgbinput = Library:Create("Square", {
		Filled = true,
		Transparency = 1,
		Thickness = 1,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(1, -12, 0, 14),
		Position = UDim2.new(0, 6, 0, 160),
		ZIndex = 35,
		Parent = window,
	})

	local outline2 = Library:Outline(rgbinput, Color3.fromRGB(50, 50, 50))
	Library:Outline(outline2, Color3.fromRGB(0, 0, 0))

	local text = Library:Create("Text", {
		Text = string.format(
			"%s, %s, %s",
			math.floor(default.R * 255),
			math.floor(default.G * 255),
			math.floor(default.B * 255)
		),
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 0, 0, 0),
		Center = true,
		Theme = "Text",
		ZIndex = 37,
		Outline = true,
		Parent = rgbinput,
	})

	local mouseover = false

	local hue, sat, val = default:ToHSV()
	local hsv = default:ToHSV()
	local alpha = defaultalpha
	local oldcolor = hsv
	local toggled = false

	local function set(color, a, nopos, setcolor)
		if type(color) == "table" then
			a = color.alpha
			color = Color3.fromHex(color.color)
		end

		if type(color) == "string" then
			color = Color3.fromHex(color)
		end

		local oldcolor = hsv
		local oldalpha = alpha

		hue, sat, val = color:ToHSV()
		alpha = a or 1
		hsv = Color3.fromHSV(hue, sat, val)

		if hsv ~= oldcolor or alpha ~= oldalpha then
			icon.Color = hsv
			alphaframe.Color = hsv

			if not nopos then
				saturationpicker.Position = UDim2.new(
					0,
					(math.clamp(sat * saturation.AbsoluteSize.X, 0, saturation.AbsoluteSize.X - 2)),
					0,
					(math.clamp((1 - val) * saturation.AbsoluteSize.Y, 0, saturation.AbsoluteSize.Y - 2))
				)
				huepicker.Position =
					UDim2.new(0, math.clamp(hue * hueframe.AbsoluteSize.X, 0, hueframe.AbsoluteSize.X - 2), 0, 0)
				alphapicker.Position = UDim2.new(
					0,
					0,
					0,
					math.clamp((1 - alpha) * alphaframe.AbsoluteSize.Y, 0, alphaframe.AbsoluteSize.Y - 2)
				)
				if setcolor then
					saturation.Color = hsv
				end
			end

			text.Text =
				string.format("%s, %s, %s", math.round(hsv.R * 255), math.round(hsv.G * 255), math.round(hsv.B * 255))

			if flag then
				Library.Flags[flag] = Utility.Rgba(hsv.r * 255, hsv.g * 255, hsv.b * 255, alpha)
			end

			callback(Utility.Rgba(hsv.r * 255, hsv.g * 255, hsv.b * 255, alpha))
		end
	end

	Flags[flag] = set

	set(default, defaultalpha)

	local defhue, _, _ = default:ToHSV()

	local curhuesizey = defhue

	local function updatesatval(input, set_callback)
		local sizeX = math.clamp((input.Position.X - saturation.AbsolutePosition.X) / saturation.AbsoluteSize.X, 0, 1)
		local sizeY = 1
			- math.clamp(((input.Position.Y - saturation.AbsolutePosition.Y) + 36) / saturation.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - saturation.AbsolutePosition.Y) / saturation.AbsoluteSize.Y) * saturation.AbsoluteSize.Y
				+ 36,
			0,
			saturation.AbsoluteSize.Y - 2
		)
		local posX = math.clamp(
			((input.Position.X - saturation.AbsolutePosition.X) / saturation.AbsoluteSize.X) * saturation.AbsoluteSize.X,
			0,
			saturation.AbsoluteSize.X - 2
		)

		saturationpicker.Position = UDim2.new(0, posX, 0, posY)

		if set_callback then
			set(Color3.fromHSV(curhuesizey or hue, sizeX, sizeY), alpha or defaultalpha, true, false)
		end
	end

	local slidingsaturation = false

	saturation.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingsaturation = true
			updatesatval(input)
		end
	end)

	saturation.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingsaturation = false
			updatesatval(input, true)
		end
	end)

	local slidinghue = false

	local function updatehue(input, set_callback)
		local sizeY = 1
			- math.clamp(((input.Position.Y - hueframe.AbsolutePosition.Y) + 36) / hueframe.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - hueframe.AbsolutePosition.Y) / hueframe.AbsoluteSize.Y) * hueframe.AbsoluteSize.Y + 36,
			0,
			hueframe.AbsoluteSize.Y - 2
		)

		huepicker.Position = UDim2.new(0, 0, 0, posY)
		saturation.Color = Color3.fromHSV(sizeY, 1, 1)
		curhuesizey = sizeY
		if set_callback then
			set(Color3.fromHSV(sizeY, sat, val), alpha or defaultalpha, true, true)
		end
	end

	hueframe.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidinghue = true
			updatehue(input)
		end
	end)

	hueframe.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidinghue = false
			updatehue(input, true)
		end
	end)

	local slidingalpha = false

	local function updatealpha(input, set_callback)
		local sizeY = 1
			- math.clamp(((input.Position.Y - alphaframe.AbsolutePosition.Y) + 36) / alphaframe.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - alphaframe.AbsolutePosition.Y) / alphaframe.AbsoluteSize.Y) * alphaframe.AbsoluteSize.Y
				+ 36,
			0,
			alphaframe.AbsoluteSize.Y - 2
		)

		alphapicker.Position = UDim2.new(0, 0, 0, posY)
		if set_callback then
			set(Color3.fromHSV(curhuesizey, sat, val), sizeY, true)
		end
	end

	alphaframe.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingalpha = true
			updatealpha(input)
		end
	end)

	alphaframe.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingalpha = false
			updatealpha(input, true)
		end
	end)

	Library:Connect(InputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if slidingalpha then
				updatealpha(input)
			end

			if slidinghue then
				updatehue(input)
			end

			if slidingsaturation then
				updatesatval(input)
			end
		end
	end)

	icon.MouseButton1Click:Connect(function()
		for _, picker in next, InnerPickers do
			if picker ~= window then
				picker.Visible = false
			end
		end

		window.Visible = not window.Visible

		if slidinghue then
			slidinghue = false
		end

		if slidingsaturation then
			slidingsaturation = false
		end

		if slidingalpha then
			slidingalpha = false
		end
	end)

	local colorpickertypes = {}

	function colorpickertypes:set(color, alpha)
		set(color)
		updatealpha(alpha)
	end

	return colorpickertypes, window
end

function Library.CreatePicker(cfg)
	local colorpicker_tbl = {}
	local name = cfg.name or cfg.Name or "new colorpicker"
	local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

	local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
	local callback = cfg.callback or function() end
	local defaultalpha = cfg.alpha or cfg.Alpha or 1
	local lol = cfg.parent or cfg.Parent or nil

	local holder = Library:Create("Square", {
		Transparency = 0,
		Filled = true,
		Thickness = 1,
		Size = UDim2.new(1, 0, 0, 10),
		ZIndex = 30,
		Parent = lol,
	})

	local title = Library:Create("Text", {
		Text = name,
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0, 20, 0, -2),
		Theme = "Text",
		ZIndex = 30,
		Outline = false,
		Parent = holder,
	})

	local colorpickers = 0

	local colorpickertypes =
		Library.ObjectColorPickerInner(default, defaultalpha, holder, colorpickers, flag, callback, -6)

	function colorpicker_tbl:set(color)
		colorpickertypes:set(color, false, true)
	end
	return colorpicker_tbl
end

function Library.ObjectColorPicker(default, defaultalpha, parent, count, flag, callback, offset)
	local icon = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Color = default,
		Parent = parent,
		Transparency = 1,
		Size = UDim2.new(0, 17, 0, 9),
		Position = UDim2.new(1, -44 - (count * 17) - (count * 6), 0, 4 + offset),
		ZIndex = 15,
	})

	local outline = Library:Outline(icon, Color3.fromRGB(0, 0, 0))

	local gradient = Library:Create("Image", {
		Data = Images.gradient,
		Transparency = 1,
		Visible = true,
		Parent = icon,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 15,
	})

	local window = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = icon,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(0, 206, 0, 200),
		Visible = false,
		Position = UDim2.new(1, -185 + (count * 20) + (count * 6), 1, 6),
		ZIndex = 20,
	})

	local colorpage = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Transparency = 0,
		Parent = window,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = true,
		ZIndex = 20,
	})

	local animationpage = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Transparency = 0,
		Parent = window,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(1, 0, 1, 0),
		Visible = false,
		ZIndex = 20,
	})

	table.insert(Pickers, window)

	local outline1 = Library:Outline(window, Color3.fromRGB(50, 50, 50), 21)
	Library:Outline(outline1, Color3.fromRGB(0, 0, 0), 21)

	local saturation = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = colorpage,
		Color = default,
		Size = UDim2.new(0, 154, 0, 150),
		Position = UDim2.new(0, 6, 0, 20),
		ZIndex = 24,
	})

	Library:Outline(saturation, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 25,
		Parent = saturation,
		Data = Decode(
			"iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAYAAAA8AXHiAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAE5zSURBVHhe7Z3rimV7Uu1r7do2iog2KqIoqIi0l9b+oDRNi4gIoiAi+D7Hp/IJ/KgiitDeaES839u71uWM35hjRMacuTKratseDpwTECsiRoyI/3XNtTKzdvft1atXb168ePFWiq0+Fz/lV5HX0nfx7uUHu91uT+Yu/j3sOe778hDWMXmEeckMVrtx+VDL2bzJhU/da+yVB/by5cs3r1+/HnyPIX3x0Ucf2UfgUgP/448/Nkb+v/7rv95+zdd8jS1c/P/8z/+cceBQS+//+I//YJGvhb1VuTkI/VTjsRkDvrhw3nzLt3zLmz/5kz958+lPf/rN7/3e7739sz/7sze/+Iu/+OZGgRrMQFHqPVhjLODCBq8mV6w1TP7a/x7Ptj32hi6dGha3cGMsFLuxjO95JAfPF0ZjmUs+OfMoKi7x4cNdPcwBb7zwcl+Q37z0gmscSR2HySXyuhB6gBeTD0yJ/e4pGCpOLygGYR7OYxXPeXLJxG99cV8qeEu9p/Bx4f3zP/8zF824/LfM+1//9V/f/P3f//3b3//933/z5S9/+fWf//mfv7jp5sHpgqse9Il4uLIz4OJcrX3GkO0TwDlq8dfYU3PpaaVHLwFBfWkPbmpWTzbMuMTvxuCP6qi5s54q9Sc8XGLn5L9WK+fpQQ4Jl/4+OPgLs23cWrkdt32Ypi8UVnhrZi6yiH16IBSCoY2x7Rn8rS6Pe3Ph9LBhHY55g0P893//d++3LHmP/w//8A+vP/WpT73VRXrzt3/7t1wwP7F+/dd//c2NAhp38OgpZhKxzTV/rTvl91MntY7l73f6cDbGYiTNz0ZkLru2etpwNoExKSJevcpzr/RrbjaeTVWuT4HmOQXPnd7BXIKVDr9jYyW2zV0U+J4/fOqbTx/7JNKfp2NxYtdi2YeFu4++/vgNytNQmN/s4vjxCJZS9+DBQ/7f/u3fmBwXi49BP7X+8R//0f4//dM/vfm7v/u7N4rf/u7v/u6bL33pS29vPMboQfHSiZmwdBa2c/WRTNQYNcsOb+nEqvGmFF/+YFikPofOIpMfPLaX1loelt5sHB8tJBR7F5m7pDVz6ampH0Wul42wdSf+4nFSHu+KRxl/LmNy48s4ljKYD39fGC4KImxywfj+5KeOehP7iQrOxxt8LDXsCd+38emJ8BRDdanckxxPJfrxPU2X7PW//Mu/8AR7+6d/+qevpVzEt7/6q7/6+sZnJiNl4lXHLJQJNd45VAPIzIaaLzsXK2qSxBwWhcgfXqx9pbpBHds49tLXNfDyZbU44zXvwdgUxiVG6IOFK/GmNifxdxNiafG9BtcBrrj9y7/rYwGCzzw3B5+XjRNrDayFcSGdOEuRu5j26IUO3fOOeM/YPzsSfPaejzt8LmcvG1YXzF/0dZlecOG4O3D+8i//ku9Yb7B8LP72b//2m9tXvvIVN83CZoFs7vVgt89AzYe781PHBBvf4dl2YennL7/JOS/xJuGDXfOUyz6qS+50scghsv5yvbFVP31S1z264ie+6mkD1T5Osdrw+uSYesn0vNiNI70cni824l4AcLPvrkV6DsRclGLEgPK9CbKI6/M080+EXCQ+9mS5oP74ox+fePL5vvWG71d81/qbv/mbtzcAGjOJKhNGFzY+g9YP78qh3annpddwYh/1SM5KbeLmsNd+xumTPHXsEzl/1LJBuWDl7Z6dozecPH44UxNf5vF3KYktOan5kvZH9lrAyp+xGuOD0aB5LP0k+6nl8XsmJWCpqQ+HJws+Asx+4PJCvUTm9QseGMH5WAPz06rfrbD04uORS8XHIA8nnnJ/9Vd/9UYfhzy13t740kXXLMDKY5eJLWxP1hNFwznVMqH4jy4MShvhs/n0a57aS9/yGH9/dJxqW0N84ZofzOMXg4uyVqxkj+0xypf0VwjI9Ik/fHHmaVKsPHozBngwz5EcL1jmYlJi8gqHh1xreAGjvy4BFCA/EcHB4MUa46KAYbk4SHwrF6cYTy2sLpJSr1/0gvExKOufFmVfcLl4Wv3FX/zFmz/+4z9+cyOgiQb0YGwgSsxkwfCZQOL5ThJ1nsHJg/WjRzG74MXCSb593U8i6OihGNg+NYrn4024eRCw8ecw2jO51nSM9m+uNVDcp+OgSPoyfw7WdUg5HQ8phsT3uvHhsXfBdi+PG57nVN+OLhRW8+BAi82cJbYoY+QytKfHV51JnaueLscXqqMWcR0DYME5R83htbj+yBPH382YA9+x4PGkIqfvWlZdLl8sfq/F9yyeWre//uu/9ihq5o1gQ1lcY5QJFrvkvcL4XmBy1pXz4uqzIAmY+zQHtmL7YFxkZGP3ePjCfHjE7Q/OmPVJtja+axcHuP3YH3M3BzycnlJrx8e5Won7aR/Z1/mJmF7N4cR6HHj46QEXOxhhMK8fNxelWC8QEOILZCd5PtLI830KWKrweELx1OI7lqjzlOJXC9Tp+1Q/Dt9yybhPfP+6ccNozgQhylLgGGWwYM5LvSB8Bpbvn6JQeFFyU1OMCWM3hiWx6+nPizB/DMADU+wmHAp58NROX4l7xJ9x0o/YvVLvsemHH9k1M07i9rUllgzu6BzPnOL78LAFGUuxnxgZBxhprfuAU3ukLJ5T+3FRANNbsJ9yrnMTteFyYKnjskj86wa9cf1LT3zlwXzGukB+moGr5oUuzGt+3cCfhfgdFj4fif3NgvIv9FH4mu9aNz4TARmsGxz1ghBiFimVe2wycq3LRriIBRKThwaGnz6Erk0drczPRp14zcGlhk1TbD+cGV9U+62hPhfRPOoQauFhyS1/csHH5+USX7FTP2z95jUFv1mwmgug8wvvvN2b/LJeu3heR/ZhLgkl9EDZx/bonorn+mJYLmQuJbZf3v2E4+OOml46MFQXjo/K/kToHD8Zctn4zs5T7caPiAzAZJnQulw+ZCyTkvUfPeFKPDiLQ+GE70UJO303Wtz5jiHI+fIQcFSYF4rKF3QcVmIZy57bHAjY8t2v3EvOcyvW/M61jgbxT/3gds3EKDmpXP/k6B7i+eLIR4YjnNOH4/3yRFJLXzA7h9Dfk9UTpk8V96UMjIsBRA2Y1B+1HDylXJIKtQftDb+TosSDcrHim6YL5KcpTy8uDDE1PL3oq8v1mo9Bff/yxyYfjfxO68YXLRowsC5ON6iL7Ab2UnlC5JgwC0eBiJkMMfVoqLuvD6K1xJDggSn2xmESuwG2cSiOdy0Y38XSv72nls2S9VOh+OYgjS+9+443QA6hBsu+SKg1v/biTx5Jj1ONgUOICU9r4XD32CZKGD8Xputkvq7h4Jk7+6+83OPCoIgsuPvg0wdNnrgfkf7Jj4tDL77E8zQj5jfvfLfi1w9cPC4VT60b/+SBSTIRJsxEsTRfWPOeADaY/XI3xsRYO4vt5lCbuGOYnzGNURi+N6O19Dqm6UtnXvweiDdJvfpURKA5hWYc8xBicObP3744POrJwSO3+K5ns/PDRA+6PHNbFwwfqW+cuq4dTRM3ulqlWE/fcMM9zHDZy+O2HHjFXOaM7Zi9PIA8gWTcn/WTQ7hQ4rzASvyFnacZ36f4Tsb3q/6UyGXicsHjtwyqeXvjdw4MwNwZtJvPwGAcIorvSgkbE2wW2jpwJpC6bgZl3lBwxV5MY2zGc89ywINxKv0OMuPQEz3Sh02tx1I8Ocmej8dtTWP5HWfviX1Jue4D0Bz1bHYOy6qc19d1Sdy7eQMPY8+hR8yReAw7R319Cz617Deh1E8k+gjjolHvjziJS+DqrHxhhFlbyxNHF8tng+WCcHGo4cIR89Gn/E2XynkuF5eKWr5zCXuhL++vb1/+8pc9ERaAZaJYBsSXOqdmXYg34MqTz8elP49bh5KHJzWPPrQiB0ZOnD49nAvX45GnDowkMRoe1k81JBzjKBubMcttrv1QH1gwOO2DbNxYc+nbcdpv1yL4XXefOsYO97g0suVerX2TjktivxgWlxf2XXltpS+Q91QCDSk2lwkMDr4ujbnEXCAsBD7ucgH9t0HiYK4V9kKXyn9b5FJxufgCz2W7/dEf/ZEXy+EwcXwGxTJan0QGNbh4832L5mwatagofpeQbz9xmnefxN1MCzGafh4bbc4kjUcN8winczSOxm9v87C8YMHB9hzoh20NL/Kdl9hP3nHzMg601ulHPpZmxwlL2sOEY15zA9o3PQ1Jj5OPj02McS+EcbEGlfbLOaaPn2LgTeUi+RLVSvxk4oIyNYB+/BH3MnGR4HKJ6MMlIsdTiwtG7C/vf/iHf0gPJjv/1JXBwLQB3qgsBMgHw2ZqwH7/KYf89IFLDb7sfCy0H3n84O7bXuE5phEYvegt8Vg0D460J1x/Sac/CodcOOanh8ekJjnEPhzqSIGh+PDxmS889qEc4vjOtR6RT8FNdfMxSxJubYUYUww+++FAOEqb1oWPNZeLwNgcOlhwLoEvKxdHsevh8kSCrxb+eJT6InPZ4IKxXvoxDy4PTy0unYSLNB+H5MD5DfztD/7gDyAwyblYNJL15q4NOnGyAF8yOAxKTB15eoRrjHzjjOeDoi8v9GiufeJjZj6yjltLjMqXOS53azQep1Nseqdu4vKLY4nJ0TNc3kjH4IeUi4B1HhZyxNBrJX5JnQ9QPbU13m9zwiP27WXfEp98yAi1zJOcpLgtPbkcCOcFDkYNcXL+rsQ5yvrppovTy2Uel6sXDQyfL+/kiPkYJMbngknf3r70pS8xWSYxl4YJII0ZrPkuQuFsPDE+eeposPP0k2+MGAq5cJ1DWXDwzbXdeXLhTL6WXPOI+ATmBp88Gr7rGcMJJnXk/KQllOuPFdbIPFrD2rNPrfMcwcHgATMPYf4BBIy8qJ5bxw3WPJaQeuMR+wYFwyOklj7EreXg+aGCjy3yqfP3YGrJC/IXdS6LanyxuCDK+Y3Ujzw48Hkqyb7QU8q/x2IsLuZXvvIVx/Tmo5A/7TP7UQ1o3bEsp+1YjU4c4vJQBpXlt5qcyMT0wC9fvmMEq0lNTfgzFrXKf9R8cHzzZPnsJeYvts7RX3zHqWtvlI0vTj/2gUdH50hMT88tPc2hby15esBPjO+14Sf23OgTLj6Y+6XXR6yPHKocv89wfyw9Uue50T815qfGeyT8pcbBejxdDMaYtVCXPDU+f6wu0cvMx2Mzji4PPT2uLg/YS/E6b+8RYxPrAtvXeO5/498oy/HN5Z2HyPeNzxMIyO9cYg3iHLHUSfiL63cneSRcavyuEg+6eRlPqeOJZEeCv7gmNw9Fekwq84BCAgtfbj9mWgsMx/liR4kFqPNx32L0jzVRcuoDt3w4mrdrmD8gmBtAkLRPMdyo+wBL/R0RKS9j0B9xzDhIzwQr8Rjy52NQ/MF0Uegn+gt/xJGTEPsjkd7Uhdcv7f6Jb1s4fOyJQh9+E++fGFXn72q33/md3/FGaWAPRhGTQBuTYNMTexHE9cV1jSboxwM5Bi4e8SGAIeDEco1tH1ncU77jpt4Lay55zwEcDg3Cm7kyt/6SE4WrunIdp9ZKDSA4Gk7H5yniH2TgwZfYKg/ROWIUDgfccXjBdwGAhFjqvSfNelkX846YA44Sp85vTPEEu4YnFD2AfWGE20d1CVwcHK4/zpL3JYQv3P+EJhfRfGJUQh1/K6SWj0ivr49CTp+V4jvGFkPVkEchvvbG31tGsyAm137NuW/r4OFLwP2Ilcj1xxC+H9eMn7w/HpWbsRdWnh/BYNS3V2qs8NDicLUJ/nhInfu2f3q4Rr7nTBycuuG2B5h6FmMfnCOmHiu1bQ4edVj6hzsfdfHpz1cFuOYF7xieK9rxycHlSYKlVpfAfeFhyal+PoLle+8iXi99yMOHG759RNNyXEyWh4prbr/1W7/ld4rieZewEMVz0xWSP+VkfHs1Cb8L4/udD0+15rmBpDwEH5iY3tsnl3EcJ9++7TG8zKU9zE2dLWvYlrR4fZt3XAjz1k8frxmLwsNCWb7nFzFev3nJYJ2HhAOfcbNe56Rt6B8WpP5Yl7qP4hg7rXeePitvLhg8bNRz1uGXMx+P5KTz1NKFMo8nEzW6jMzF/y1qn1b6aXD/kboflS9uv/mbv+mZcHAq9uCyp4vVHH64dpKD7xgrNc7hsNEMuup9aIyRPGXIo4uDCPN3DXiA7cPE11g+UAPxJdR40+X7+x5pelITf9ZAHBwIezpMbOdAUJ7EfdPDsdED9/hSE+DVJy/tPgWaXzjPOFeLwOmYvGAZij1N3phfMt7Kod48Lo/OZvrD0cUhNM650YKPP3yUS0Yd3NT7n9Conf8zQur5PRaX6/Ybv/Eb9PU/9mLCkFkcFybii8H4Uh/S2gxvDAsDoO4pH0sMnwWunrOZrZEaXxb1JakvLptG2t9h6ImVdD6uD982cpo/OTsS6lsXCOtBJWwg+dOF40X42HCI5xKBJW6P4XJITqYuGFAvJT6pnd+85vD9RoQGqLOE56cVONxckqknQY4LhIBJPa4uiPv1coXPl3O5r/29i4tEDp88l4pLduM/hwZYTwMvkovFRJhNfE+WzSdfn0OiMZx9MPj0Ig8/6v7F8PvHW/hgjEk+vMF4wSfXMbDtFalvSx7pF3Uwxup6pPNkIieF51xjcondjDw55pYQC8GHcJHdV+bgEKR+5ijbenhQ2mzOBEts1CXz5xpjKYE/5TxFWG8uhkH64GPpy9NHcn1iTY10LhMxvD7xFPtS8VEIptxxHyCrl5WJ1keV4xTrX3O2yrND9aeHmhfvl8tTHosIZ0Psq6ac6QlWPrbj0lMl/iKKHw6PWXxj9CyX+tQ6l5gvoB4vMbU8SmceYNTFdz055pX5emz5/RJsDe6a9oDDfMGp1UG0v5Wa9HYc6y/N+OnpcRTbdhxZOK4lB46fPaJHOa5BVx+ePjNv5sU48FF4Ev+eSzlj9IVDP6zi8oxB8uZj6yP1k2PAwVQ4HCYVn0GHDx7fiij2YSdvHwsOBz5+bccpBgf+7i1xLrgvKXWp9wbAZ8zUm4tPnTgzJwRLbfpZ03/mLdtD9aHQg5zaNPbcys8YPuxi6ukYPlxJfzHp8eXPoYZDj/HR8oTB5SlqfsZ6ybjheA5YcunJeL5w1KfGlwJ/1RqnVpgefh+RZ42+8OBYuB9//LF7YgG8aViBY1VoHMGCITQqj2bw4g/WOnz44MJ68QaL9URT4968Y+hLTJ6cbBdtnFq4VfrBiT9zaEwtc8AX1rgba4z5gTN+sPZyHbnUe+7BPS8w6mV9cOSFu/+uSb5rIccF8I/q4bcfOfdrn84r/f2jPjz4wl7y1AnudbQWS9+OSw2anl4jc6GvrLnE+GBcJuq4uPQT7jcBeXy44rxMvce9/dqv/Zo/d5Xwh3Z9kbhJp+9XF7+f+/Yl5m+sPt+jTJCA4WqSOFNTX5T9PWpwrPDm6Ts85rX55Sl2LdxyNo605ikfW2UtsvTxDzEmpB8+Ibh4kIo3Z3Hx0XvqmB9Czs4hfFES5fheWiHW4dpvL+ZFGB5v0uLE/DoADN9D0IMv2RVdrs7DPVBhXptqXU8h48JV3mPAgcuXdSzftVJz+j5xUm1Q3zHsglU+J6l5aWay3PZiGayxlbzE74RMbnJrXNcTi1/8lE9fP3ZpSD/yKKLe7glPmH1w+X6HSoZD/qKuwSq/x3aeseibOfQp5Dhr8jwSk/c7NzjWc9B0TutITZ8onlu0H1W21DZHzB4lb07yWH8MyXaM6aOxmfOsRz2M4YMlT+x+xeKbRz98KU8JPy3BGQ++3rgvpe4rzG9jbwy6/R1vXM3GRxEwcXyYamqQmloGTw8mY5xL15hc68E6WfpHyfHuMA8+l0VxN4xSxDlUPdhApY7NJFdeahzTj77i94DB7NMjsbnwWsvY9ISDjyWGE/G41MMnLzv7nTrn6L90MKz6+MCJ4WvdrPnECe80BmPj9wKk3v3gNy+LztqSN0asuu6xa3R37DOP+C/1ncp7QS3j4HeSPgy0fg7em6oJN++FM0Bia2uYTDAG7OLKYWI8XstrDzCPgaQGbvvsXp2L37mK3Q8cDIUHB2wdgucQTg/Jig+XzegYcJH4VvVsL3zzmAN14ZfrJ297y/pgOh5KL+WsnSs9lWOOfUJYOxa+7MucS+tnDHiagy05etEHTHzXoGDi2G89/IzjpxHf1ahj/8iBdR77p0f10recl851PGq4aJ6ASAxsbVwFk/UBYhOf8mo89VIG5nOWzW4/JupcrbRPMiZvTiZI+cyj9eEQ8+6YsagpDy2eHszDm7B4ffI96k9NfObhDYwtb97JtdRxkVrDOOBZS9e5e/pwwVFw8loSnJ5HffcCSz/PAVXs8TW2edRg1ccXhnHI44vrw8cSM1Z62UrZU/8UKcwfZ6kj9t//6AeHXMbxl3Y4EuO9iGA4MwCWWE1GV+zNaPyfxx84u0FjyWeyg2nQYq7Puw4Yjg863JlDrDcrdY5V4yccmgOdHL56uEaLA2dDTge7fak3EB/bWvmef+Y5eWyVmPnL9+93mhfmzQVjLGFzwLLeg+Q4AOdQ8NZJPS/82iox48ChN3MQRk+PS66atRqnjnpqUufvZPI7f49NHWvAcmGE8Z2RnDEeUal1r4zfeo9DPYk5cFTJ8beCa6K2KA15AWs9AzeHJV71xuS7Dpu6LtoYlg0Jp/NpP/uMCae5jGPd+Lb1mZssvjU9PT/y9Eo/Y+1NX3zqi9WK53fpqvfaN5e89HT4xeX7sIP7aYQPf9XUn9poc46Zi+y+DK6X7x8quqYL31zNF5/9MB8ffnjm8kDB10OMS4ffWq+Xpxs5BiY5G11N0RxmrBe8OVhEPhyZ+YhzHn9ZJud+WHSN3zGG0x6JXb+xxmhr47sHFhXmQ2MzV503oj71cFhL68gl743DD+6LjYY/PaXEbLbxxDMeMdyV92HCKUa+NWCxVnBpL0zHMxdNvj2YXvMdiz7MzzZc7094ng95WT/VqFEbc7k1YHDF8Xcy1oVyoeBR7xdUhLFoBqRY3OM7TbC5OOGbQy6YYz1GzZN0wc6DLT45f7QRdxzifgz14075Hpb7hWcOtbXNaZxuyIyFz2VIj/Gr7U8v+CjzFeb+1KRuLhrzLJdabPr4ndx5wE2+h2hLDk76u6Z4NXxreJ5TMNcyn+Q9V/V0v9W7vYiZ81yO4O6RuJeHLes+ztwQuAg5cOrgl+uLhSjhTYvO5IXbR/HLa02anfJgTAAMv5dEi3TvcNrXlo3gEsEn314Zp72MwQOjJvyx5MX15qG5mMXtZ2wwX2oZxzmMqveGXPkoHHoFx3rjV8/6voDd/J0DD9bDNb50Dheu4vKMoR03sevok95c/Pn36eSE+elSDpZYPOfhMg5Och0PyJdP3PabOaDgKDz64ZPoRfBBoCqyJseXawbxZmIp1uR8UAtnQDbTcXowiCU867UfPEnHdS14L2Qu0uTp18uVXt28xuZpLvT1vMoDbx9pD8dzlLgmWNfdOnr4IMgzt/BmDnCk7Yn1uI33JZeap36+NFg0uNcfbvv7exN9wm9f90bhUI+CMx41iduP2HXtIXFP/IzlS1YeWOPOs4rwKwd6Re13wC7kkc0FslVz+1hk84Qdj5djsuYk54mRwAfj8LDhDKY5Fj/xUfyoa8gXD39y9AVTPF9q4YMTk0Plm09eh9DNda1wH054WPIzD7Xz5heDF8y19GVO5MHgdKz0ZkrMz09N5gIPzZvBHMbuXGQdcxFkfWHS2/biMy/q/GsAMMZPP/99UljVde2HZRDmVzzWPyV2XeRTzz7yhPR3LOnxR+h7iqjZ+M/lUflMjoWfOJVMGBzrJPxYr4OnAEIaTK7fdWDUY8HJE7Mg6uiDgmd8czOMYza0PSQzl9YiyRujN5Kc+UxSsfs0T4/0MQaPGqkvteK+m8HcHx75WA7LvPakDguO1EfxO46s8/SNeuzU9WOpa+nlbJ/65pOX7cfZcOEhPJnke9zw4LePv1+Rk/gJRgNPJhMaf8UUUmFLnLzfZdJuFPxOlAHMg5PYNVmkL0x7gGER/TjrBe2+8Ja1wlV+fGqI5bo+vH6HguIDDs+1rZHORl5x+b0AG6O3a1JnjLzmbZyajOex+kQE3z3Jx7rP2hf6tIZLSh9j5PHhs0/EWZ8xxd2bzt81K7aPqmZ+8gPf/eCmHzVy56N2emVc/3eF8d3fk0BFstK0cXP3VMW2CBY+T5zgbKQtMUoMhw1qb2zz0i5o+pJHyt015eKzGdhyicPzxYUrn9/Ct0cPcvqQgy/X60foCQcu2B3tZXDt7kmeS6K+PjRwiQ+JXHq6Bow5E/dJgLZn+dL27uG6p3wO03NI3r+zKhbu1FWDWdVnlFh1nnfmg/bJCsd+ubLmgoNR8/KXf/mX/5cCRNzjcqFMSuTjZJUjNoHgwWK8yWB0PGBPwEnqgFcvE1hwfGMIPr0Q5WeM9qcGq5gF4ZaPD1a+/SawwTxFLhGp9pNgZywUDBLzNzkcemAlHgNNfvasXDjY+qwpNZ2f55SajjtjoJnjKGM0R7xq6Dc9mhfkixzcfeXXUjJzSe8dd270wXeO/QvPil8uMcXcxG6IC2rBm6Mwsa3yjTvh5hB825XD98QRfGw5xOG1v3mZl7ErJ/EpJ/FCZRXOpvtjl3wuFZeLXDe8PHOJsdtnHlLHcLGdW7Gsze/uziO80faVeqxgp3FbJ52ny4rL9RMi6rkxtqxriBen+e6550gOm7P0JwxxuVhwqX/VEL/rm7mlL1/BnNPW+qPVmytgLhU+tv41rtXA+J5sMSYHll625WKZxMZSxyJOdRJsJ28MS0wNMdo6cvKp33lb8I6b/ns+e3zvBUIdPv0ypvsEnw2tL+vLtLg+OLBoe7qPeORZH3OZQyoHJd5jyh+uYubNpXCf5Mszp/MBx4dHjj0Apz62PmtAHGPj7/zOYQdnbC4XVvHxxEI1qK0SthsrjubyUNvFeqFR+2DUcENSay6Lwu/iGqdmxhE+GPlaMCy8iP3ym2f8WI8DHq6VmDo4ia31sfSgpmPDZ5xy4u85sqkeL+P63Q9P6g1H07OxD5cYbjmtIw8fLDxz6U0+a3JMvrz2ABfHeXol33kaS56j6hMPnZ9UY92P+o5JndTfqcjnieVLJfnYg6jIG321EpoRjw3uQ8RH8VFmh6WuuKyxZX0QkMB2nP7mtUYbeLLwsXDBVs3YXZ+4h9K1+GDks5nt51x112HhhHfFeyna25t/5Uhn3nDBw+n6ffDk4e0eqbcqnt8xwZO6Hjw9wH0xqCUmT7/wif1xRUwOrLnk8fsT4FygjOlxuIjp6zxjYcGZH0kW7INARZh44/hV4hx080zEWHB/iaMX+faUelOD28dqQj4ULJiEfu6JpOf89KWYubsfHBScvgg9E/viEMNVygo/47oXudas8d2TXHCrYh8CJPrDC79592RcfPJYuMr7MMrDqtaXIJg59OvYiueSkCen/u6TnvP7KjAZz48+2PqtT2ycOHfAdyHYaHnp6Uuz+8sn7997oTRRTP7hOxaK7JiDvGAIxcNByUsZzM9ULYJNn5zs1MBTS7it8QHiY1urzXMdWCbMVLCnmipJ8uDl8tI8OAeOXyus83Vf6uT3MrJBzMGHstQ/TSbvQ6ZfsMGpyxhTr9h9weEwR9XSzxjzBSNe9Z4TvlTw+ZIFB/MFk+81J986jweGDy8x4ys8Lgs2ivjSUVMutYhyp8uEhad864+/FQoY3TF+FkHcRaruuGzkevmC74U5D55e9rEQsyCPURvfefzw0c5hMCwi234zluw8qchlfJqbgwWTduPdE58kPZPH769RLPSGBx8l11pZ+vfXIY6pKU/YHCxjsAfK+SDBg01v4nCJsa333HYtfFlihoI3HGrBY+H4Yy78/s6r86eulxTMY9ITX/PzGHCr1ICh8Aj2BMZuH5HPuwrXG56JPOLWl3rxqZ/Bse3FDLDZXHq6LhxyVuL+wECMJd+5pJZ27o8yNByprTBvYjD3pZ7JKcYYp3ZzgvmSsqHEkJHF6bpmvii+arB9N3d9tqja+FDhpd6HJt81+PSqjTKf6Zmaxu5Bv3Jbq5x/bcB4WGq9aZJyo7508CRTD5Zx2o9aY3D6m/fwXnbBbi7AfmIrPlJ/4QyA34l2I03P4nphfMPid6KuFdw6L/YOh1JjWFYLVzXG0NROvZQF7rzCR2vx77cWx2PiY8Px/jBm8Dm82Bm7tVXijGWfNQpnbviuJyYn8YG1FhwrDF655qietj5MesFZc5iDD26Fv3CUcd2bvMb3pUP56Q4+cyIHL/U9C5+ZaLbRGYO4C3IBqsaPFJy/322MQy1fg7eeUec7FqGsffG8CcoPv0+h9qqAEaPkqKM+Y81H7x6nCk/Wig8NDn77qKctMX1S13E6Pnk23rXUwG1Mzz0OuuLZ0/gdyxdE1hrcFyR7AKbweGJlPlXzsOI4xxwkHcsHCxbOzAcFoyY8j4tPb+qwyZU33OTg8STjI9Lfr4T7yYZKfDHBEWMCvGEKunGzyJ1LbBxZmC2bv+L+JteKlIdkU7w5KH3Js6gqMZendfSkCEvMYcAjDn/7/gjMnFwncY44XPcS5o0gL7ybbD5+tIfpHNill5Ua8vQsp0pOCt4xXJs50t/ziJ08Si09iic3T5mq8NbORcIqpxbHx5T8+QeAq2bq4KGp4wj6fYwecMrzerAdixw14C5AlfQBYosRc4DNSwUdlwe5U+N3X/HkvLD06UY6Ztb0SU/jiHJyD05y1tW3izaOEJeHDw8CNcwhvZDTePC3lbp3fPOSK+afhPoxqqFtGYOxJGzw9KEWYd3lZD6do/lIajqWVbD7NI7PgTI3X9TNpTc9WoeV7gsw/cDLpWdyXnOwXQ+3uLn4wvYls7KmuVgIVgVzgI0ryXlz8kRiEONq5rrUDI5Qk7wtefBXuWytS+w8XDgc4I7hw6NG1jgKBi/c4UmMocK8OVF6sxHus/CtPTTPqzHj6YlfvL2t9AoHrufUHL50cJS5Mkf49F24Y2zqqbMv672U7zklD7f1YJ6rejtPn+Q6H1+CcIuD+SdCcPzmEtOPM3Sd/I15rGI0ZZH7UjSmmTGIzW8OPhtJjkMsJjs/cpMDh0cjeOFPf9lO3jUIOeZAzbblK7SmhvSeczcb3z3L2zF7oZrZ2KzB+Yw13OJwilMrnfkLY8OJt+0hmOOJHgdqPpPggtMv+f5UZ57w9ulegrWva6LGU+M+5QQ3B8Vv74V7P6ltLGmP1vd7VevB/S9H4/tpBYcXJusDzmbaB2MhCFYYjY1LzLsX00N24l0XzIdGET4WnDEyji+frBcDN5gXTk3UXKnj8rDk6LW4xrDlo+L4EKijt7RPjenbmnLhpWb3sSWHz1wV9zCuc+wYtnlqOr9zxNU1nnEkfms9N3LlYemFiuO6jiOdpxJ+rC8FeHqYk9oZSzpf1JtPXS8VT/PH//tYW5kUloNGKAruzSov6gnBy8aah9Cn/TsWSl+p3/UReO4h7vzuDAyfPhnL4xG3LzGa2DWyvPs9ZmrdB05jBmAM5rzrq/BlvU+y1HJosxfN0Y8e9BJmHw3fGDl4SLlIa1Dyin2QmaMPjVwx1U5P/I5DH6zUdUh60XdwqecLN2PM3MjDS41t5uhe8KRz6ZTaeP3jR1QV43fjrpYCmYcv05mA/V2H4ofPouEaY/H1ycnS11ypY/JRcl4UPdKzvTw2PuNlDPdqXq45aDal850Ngyc7H9nkq8yVfp0n2KrZ/FoOo/XeZHLlrj4bn/7EnWcw98ZHya+cxyIO5jWmnw9V0ks0vYTB9dwk85GWy+e+i+dfKWwcLjXE4FvBZdvPH4uzIRwQPsli2Byc42KKZY6LhDbHF3pZNsI1GoSBLfAknkjrOcDy2xvBb4/EcLrQ2Wh8pBxEPTz/jWdtzoGRb1wfnlLEMw65WCs49WD8UJHYuc6vXGn3Ft+WeZPLuvy0yFrIO6ZOU5+LgaUvOcVeF5zsHVzyroEv7b80aH0/9qYXfZrvmIqt9KFnepkPFs70aU3nRQ6N//AdCwVE8VVgi8hOcXnhzGYRc/nJMZPy1sATw28PWXNR6oiDeaKtD3f6tY9sfffCD8dWB8DQjX2Zw7eC069jwQFL7+Fc+Htu807HCvNTkIYS54Ttdz3qi4OGg7J+85hjcrap9eHih+tce1Mja5+eHZse4B1n9fFFqdKruFSQh+jvvGZsnkjKTT94jaP8D7A9/EmnqgYc1BwkShz/bRY9WLmyLHLqNkc6NbLIxvuvBbo5p7ERYgQOFn45WGkPubxR5diU4a4DgTrjkkPBsGAECFx4KE8qRLD70Dd5z0PWB4BeerqmOfzg1LqmcyqmuIfqehQeGBYNH9unl+eR+ft8seplLrZ8WT4SpydEYnDywcu3pt/E0n2pUHM88FYWp0b2sdXGWBYg6wZg2RB8BpoeWDgoCyWPptb1WLjLUuc89fjUxLov4zeGR43kVBMcnYubvOuwizsfy+XQD6x+ePaxzKlKbsU+ECYkOxegPOrbI/178eH2Etm2blkfHDVg8uHVJz9jElMjnZ/i4NZKvXfEWLjy+7Fpjra53MYfw4dHXJ+a+LXnP+lsLaZFiHc8NfDLR2RpdKqBg7JpSnVToJ16VciXQ17WPZHi9EWVZ1Od0yIdwy+uMZ3iBZ96fDjRznNw+sr63d7c5tXCh1tlPFR5z5/1loeAX1WwLbxi+OrDYbT3KR/t4btv5gqv33F8jovnJxExY8IJ3+vCFz7fpSRcHPcnzjzHhyvdOfOLxzY2pxPyJuFX07i+J6cCC9xY/0qgWj4zVQ3fNRyTy0HPH5+FdZLDqQ+3MTxh8Hx5sMr3UW9ehGHNKR+R782PekPIE2NRistR3DG7jqnBouljTb0Vv9r+5WxtH2pkvSZ4in0w5dWHE27HJddDLa+/JfeZSt2Leeg7Ty9c58yXf1txjGGJyyGmvipsnmbiMaH9pKr6I1TbdvpnMye78apiGhvXhI31EJY6ltimthvkSVID3kuWPn7KwSsHXzLjtWclfcxTbcc2hoLRG0XSx70Vule5u5dy3uRwXRM+cd/ptCzfSn3G3P08d/rBRZsHU50PMJziw6ut37i85PZlI5aZuTkXTrU/sTtOX89FS8OyBnK+rOSCs3Tq5pLJugfWSQk5D6LC2XwWWKya/xW3/bRpDYNS1kWg5IyTZwPaG8FH1zjmKMU7a7jJuQccbPmrZvId507MGmcM5aY3vHLZD/zU+zKFN/VYxlw8PznJ1fITkawPgRifHrLzxqltj/geB8tkgvvQsPWzBqy/57R/aqu7zr2o2/nUeC+Yc/sm7ycPOU2F71Xt6T/fkJO1Lq5Vvj+GXYxyabBa9FgNZB/d/jXGR1oj658ei5dLng1OjRfcHlUwfvKS782gpjkOKnWOGYM8okVyiL0Qvp3h+st7Y6XcgxJ8LP3oBQ43PYjZKMaauqV+oiHtJeXAKHG8BYw3Tnr7gqD0SuxLQB22PYrBkbKG4aLp7TmG28PtBTW/Ncn7YmGJuw5k88OTsT9jBKfWYxNLi9u6AKGBBrCP1Rg9JB8ieWwPkgbECPzyqAHbNeRXnQ+xfsbypYADhhCjEhYz9elrvnz6+LBS175doMdKf29Ka8DxqQNH4YBVVs7ryph++oCFY03f6UXcmsZY5A7P62uOMcBRhWgvVft4/HLAFw/b77f45hGrff/8g5L3hUi+ta6Br9iXKzi2F7K8Yh4LLe7bmkSbmUSz+jsHXiz5uTj14aj5CHFVYTd7ctSCo/TGCp8cNpvSAx4OUm5zieF6U/I0np6MkTyW3iP0BWcseJ3PnhdW6gvWfoDUyfceqL7jdE4npUd9iT9W4KvOc1aNLVjHkfhjJuN5DopdJ7VNPE+Q9pXv70sff/yx68HhiM/HW+davi8UyngL6560v3NYPY39hJTvj0YKfQgIVkVPKvks0vx+50JkmZh9LBvLhuZjzXgOi9nMoSbHZJ1P7WBMFq4BCflwXE+uyhxSNzXlwwWnZ+TE7djtBb8c4ozty0ScPuV2/fC9wZJutDeenLg+ZKzGm6cHGErcnkhzsj5Y4bMOiXtF56CTN3/nhSt9fIRRWy54MF8IfOxWeNwbfP6jidT74za5jxkn/ch5cr4smbQVrP49ZeHaBNUfm4BNzpYcPVAEDJ/dIFceY2ZzybMBM0Z74CNc4j1HBJvxLc1lXM8tfTs/jwOesadGOmuRNPaYYGsu0yt8czPGyVKLjbLh5tKjvrQ4A/ugUGrC6+HSy5cFPP3MRcDlt16peVr5iaS59Ev28Iil4O6Zus6LnoRwO24t4hqp7xBj4TMW+MsvfvGLvyLndIhYtBjKJlIT/Njh48kzNUhrMlh9T3JzciiCHsaUmIcubPdqfvqVQz/mAm/Xp9ablhqPK8VOj+ZkZcyxBKuP8cbhCJ8e9anHb4/4uPUdM6dgHgOlVpAvDLnskfuTT8n0RC/xtvYlJwsXHyAcZGLlPb4skPn4ys1FXvkThpUa9zthK4eTpBcd8cDNoRnspOSZSHeAp8yr4/E+eewSc6kR79QrY3uy5FXbd8b0Q+GQx0EYQ2oMFcffI8O1pJ/HkPpdiE0a3xxqpY7BqaEP/bQ288Opzzz6rm1M6HWARWZ+9CJW3r0YC58cROqi/T48T4X08eFKO1dzFSPGiKWBjrOUnOqqxfKdyX+ExhWGOM8YSGrA3QMuCuflF77whV8R0Zsckn2EePtsLLKxclA1nZzEkyme3kxqeNXm6a9YoWP/ZNO6xO7JBmuxrqUGPhfThZLUIF44Crf9pKZSQx+keDkdq3UIRfUl3tjwbeO7tjjE5pqPOoeAsybm5JcDw+75e7zk5Np3XE7UGH3omzpDyc3c2DssHOHeiPAR52pTZ5u4H4uecuqG65uMKmGtj0U2VqUTG9FaJL6xVzowtHkWoLou1HFkPzkcw8dvL/l+mjEehI4bDKi2PPvwou6B0pMcdvE6/mw4eHlYRLk+MYxjieO7V9Tv2NR2vo05DPbc7/D0c5wxqs6jxPFpN33Sy3nw5NwndR6rOZQ4vTqmY55IWDgSmeN7FTY1+H56wQkOd/vmNw/Yg7Rlo/GxxYshr/TRtvlYqRdYHjG2MblY90id+yDi9ZAcw9c40wcJvzHWG5E6+8VT6/EX7nE7//S6q50LnPaPuh94+k6fWG/ywjiUmbv0VI+QX/yTRcV7dMhoOcWTa619hHHk+191thci2/01hl9OrL/sU4+Wq5xxtZ46uLGuh//y85///K8I9KZjmQw+UhxlgyWC5qAxvkzIricGV+wQ/BrrgOFCpakx8u2HdNyEiOcWdS+EWurA8NuXl/KDTy9iifmpNU4PPh6Fd7HmxNqPei7Y1mHJdQ3y2WRjjA0XH6U2Y1JnBY9voWf5EuP0VuxeYMlZrni4vkRg4VjV2xege7Lmt3nArpdyqQBaxxOcxq03Hn348s4i629FsgHznSfx+Ngchi/MzhOjGvhRLJ4vEjgzbQ0a33Dq/CSKmEttMY1vDAFrD0lxj8Xc6CXfm88YzAPBQuy8astF8GX65isfY4vSi76rv3uZFBHeJ4PXscbzPMhTq3Tj9th9mrMlDmauxP2LrX4bPynjCmdsXxRhnivkPOk8vqwffXDQ1jbP4iB5Q2qzSCtF4FvXRpxi/GtdxBsWv33alwszvx1X2pPkF6vpCc+12ijGaR8vGpt686hFhM1lTA9zU2/FZ4z61KLtAy6Z7z9w6sNJjS/IrsdvvDjFzc982Kv274G2t+dNnWQOGoUbdQwvuJU+VXjk06M5x1gpgbkvJYThb677C+9v6efjMJz6rXn4z79E9qERL/UCyRFTiH/l4nOI8BP3ck0P8PYpVg6Cz+WKeMHwwMuTdcxYvYjNIe1Jfgt1YFLXZA5wuxlIN888lfk34+0JtzGcclu36n0JGFfxcPElPtwqPZmbepqDH44Pq7WMD4d8OLQ3V8Zc4XOw1C9ee218fnWBD4YvVfiwjvjuTSxxLGVdrpUaU9yxXM8A3mQES8wAaHPBvcCIfZSG5aB0F+7NylPEBfDAsAbUY3Eo84S4MCg9ILXXq+NQy7PsnlFgc9LbcwIrjoVLX3LwpLbkwKOugwM/ffC9Z/DB8VeNDwcueWI4K+c+sZ4PsYwPq5zUjirlvMQ14Zm7OFi+pHtsetYnl/F88ODxHZOT7fi+ROF17LmU5IvJp8/+waBjnP9HQeqL4AnpMB1LPJlyyKPJjV/+zjeu38PeuV3HWLw0DoZ4DtRzyYT3UPZcvfjWsUji9qcOm54+QKxiNsPzkG8sa8V2Q92vfeGAy/rdDw6HmB7yXdcxajsnOOWRYxyKwbASc7HBqLM6e4jHah8AaniyMIaUjyyvA26tOP03VoxH3I82xGMSVwGDWcuR9D81G676uReBNxrVwIQTF7vkPCHiHhTCKK1B6nNYDL5xXQ4fHDXFtiT2YWR885COI3wOqzgWPjhzEw9prSnE5FJraS/lvGFg7YdLDSoO9X5iUdMcVnEvUnMeC2lMjnHgt+cW8EgvkOdFPYqASRE4Hqt9hMF3beclaR/PJ0odnKr7Y+HSG7894/viSBH7i/9IOzkvWkTbYsXr60D6MaXa4wKAhePfjJNvDfNicGJ48JlhxvGThBwTIb4+jehBz/LgtIcnIGlNuB4PnHctfDBZHzo5eu364PX9b/jplzHNS979cPBbUxvx46I+L63RkD5wxkOBqCV/Uc8ptVMXa46s/wnM0fb4Yg8HDKFWYkzWfCcObsfvk8rjkYOb/u4t7cec8YXBMU4sxUfxwT56+bnPfW5+j4UijAJWVXjKI/itw0qmhklQA8ZLOPbJt1/45gZnws7tGgQfjnBzitmR4Kdm8EvetfhYYuSVLpGdY9mu4W6sHqe5YDsOfepHZw8yBj1ljhrJzCd15RgLGS6ArWKnWl9ycp2TVeK69CD2GHZ02FxUyfRI3eRj3QNVjosI5gsZ7syPxB3rC8et9iJRmqD1dw4p9krvZooNSoR5A1CJfXG8OHwWEsyXDr4LJXDSczYj/NZ3QU7Rhzh93G9xrCtvDnbnpZ4XHPz0MY88H9W7DgHfeumH+rtI8L6biU+HsvP4CONIN89zgnPVcCde/VzPOtq3OHxwiTHWDSdjov6uhB+On0KKZU5rdV6yecTz1Ar3o5c/8iM/4icWWRaTZrb1kXKYoMzOu66crZtbKVfChGdcuIoJk3Y/56QeF7vyrkfB4fGkwUacx6oW59Qjvf10irgx9RBam/4zRuqM4bcPvOodrnnk2pO4vkHJq+MNi0zP7SeeC9xafMaRkPI6hPlCwRHURe4+5dlfWHshxKcv7+IR2haLeh6NfStphKa5bZvrMGYyOXxj4U+OTRE2kwJDePeXI/EE6AN/4RZ88HxPMzeLspDvPFft8FTrQ6D/nkd6YMztPMkxHmNdFQ5cydQiB3QAcS3q5c1GA42Ea5wxUWKN4zrGC0bsTxHyUl8OAoljHLiZP3k/JToGPnb16Hi9aFD9xMGXnurhoeCJPcfgtopn/ckhvYCe48vPfvazfmIhWah9bCZnoSi5OZTNLR+bAfBdE7wTGEzqXs1T1tpuOtwIuGNyrXfiKEHstD8HVt6lz8yn4yFgCWeOy5+L0H7kE3dM12dcONbFc9yeyzpP7EC2E0Hg7H7hIkNjzJ0H5wW/45uoGtZhwhpfYn/xpmdCzz9+L1nrjYdrvz86d5NOPvrqeBKdnjDltDbiBUivC7EPVz2a66LNJ98vzOnhPDUsDg61aTebgjTX70Xgyfmdg99x4NEPbvtSk7z5zMFV6Z+4G2gBx2wtj75bNicxUgzB+qmBzzzwNdeuvU8ta3kSH644fmo1v3DnxCdufnj0pFf43AO481Md2hyacVvfJyVx/2XDqfblD//wD/uJVa3E94ZmEsNRvH0mZ6wW1UQdtwd6R0wIv4t1AqEx0vpwPGYuYvuWw2Y6T1xexGNhJa2duvS1D2nN5+ExJoEPHggZp7WSsa90QfqmoXZZ5zsmMb6khzdjrMHGZp32jcSmD34VGZ91rdja8ReGGMvYw6t/Z+yTvvyBH/gB/wtSBIsy6UoxJINb8ME1rkHiqqQTnVpJNxHMh8aciXGe4iPNIcWYI5tED2ScB5me8DpuafEddA6IfIqmV+qwnk/H33F9yQlDATdGLIvB7zi2jO/oEM8ZVW37+8mR+vIJwJE+WchhiG3pQQ48dbtv12+3XIJaSXv1ciJY91DO7+DY45/NIBwUhJC6ICuycZRZhDMbIB0ffg9UYpuazZ+a9sNS9+rho2B4NNK734uJet6LZxwhh7/mZwu3P1BQW2z3SI17uJmkrsbvl9TmHCPUVEgvzq5zmLyVsWNl5mOs8zA3NZbMzb82EMeXKTwTyRFLOQcuFSlkxowiOz7Na8XulTlc1WvDEmf828vPfOYz81HYCeBXWGzzR82RLxfbOHkfGgNQW7w9KuDNIztff/V2T0ntFmNw4KP0ZcyOy1zKrQWPTs/U94JNLgfoPuThpqa10w8fDnPAl/Z/n8v19eHGwjGGBYdHEJk5v9KbDZuxBpfPwI6Dtx/iOGphDuVFES5P+xTzWhYX4SIVcwwHS1Du7Zd+6Zf4UwxvNb5c09i7wxgvX750jhhbDAuFF02S2L56uE/j5IzXCrbvlwS45MS35Q2Q8czp2NB5wcKhP9ZECYk9Xyz95OPCNcavM/B3zi8Pbca2TwEEH6n/HIbF9csh48bBMAlv0h5P82ONzdkmtWtdE25xL6rSmP1tTZWYl+wDMjiWmicwxEDHlXBQdvyYJOigxBtD8KvNYckn9jtEF7N9HGuxc4uJo2wSsHNY8I4l6zhibvs0pgdj1RZbfSmxCDOOFXc+BhlDsR/x4YzSi0b4SPulN7L9fgwMZ9nJpa9j/GUZp+fgsVH87IlrJPzUZU6xxP7+xL4F67h7LH80YkkiyYE7T1wNl57FXVtF1KLx/ijsf3Dx0e0XfuEX1Oc4ETWybSw+1iEvLP6KI8Idk09ukljcbYGPuTw8WSS2xBFj7IHUvbHgziaPdbRiBK6dA8OfnAGJA0nHTDhE8K6Vg8Nnj0jjk2d+q8SWl84XEAHr/iJQ4lrII/Ux8QfihTEH0DKBiCWDSw5AwjwiTcTMPzV3n+Am40hw53wA0ss9pDP2Whc0+37HUtAJ1C8uSwNSfpKgr/SUkBrfmhxPheuTx2+jxZsnjXjONwcPejHy9KSX4vZo3hYpjoVLHUqc/OQiM4aDY9yTADFX1kKcudoHp2fz26Lw4ntMuLqMx7vpkL7LK67ZqhrzWX97NydxLvMuH+snWBVOZHjB99Oqgu96xpYWQ6ZeCrb96uRuP//zP6/6o4Ma2m2sOfsd2ViLO07B53G8ayeQ3MtT377FiSeQtA/17H1xLG4tUHEs81Mv241j49ZHGp4s/8y788EyX82jczJvyIfFsIGT/xCb+QL03T44lhcs/BYlro80tL3uewRnSN2njhdeOazH4O7llxIl3aeEtrykJzLfsW4/93M/52YsFkljFzKRbMLR5ZBtX3z88cf1K5Onln7Hv9E/TbQbOYcZ3Acatxbxooh5wYLVdu4SgMF5QVJ7irFDXLYuL6y/Mbb7xBz1FHGeJHnWE359xjHW8SITu+mDuLa+lGbHbQuOlfD0cnzpPRaJP7WqGT8yj256kLr0st8a5XY91vPrXCS1xm8/+7M/Cx85ZrQsE2eD0GJt5EDCT4nYTqpcbXwHMpXD2H0mIblOrge3fwKtTdA+yPRkvliE+XCh2VDwnZPgI/aNSLLBJ9LV4vrlgmMj92omH785m+1H7PPCgeKzjshciBJx/XKI16s6LuCb7kE4w9t27T/yLk5x5jGXPDJlt5/5mZ/BGyAL8SYzQR3yjm2JKWhNLXksL0gHXXk79KAvhclNk90fSw19GyOdCxiwX4JjE2P8kZUY6bj2/RKRe+XunGWFYxMMcITnmthLaAfDdx7vjSxvKr5TNWcuL0gB3GixedfQC7cxEt+6YI/Dm5hxJaz/dGnX+TE/P4mclIBh18Vqzrz58o6IZD81+Cx6sPCO26M42HCC03hq0OD0ny/tUXO3ZAHOp69r7tROPTWtrZUc74hjvlb49GGdWGoTT29Zx5l/65xLn+IzfnMXv7EtGD0ztnFZzxFfOX+ZZh5w0Ui/FA+QGJyafsnuvGe8aPelNfWt4vaPx0ix+uanHnlUv5Q+zb+8/fRP/7Q/p6nFCrRokvWPUfK0QTSw+XCYRGNuf/Kl2fJSbuOI67B+udQhHMYVNCBhPPW1bdoJCcDGGvsl0vUWu1okPoaJ8jgofoCaP1YS+KEWMSARjwNDWBD+sTBJc3LbJOYQggpx1kz4JhcRjueHFcV/CE3p9ARvbfZVkLk0wz8NXA4viCAbemD9cqyDsYkpA35x+6mf+qm5WKAk8LkIEAxIenjlgcEJZssLn+n4kmOENdg+yOuk6Y8lJ6lrywvSOSFmSRIOmbl0joyBT9ov4TxlkYVNuLC7Fln+I+wpiyz/EVwAyzp0iWyzdwj5cp6K24en4RRKjEl9McLxnuGyj2uc47DSc1+sCOXuF/vi9pM/+ZMHO0Ctmp4gtF+mGRSLXC8gFpcN2JcFizh7iHsGMjcTPl0OA6tFHea342u+NkK/iamlv8S0cK/vutrdq+6CHmENYk7YxLEIzulgsYS8YAc4y0Py8D3/hTlgT9nb7hewX840W7gJeuEqrXFOPF/G4Ds39vYTP/ETdxPXC4P0okgGroPNpgy2+LuPefvisOim67S2G4NPjvS9S9cYG9fSDV1g3eLuv8dBIIFxIeGUt9K2CTAGs7bitvRBqGc+cCS79pFf2x640rmABsKv5YWPRsYBawJZ/rlo1d47c8nmIX0AADyAbRR7++IXv3gCahkEl03KZjmtSWMf8bE5iMEi9U8WSg8N6aIkxSYnGac1HQdJCnEYaJoQ+2VJLhw6hxVKrSVBEzbbj32OdxAkdWX302DX9qljmBfsjhOcnk6YHnahaMU1TUqGVyf1CHF57n2Yw4q3n1T4x7vkIMxe3r7whS8cFQewPyZOh93L1Xdt+Uh9bN6Nd/O414uJ1N+2fZDgMSPDpeeet+TEJUASIg43Vn9jCH2vWOONL/9RDmm88OXeS0/QhA+f/e8lKl5/CaXFHvGa4zsbdknjE2/X7rGX3Vzb2+c///kTUItwsdaTwZhiH2QHyGFOnoOwI6kPZ/m+NPSg6Fofe7w0kFATMYxSS4Akhzhs/1rqy481dwoiuCuue8pjtn+1CWJskfEXWJcXNqLztG0yaz+ID/xtd0+k3Fqb3ROJz1OGATx+dGrqZw692MYltcOX0OfN7cd//Mevl8cWjAb11XiaSOwzGF/ojaQu0kZ3L6dk8kzUyIOYt8jDjbXT+TTGdJwr3lB5z4U3Refd7ySp3dzpgaz1Y30IkQOM07qEpx4Sh7xceeuwTjXbl9zDbS8lu2a4lyfUXb/cWoS1c9aR96q7/diP/dhgfkmAPNVwc3oxwArvQ6FHcYT4emj1MT1w/OKIaiasU8MLfbHI9q9c7D7U+M6VQLw5zSE7rn+Hc8rf8bHo/t6DbH/zRja/foyfOoV42RcpXLRPpsqVY9n+6nOtQ09rqO9/YBZgFKx+5V5uxxImvHP+TXPxSg+SPLacWN65/DjrJ8kea/vw72G8ILrsGkYDSbDJI8Y3f/fYeOL6WNeVE4s4h74jjxjXFJig/zLvCUmcfeA6Dj6anv7tdseJIv2/UGFN/i28sNHI8QX3XIe94qPq5fGe0P7Wfqv5t8997nOnJwgWFwzhEU2M4BQf8JD5LgOcfsadlThxWBa+ayfuPOBEis+Tcz0hbZaPPDgbLPmCEXauDiJfLR9ZsW3CR/yncOQpnzff+t3iPFk2J9L4hG/ePZ89X2d1qpVsvk1829uP/uiPngBk+/c++2t4QTafS8AiK0yshycpzyUouT2GxLmTc4gvV3ut73abdyo5BQkDPcIjJ1/KEwBrMDkW1z/t+EVyj3f1y0HqPsXZvoV9lPKPBRmbJ8mVN1yJcWxylfE3Htcv+yzY74s0NxxJWx0vR3C7ffazn92ABZ8wh2h/4/XtRJxJjXQuEz42HBsHkklI8BvWwdTlJdK0pQHj7I3okw2MuUhM5aVzQ+I7qOEFWw7OrpGccnYOwfeCkadqIn2jGGwOUtYx5LWu9jg3Cogb60t1uBYoR+HDHB6cA+TjE3fXVZ7DbR1JAtxuP/RDP3RkwkC2LzmFl6fLk3UcLCGbi+zc9pFLPKE29FHNpg5RsvLvPNDG+/KBcciZrzlaK0/GKYBHDd9l+sSE0z6bl9D/Tp4AHul8dPXynJ42h/vY3xJ+5eo/enrtPttHiOFnv/qnmsrwIqc6zNVH6Ie9/eAP/mAJk0R2fPXXQTjGRziY+ogzi8chRYxvAQArN/AjosY+5VbazhPxu3J74su1PBUP2PjCeyBKsi6HwTAVKLaOJAWWPCpQz9O8/XLED++OQ3D7FDOWi15u3NMY20fMDXFyq27nbrfPfOYzRyaMyo7xG7JBmtTmOoeSa1w5BQr1Do5ruaQf4p3APe+hZeJrAvmQC4jP3IM5jgw3+Ue1fgm8fATn0UEgwa7yUHjObzzm+TfgdmOZxzyN1qWybF/CIZbby4jYnqmOp6/8qb19//d/fwtOFc/F+HmUV3YaeTbmksS1kOzBcvH2pZCcaiUOFvYo/wz/lHtEvMTIcxx8zduXBwk8csUusf0FPTgHtvN3c8gdLjJOPl0mlszZ3eNLto+c4vS6+5QrgNy+7/u+r4d6sNZg9clz2D18hGR95BRIejlWzZWCDECSS8W7CeG7CbWVFmOKgxEvcfxEfuqXTD7zvBvvfnYkce83W7J5O/8E94Q9E+/H93ACrdT5O/EpIbnEvizRynN8SzDX7vzte7/3e08Xq3InjjnDsc7vRdw7DIT4CsVamm89wiUDQ9514BUznuDEvcbIqc+uQRJ7E1c8smPczvVejDTlYMkdDnKQVw0+PXkT9ymE7Hpk1yy5xshg1x7Inb5Pcm7f8z3f89QTC5kAvJyLTB352NOBXmM7ku3GjuwnHgK3tZmvf8LqEw7pBSTPRsvC90VI6fFy+OXdfTJuuWL3YqB7fYo3rjQt3fPzm5MfclhXQWLWk8szfVoj2Vj9TgZo8pFrjJywa03C9+Xcbt/93d+98/a7QU3sfKyxbtjybfeTq2LSksatachL5cqpj3EQKa9yjyPxRy2HUzoXEbsxLBfWgUQxvg8/sU19ajn48HwhEM13Lmx5YPjguSRTt+V9sHfFyD1M8k7sqborfAV2fPuu7/qu2QAt9rQZGAcS4pV7suEW8KaymUfTCz2xufAa81Jx8iLvwnDT7xEW3/hT2JIG2H6/oeDKxWnOEq6x+BX7gqbPsu25+dfvVR7jHibB3zEC1dhaK7d7c9rv1OuARhwE27xTv9t3fud3ThUdJLPJiIGLmPUOXvKG4yfz8FPJFojw0HD3vMbSc2OR98Lk92M/iAXYY24c8Cksvq3kwbn0jS1+j3cueL7niVtR/orf4xVj8vZTduLew5DLGL3g93g2vNy+4zu+YwiXBpW7MCB4Nzpi7I7cxTeI2159slXKW/TKh+Btc5UBV97c68WS3OXG3uNeDxK5x6+z+ZN8Qnb+Efc9x7O8Az9hiPCN3Z3z7du//dsL2vByEfPRr9YlWvIh3MHvPPGM3ym7h0/w3+HLv/f0Qu71qFxzd0mSR3jGu36cVqbvejNsng//UrsvhA0vlQt25SKb/+hj/vZt3/ZtD8xz0k2yedfUyJOJp1N3ccD32bgtT3DfC9+Up/hIc9e5bf8i7+y1Bexd664syr0+8Sb37MVBnhizc7nHj/dkbvDbt37rt25Set6VT5T7REVK+eXDSwe8k3eNzvBuLvaam5oEtpErMZ7lnbkLVnmq7h55X8ba97lM8e72fLIOWeNV9nin3O2bv/mb55GO7O83dzb02niExuX18HZf4hKufYkZt3XFtlBLrpzFPQokiS2td1Gk7u698oAO79Xek+fyK+e+h3tIc5g9l8qqfSTP5ZBL/jT2B9ae5ENrb5/+9KdPF+upBsBPbXhzyz7q0Vx854vtHNL8c7I5da+9NucqST07zlP1wBmLPIM9N84nylWe4gC/zzqR/+k8cuXcvumbvula9En6nKSb/hSnG3J9St2RSVw5102912NxbBxI7nElJ/DK6ZoSWt7RZy7ctSz2JO/Bcb/Fw5kxtlw4T8pu9pSE8sF9bt/4jd/4CLxHBOpBVe7xrhLK8XKnx5an+l3rds/n5Kl+Vwnv7iFVnhuT3GV+7xz3fTjIE7y7c32fnu/DQf67vNs3fMM3TAJON4iCxlhk5d57I6+1yObjPtUX2dz3kaf4/5O978n7cqExrw/pjdzhNz4vUhIu+DvHuNP3WXmKf/v6r//6JxtdiwizCf/tQ4pMzQeUP5rTO+QR4R01d/ld9zOi9KN9eerXCMhdvD3ulD07eOVSt4NnL9aq+9Cau/nb133d1z1ZKFHtc+l3CsXPbe5TcuJ/YPld8nv2eESirpflHT1OyV1Xeab+vSZXufT5oFpk1X9wLZL6Z2tvX/u1X/uu5keXpzflfWSKP2Gfu0Uf2OtJ8gf02cR5N1O/LtEHP6Uk5xsY+QR9tpx6Xnq9T/09cU+1evzH3ovcPvWpTz07SOeTx/O7for7JPKo2Vep/3ut6wPlvYs+oP+HTGQuc+WJcT6k5ztljfHefW/877TH/yRyqv0qXYj3kfce6Ks8pyebMc71o++OzMX4gHl9VRfwnFzm9N8ad/67t6+GdGOvm6z4g8b4QPr/Sfm/bmKfYK/+j6xB53/+L2b+vzwtH/oG+X9XXrz433LUIQNpxx2DAAAAAElFTkSuQmCC"
		),
	})

	local saturationpicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = saturation,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(0, 2, 0, 2),
		ZIndex = 26,
		Visible = true,
	})

	Library:Outline(saturationpicker, Color3.fromRGB(0, 0, 0))

	local hueframe = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = colorpage,
		Size = UDim2.new(0, 15, 0, 150),
		Position = UDim2.new(0, 165, 0, 20),
		ZIndex = 24,
	})

	Library:Outline(hueframe, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 25,
		Parent = hueframe,
		Data = Decode(
			"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"
		),
	})

	local huepicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = hueframe,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 26,
		Visible = true,
	})

	Library:Outline(huepicker, Color3.fromRGB(0, 0, 0))

	local alphaframe = Library:Create("Square", {
		Filled = true,
		Thickness = 1,
		Size = UDim2.new(0, 15, 0, 150),
		Position = UDim2.new(1, -20, 0, 20),
		ZIndex = 26,
		Parent = colorpage,
	})

	Library:Outline(alphaframe, Color3.fromRGB(0, 0, 0))

	Library:Create("Image", {
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 26,
		Transparency = 1,
		Parent = alphaframe,
		Data = Decode(
			"iVBORw0KGgoAAAANSUhEUgAAAAkAAABuCAYAAAD1YDnyAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAFMSURBVFhHvZMhTMNQFEX/WOZwKBwON4dDNMHN4XBzc3M43BwOh8PhULip1s3hcLg53Nxcue9mIy/ty/8kDfcktzlpsv97xEZ1XacjVVUdLKWmaQ6W0slfNmrbdgIh/tf+1PCX3YUvu7MPP4WQQR8evuzO6s4gRFN3DiG5unFpvaOjWd0FhOTqwiv8ekdHs7pLCNHUTSFEU3cFIZq6awjR1N1AiKZuBiG5uuLsEX6Hn9XdQkiurjh7hFf4Wd0dhGjq5hCiqVtAiKZuCSGaunsI0dQ9QMjguuKsbgUhg+uKs7pHCNHUPUGIpu4ZQjR1LxCiqXuFEE3dG4Ro6t4hJFcX/mv9ekdHs7o1hOTqwiv8ekdHs7rfOzR1GwjR1H1AiKbuE0I0dV8QoqnbQkiurjh7hN/hZ3XfEJKrK84e4RV+VreDEE3dHkL+uy6NfwDz0OfO0eCa+AAAAABJRU5ErkJggg=="
		),
	})

	local alphapicker = Library:Create("Square", {
		Filled = true,
		Thickness = 0,
		Parent = alphaframe,
		Color = Color3.fromRGB(255, 255, 255),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 27,
		Visible = true,
	})

	Library:Outline(alphapicker, Color3.fromRGB(0, 0, 0))

	local rgbinput = Library:Create("Square", {
		Filled = true,
		Transparency = 1,
		Thickness = 1,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(1, -12, 0, 14),
		Position = UDim2.new(0, 6, 0, 180),
		ZIndex = 24,
		Parent = colorpage,
	})

	local outline2 = Library:Outline(rgbinput, Color3.fromRGB(50, 50, 50))
	Library:Outline(outline2, Color3.fromRGB(0, 0, 0))

	local text = Library:Create("Text", {
		Text = string.format(
			"%s, %s, %s",
			math.floor(default.R * 255),
			math.floor(default.G * 255),
			math.floor(default.B * 255)
		),
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 0, 0, 0),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = true,
		Parent = rgbinput,
	})

	local color_button = Library:Create("Square", {
		Parent = window,
		Size = UDim2.new(0.5, -1, 0, 14),
		Color = Color3.fromRGB(13, 13, 13),
		Thickness = 1,
		Filled = true,
		ZIndex = 21,
	})
	local color_outline = Library:Outline(color_button, Color3.new(0, 0, 0), 20)
	color_outline.Visible = false
	local color_text = Library:Create("Text", {
		Text = "color",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 0, 0, 0),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = color_button,
	})

	local animation_button = Library:Create("Square", {
		Parent = window,
		Size = UDim2.new(0.5, -1, 0, 14),
		Position = UDim2.new(0.5, 1, 0, 0),
		Color = Color3.fromRGB(19, 19, 19),
		Thickness = 1,
		Filled = true,
		ZIndex = 21,
	})
	local animation_outline = Library:Outline(animation_button, Color3.new(0, 0, 0), 20)
	local animation_text = Library:Create("Text", {
		Text = "animation",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 0, 0, 0),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animation_button,
	})

	local animation_rainbow = Library:Create("Text", {
		Text = "rainbow",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, -Utility.TextLength("rainbow", 2, 13).X - 17, 0.5, -60),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})
	Library:Create("Text", {
		Text = "/",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, -25, 0.5, -60),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})
	local animation_lerp = Library:Create("Text", {
		Text = "lerp",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, Utility.TextLength("lerp", 2, 13).X - 42, 0.5, -62),
		Center = false,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})
	Library:Create("Text", {
		Text = "/",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 28, 0.5, -60),
		Center = true,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})
	local animation_fade = Library:Create("Text", {
		Text = "fade",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, Utility.TextLength("fade", 2, 13).X + 17, 0.5, -62),
		Center = false,
		Theme = "Text",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})
	local animation_disabled = Library:Create("Text", {
		Text = "disabled",
		Font = Drawing.Fonts.Plex,
		Size = 13,
		Position = UDim2.new(0.5, 0, 0.5, -80),
		Center = true,
		Theme = "Accent",
		ZIndex = 26,
		Outline = false,
		Parent = animationpage,
	})

	local rainbow_page = Library:Create("Square", {
		Filled = false,
		Thickness = 0,
		Transparency = 0,
		Parent = animationpage,
		Color = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -10, 0, 100),
		Position = UDim2.new(0, 5, 0, 60),
		Visible = false,
		ZIndex = 28,
	})
	rainbow_page:AddListLayout(3)

	local lerp_page = Library:Create("Square", {
		Filled = false,
		Thickness = 0,
		Transparency = 0,
		Parent = animationpage,
		Color = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -10, 0, 100),
		Position = UDim2.new(0, 5, 0, 60),
		Visible = false,
		ZIndex = 28,
	})
	lerp_page:AddListLayout(3)

	local fade_page = Library:Create("Square", {
		Filled = false,
		Thickness = 0,
		Transparency = 0,
		Parent = animationpage,
		Color = Color3.fromRGB(0, 0, 0),
		Size = UDim2.new(1, -10, 0, 100),
		Position = UDim2.new(0, 5, 0, 60),
		Visible = false,
		ZIndex = 28,
	})
	fade_page:AddListLayout(3)

	local startslide = Library.CreateSlider({
		parent = fade_page,
		name = "min",
		flag = flag .. "_FADING_MIN",
		min = 0,
		max = 1,
		default = 0,
		float = 0.01,
		callback = function(state)
			Library.Flags[flag .. "_FADING_MIN"] = state
		end,
	})
	local endslide = Library.CreateSlider({
		parent = fade_page,
		name = "max",
		flag = flag .. "_FADING_MAX",
		min = 0,
		max = 1,
		default = 1,
		float = 0.01,
		callback = function(state)
			Library.Flags[flag .. "_FADING_MAX"] = state
		end,
	})
	local speedslide = Library.CreateSlider({
		parent = fade_page,
		name = "speed",
		flag = flag .. "_FADING_SPEED",
		min = 0,
		max = 500,
		default = 100,
		callback = function(state)
			Library.Flags[flag .. "_FADING_SPEED"] = state
		end,
	})

	local rainbowslider = Library.CreateSlider({
		parent = rainbow_page,
		name = "speed",
		flag = flag .. "_RAINBOW_SPEED",
		min = 0,
		max = 100,
		default = 10,
		callback = function(state)
			Library.Flags[flag .. "_RAINBOW_SPEED"] = state
		end,
	})
	local lerpslider = Library.CreateSlider({
		parent = lerp_page,
		name = "speed",
		flag = flag .. "_LERP_SPEED",
		min = 0,
		max = 100,
		default = 10,
		callback = function(state)
			Library.Flags[flag .. "_LERP_SPEED"] = state
		end,
	})

	local lerpstart = Library.CreatePicker({
		parent = lerp_page,
		name = "start color",
		flag = flag .. "_LERP_START",
		default = Color3.new(1, 1, 1),
		callback = function(state)
			Library.Flags[flag .. "_LERP_START"] = state
		end,
	})
	local lerpend = Library.CreatePicker({
		parent = lerp_page,
		name = "end color",
		flag = flag .. "_LERP_END",
		default = Color3.new(0, 0, 0),
		callback = function(state)
			Library.Flags[flag .. "_LERP_END"] = state
		end,
	})

	local rainbow_button = Library:Create("Square", {
		Parent = animationpage,
		Size = UDim2.new(0, Utility.TextLength("rainbow", 2, 13).X, 0, Utility.TextLength("rainbow", 2, 13).Y + 2),
		Position = UDim2.new(0.5, -Utility.TextLength("rainbow", 2, 13).X - 41, 0.5, -62),
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1,
		Transparency = 0,
		Filled = false,
		ZIndex = 21,
	})
	local lerp_button = Library:Create("Square", {
		Parent = animationpage,
		Size = UDim2.new(0, Utility.TextLength("lerp", 2, 13).X, 0, Utility.TextLength("lerp", 2, 13).Y + 2),
		Position = UDim2.new(0.5, Utility.TextLength("lerp", 2, 13).X - 42, 0.5, -62),
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1,
		Transparency = 0,
		Filled = false,
		ZIndex = 21,
	})
	local fade_button = Library:Create("Square", {
		Parent = animationpage,
		Size = UDim2.new(0, Utility.TextLength("fade", 2, 13).X, 0, Utility.TextLength("fade", 2, 13).Y + 2),
		Position = UDim2.new(0.5, Utility.TextLength("fade", 2, 13).X + 17, 0.5, -62),
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1,
		Transparency = 0,
		Filled = false,
		ZIndex = 21,
	})
	local disable_button = Library:Create("Square", {
		Parent = animationpage,
		Size = UDim2.new(0, Utility.TextLength("disabled", 2, 13).X, 0, Utility.TextLength("disabled", 2, 13).Y + 2),
		Position = UDim2.new(0.5, -26, 0.5, -82),
		Color = Color3.fromRGB(0, 0, 0),
		Thickness = 1,
		Transparency = 0,
		Filled = false,
		ZIndex = 21,
	})

	local mouseover = false

	local hue, sat, val = default:ToHSV()
	local hsv = default:ToHSV()
	local alpha = defaultalpha
	local oldcolor = hsv
	local toggled = false
	local lerptoggled = false
	local fadetoggled = false

	local function set(color, a, nopos, setcolor)
		if type(color) == "table" then
			a = color.alpha
			color = Color3.fromHex(color.color)
		end

		if type(color) == "string" then
			color = Color3.fromHex(color)
		end

		local oldcolor = hsv
		local oldalpha = alpha

		hue, sat, val = color:ToHSV()
		alpha = a or 1
		hsv = Color3.fromHSV(hue, sat, val)

		if hsv ~= oldcolor or alpha ~= oldalpha then
			icon.Color = hsv
			alphaframe.Color = hsv

			if not nopos then
				saturationpicker.Position = UDim2.new(
					0,
					(math.clamp(sat * saturation.AbsoluteSize.X, 0, saturation.AbsoluteSize.X - 2)),
					0,
					(math.clamp((1 - val) * saturation.AbsoluteSize.Y, 0, saturation.AbsoluteSize.Y - 2))
				)
				huepicker.Position =
					UDim2.new(0, 0, 0, math.clamp(hue * hueframe.AbsoluteSize.X, 0, hueframe.AbsoluteSize.X - 2))
				alphapicker.Position = UDim2.new(
					0,
					0,
					0,
					math.clamp((1 - alpha) * alphaframe.AbsoluteSize.Y, 0, alphaframe.AbsoluteSize.Y - 2)
				)
				if setcolor then
					saturation.Color = hsv
				end
			end

			text.Text =
				string.format("%s, %s, %s", math.round(hsv.R * 255), math.round(hsv.G * 255), math.round(hsv.B * 255))

			if flag then
				Library.Flags[flag] = Utility.rgba(hsv.r * 255, hsv.g * 255, hsv.b * 255, alpha)
			end

			callback(Utility.rgba(hsv.r * 255, hsv.g * 255, hsv.b * 255, alpha))
		end
	end
	local function setstate(state)
		toggled = state
		Library.Flags[flag .. "_RAINBOW"] = toggled
	end
	local function setlerpstate(state)
		lerptoggled = state
		Library.Flags[flag .. "_LERP"] = lerptoggled
	end
	local function setfadestate(state)
		fadetoggled = state
		Library.Flags[flag .. "_FADE"] = fadetoggled
	end
	rainbow_button.MouseButton1Click:Connect(function()
		Library:ChangeObjectTheme(animation_rainbow, "Accent")
		Library:ChangeObjectTheme(animation_lerp, "Text")
		Library:ChangeObjectTheme(animation_fade, "Text")
		Library:ChangeObjectTheme(animation_disabled, "Text")
		setstate(true)
		setlerpstate(false)
		setfadestate(false)
		fade_page.Visible = false
		rainbow_page.Visible = true
		lerp_page.Visible = false
	end)
	lerp_button.MouseButton1Click:Connect(function()
		Library:ChangeObjectTheme(animation_lerp, "Accent")
		Library:ChangeObjectTheme(animation_rainbow, "Text")
		Library:ChangeObjectTheme(animation_fade, "Text")
		Library:ChangeObjectTheme(animation_disabled, "Text")
		setstate(false)
		setlerpstate(true)
		setfadestate(false)
		fade_page.Visible = false
		rainbow_page.Visible = false
		lerp_page.Visible = true
	end)
	fade_button.MouseButton1Click:Connect(function()
		Library:ChangeObjectTheme(animation_lerp, "Text")
		Library:ChangeObjectTheme(animation_rainbow, "Text")
		Library:ChangeObjectTheme(animation_fade, "Accent")
		Library:ChangeObjectTheme(animation_disabled, "Text")
		setstate(false)
		setlerpstate(false)
		setfadestate(true)
		rainbow_page.Visible = false
		fade_page.Visible = true
		lerp_page.Visible = false
	end)
	disable_button.MouseButton1Click:Connect(function()
		Library:ChangeObjectTheme(animation_lerp, "Text")
		Library:ChangeObjectTheme(animation_rainbow, "Text")
		Library:ChangeObjectTheme(animation_fade, "Text")
		Library:ChangeObjectTheme(animation_disabled, "Accent")
		setstate(false)
		setlerpstate(false)
		setfadestate(false)
		fade_page.Visible = false
		rainbow_page.Visible = false
		lerp_page.Visible = false
	end)
	setstate(toggle_state)
	Flags[flag .. "_RAINBOW"] = setstate
	Flags[flag .. "_LERP"] = setlerpstate
	Flags[flag .. "_FADE"] = setfadestate

	Flags[flag] = set

	set(default, defaultalpha)

	local defhue, _, _ = default:ToHSV()

	local curhuesizey = defhue

	local function updatesatval(input, set_callback)
		local sizeX = math.clamp((input.Position.X - saturation.AbsolutePosition.X) / saturation.AbsoluteSize.X, 0, 1)
		local sizeY = 1
			- math.clamp(((input.Position.Y - saturation.AbsolutePosition.Y) + 36) / saturation.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - saturation.AbsolutePosition.Y) / saturation.AbsoluteSize.Y) * saturation.AbsoluteSize.Y
				+ 36,
			0,
			saturation.AbsoluteSize.Y - 2
		)
		local posX = math.clamp(
			((input.Position.X - saturation.AbsolutePosition.X) / saturation.AbsoluteSize.X) * saturation.AbsoluteSize.X,
			0,
			saturation.AbsoluteSize.X - 2
		)

		saturationpicker.Position = UDim2.new(0, posX, 0, posY)

		if set_callback then
			set(Color3.fromHSV(curhuesizey or hue, sizeX, sizeY), alpha or defaultalpha, true, false)
		end
	end

	local slidingsaturation = false

	saturation.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingsaturation = true
			updatesatval(input)
		end
	end)

	saturation.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingsaturation = false
			updatesatval(input, true)
		end
	end)

	local slidinghue = false

	local function updatehue(input, set_callback)
		local sizeY = 1
			- math.clamp(((input.Position.Y - hueframe.AbsolutePosition.Y) + 36) / hueframe.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - hueframe.AbsolutePosition.Y) / hueframe.AbsoluteSize.Y) * hueframe.AbsoluteSize.Y + 36,
			0,
			hueframe.AbsoluteSize.Y - 2
		)

		huepicker.Position = UDim2.new(0, 0, 0, posY)
		saturation.Color = Color3.fromHSV(sizeY, 1, 1)
		curhuesizey = sizeY
		if set_callback then
			set(Color3.fromHSV(sizeY, sat, val), alpha or defaultalpha, true, true)
		end
	end

	hueframe.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidinghue = true
			updatehue(input)
		end
	end)

	hueframe.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidinghue = false
			updatehue(input, true)
		end
	end)

	local slidingalpha = false

	local function updatealpha(input, set_callback)
		local sizeY = 1
			- math.clamp(((input.Position.Y - alphaframe.AbsolutePosition.Y) + 36) / alphaframe.AbsoluteSize.Y, 0, 1)
		local posY = math.clamp(
			((input.Position.Y - alphaframe.AbsolutePosition.Y) / alphaframe.AbsoluteSize.Y) * alphaframe.AbsoluteSize.Y
				+ 36,
			0,
			alphaframe.AbsoluteSize.Y - 2
		)

		alphapicker.Position = UDim2.new(0, 0, 0, posY)
		if set_callback then
			set(Color3.fromHSV(curhuesizey, sat, val), sizeY, true)
		end
	end

	alphaframe.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingalpha = true
			updatealpha(input)
		end
	end)

	alphaframe.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			slidingalpha = false
			updatealpha(input, true)
		end
	end)

	Library:Connect(InputService.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if slidingalpha then
				updatealpha(input)
			end

			if slidinghue then
				updatehue(input)
			end

			if slidingsaturation then
				updatesatval(input)
			end
		end
	end)

	color_button.MouseButton1Click:Connect(function()
		colorpage.Visible = true
		color_button.Color = Color3.fromRGB(13, 13, 13)
		color_outline.Visible = false

		animationpage.Visible = false
		animation_button.Color = Color3.fromRGB(19, 19, 19)
		animation_outline.Visible = true
	end)

	animation_button.MouseButton1Click:Connect(function()
		colorpage.Visible = false
		color_button.Color = Color3.fromRGB(19, 19, 19)
		color_outline.Visible = true

		animationpage.Visible = true
		animation_button.Color = Color3.fromRGB(13, 13, 13)
		animation_outline.Visible = false
	end)

	icon.MouseButton1Click:Connect(function()
		for _, picker in next, Pickers do
			if picker ~= window then
				picker.Visible = false
			end
		end

		window.Visible = not window.Visible

		if slidinghue then
			slidinghue = false
		end

		if slidingsaturation then
			slidingsaturation = false
		end

		if slidingalpha then
			slidingalpha = false
		end
	end)

	local colorpickertypes = {}

	function colorpickertypes:set(color, alpha)
		set(color)
		updatealpha(alpha)
	end

	local function lerp(start, stop, t)
		return start + (stop - start) * t
	end

	local time = 0

	task.spawn(function()
		while task.wait() do
			if Library.Flags[flag .. "_RAINBOW"] then
				local Clock = os.clock() * Library.Flags[flag .. "_RAINBOW_SPEED"] / 80
				local Color = Color3.fromHSV(math.abs(math.sin(Clock)), 1, 1)
				set(Color, Library.Flags[flag].a, false, true)
			end
			if Library.Flags[flag .. "_LERP"] then
				local progress = (math.sin(2 * math.pi * (Library.Flags[flag .. "_LERP_SPEED"] / 10) * time) + 1) / 2
				local value = Library.Flags[flag .. "_LERP_START"]:Lerp(Library.Flags[flag .. "_LERP_END"], progress)

				set(value, Library.Flags[flag].a, false, true)

				time = time + 0.01
			end
			if Library.Flags[flag .. "_FADE"] then
				local sinwave = math.abs(math.sin(os.clock() * (Library.Flags[flag .. "_FADING_SPEED"] / 50)))

				local val = Utility.NumberLerp(sinwave, {
					[1] = {
						start = 0,
						number = Library.Flags[flag .. "_FADING_MIN"],
					},
					[2] = {
						start = 1,
						number = Library.Flags[flag .. "_FADING_MAX"],
					},
				})
				set(Library.Flags[flag], val, false, true)
			end
		end
	end)

	return colorpickertypes, window
end

function Library.ObjectTextbox(box, text, callback, finishedcallback)
	box.MouseButton1Click:Connect(function()
		ContextActionService:BindActionAtPriority("disablekeyboard", function()
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.UserInputType.Keyboard)

		local connection
		local backspaceconnection

		local keyqueue = 0

		if not connection then
			connection = Library:Connect(InputService.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode ~= Enum.KeyCode.Backspace then
						local str = InputService:GetStringForKeyCode(input.KeyCode)
						if table.find(AllowedCharacters, str) then
							keyqueue = keyqueue + 1
							local currentqueue = keyqueue

							if
								not InputService:IsKeyDown(Enum.KeyCode.RightShift)
								and not InputService:IsKeyDown(Enum.KeyCode.LeftShift)
							then
								text.Text = text.Text .. str:lower()
								callback(text.Text)

								local ended = false

								task.spawn(function()
									task.wait(0.5)

									while InputService:IsKeyDown(input.KeyCode) and currentqueue == keyqueue do
										text.Text = text.Text .. str:lower()
										callback(text.Text)

										task.wait(0.02)
									end
								end)
							else
								text.Text = text.Text .. (ShiftCharacters[str] or str:upper())
								callback(text.Text)

								task.spawn(function()
									task.wait(0.5)

									while InputService:IsKeyDown(input.KeyCode) and currentqueue == keyqueue do
										text.Text = text.Text .. (ShiftCharacters[str] or str:upper())
										callback(text.Text)

										task.wait(0.02)
									end
								end)
							end
						end
					end

					if input.KeyCode == Enum.KeyCode.Return then
						ContextActionService:UnbindAction("disablekeyboard")
						Library:Disconnect(backspaceconnection)
						Library:Disconnect(connection)
						finishedcallback(text.Text)
					end
				elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
					ContextActionService:UnbindAction("disablekeyboard")
					Library:Disconnect(backspaceconnection)
					Library:Disconnect(connection)
					finishedcallback(text.Text)
				end
			end)

			local backspacequeue = 0

			backspaceconnection = Library:Connect(InputService.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Backspace then
					backspacequeue = backspacequeue + 1

					text.Text = text.Text:sub(1, -2)
					callback(text.Text)

					local currentqueue = backspacequeue

					task.spawn(function()
						task.wait(0.5)

						if backspacequeue == currentqueue then
							while InputService:IsKeyDown(Enum.KeyCode.Backspace) do
								text.Text = text.Text:sub(1, -2)
								callback(text.Text)

								task.wait(0.02)
							end
						end
					end)
				end
			end)
		end
	end)
end

function Library:new(cfg)
	local window = { objs = {}, pages = {}, pages_buttons = {}, pages_titles = {}, pages_buttons_lines = {} }
	local name_white = cfg.name or cfg.Name or "Title"
	local name_color = cfg.sub or cfg.Sub or "Hook"
	local offset = cfg.offset or cfg.offset or 0
	local size = cfg.size or cfg.Size or Vector2.new(600, 650)

	local window_outline = Library:Create("Square", {
		Visible = false,
		Transparency = 1,
		Color = Color3.fromRGB(12, 12, 12),
		Size = UDim2.new(0, size.X, 0, size.Y),
		Position = UDim2.new(0.5, -(size.X / 2), 0.5, -(size.Y / 2)),
		Thickness = 1,
		Filled = true,
		ZIndex = 10,
	})
	do
		local outline = Library:Outline(window_outline, Color3.fromRGB(50, 50, 50), 10)
		Library:Outline(outline, Color3.new(0, 0, 0), 10)
	end

	Library.Holder = window_outline

	local window_inline = Library:Create("Square", {
		Parent = window_outline,
		Visible = true,
		Transparency = 0,
		Color = Color3.fromRGB(12, 12, 12),
		Size = UDim2.new(1, -10, 1, -10),
		Position = UDim2.new(0, 5, 0, 5),
		Thickness = 1,
		Filled = true,
		ZIndex = 11,
	})

	local window_accent = Library:Create("Square", {
		Parent = window_inline,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = UDim2.new(1, -15, 0, 2),
		Position = UDim2.new(0, 7, 0, 21),
		Thickness = 1,
		Filled = true,
		ZIndex = 11,
	})
	Library:Outline(window_accent, Color3.new(0, 0, 0), 11)
	Library:Create("Image", {
		Data = Images.gradient,
		Transparency = 1,
		Visible = true,
		Parent = window_accent,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 11,
	})

	local window_holder = Library:Create("Square", {
		Parent = window_inline,
		Visible = true,
		Transparency = 1,
		Color = Color3.fromRGB(13, 13, 13),
		Size = UDim2.new(1, -15, 1, -90),
		Position = UDim2.new(0, 7, 0, 82),
		Thickness = 1,
		Filled = true,
		ZIndex = 12,
	})
	do
		local outline = Library:Outline(window_holder, Color3.fromRGB(50, 50, 50), 12)
		Library:Outline(outline, Color3.fromRGB(0, 0, 0), 12)
	end

	local window_page_holder = Library:Create("Square", {
		Parent = window_inline,
		Visible = true,
		Transparency = 0,
		Color = Color3.fromRGB(50, 50, 50),
		Size = UDim2.new(1, -6, 0, 35),
		Position = UDim2.new(0, 3, 0, 34),
		Thickness = 1,
		Filled = true,
		ZIndex = 12,
	})

	local window_page_holder_inline = Library:Create("Square", {
		Parent = window_page_holder,
		Visible = true,
		Transparency = 0,
		Size = UDim2.new(1, -7, 1, -4),
		Position = UDim2.new(0, 3, 0, 2),
		Thickness = 1,
		Filled = true,
		ZIndex = 12,
	})

	local window_drag = Library:Create("Square", {
		Parent = window_outline,
		Visible = true,
		Transparency = 0,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		Thickness = 1,
		Filled = true,
		ZIndex = 50,
	})

	local dragoutline = Library:Create("Square", {
		Size = UDim2.new(0, size.X, 0, size.Y),
		Position = Utility.GetCenter(size.X, size.Y),
		Filled = false,
		Thickness = 1,
		Theme = "Accent",
		ZIndex = 100,
		Visible = false,
	})

	local window_title = Library:Create("Text", {
		Text = name_white,
		Parent = window_outline,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = 13,
		Center = false,
		Outline = false,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(0, 10, 0, 7),
		ZIndex = 13,
	})
	local window_title_accent = Library:Create("Text", {
		Text = name_color,
		Parent = window_outline,
		Visible = true,
		Transparency = 1,
		Theme = "Text",
		Size = 13,
		Center = false,
		Outline = false,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(0, Utility.TextLength(name_white, 2, 13).X + 10, 0, 7),
		ZIndex = 13,
	})

	Utility.Dragify(window_drag, dragoutline, window_outline)
	function window.unload() end

	function window:page(cfg)
		local page = {}
		local name = cfg.name or cfg.Name or "Page"
		local default = cfg.default or cfg.Default or false

		local button_holder = Library:Create("Square", {
			Parent = window_page_holder_inline,
			Visible = true,
			Transparency = 1,
			Thickness = 1,
			Filled = true,
			ZIndex = 13,
		})

		table.insert(self.pages_buttons, button_holder)
		local button_inline = Library:Create("Square", {
			Parent = button_holder,
			Visible = true,
			Transparency = 1,
			Thickness = 1,
			Filled = true,
			ZIndex = 13,
			Color = Color3.fromRGB(41, 41, 41),
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
		})
		local button_inline_gradient = Library:Create("Square", {
			Parent = button_inline,
			Visible = true,
			Transparency = 1,
			Thickness = 1,
			Filled = true,
			ZIndex = 13,
			Color = Color3.fromRGB(41, 41, 41),
			Size = UDim2.new(1, -2, 1, -2),
			Position = UDim2.new(0, 1, 0, 1),
		})
		Library:Create("Image", {
			Data = Images.gradient,
			Transparency = 1,
			Visible = true,
			Parent = button_inline_gradient,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 13,
		})

		local button_title = Library:Create("Text", {
			Text = name,
			Parent = button_holder,
			Visible = true,
			Transparency = 1,
			Theme = "Text",
			Size = 13,
			Center = true,
			Outline = true,
			Font = Drawing.Fonts.Plex,
			Position = UDim2.new(0.5, 0, 0, 9),
			ZIndex = 13,
		})
		table.insert(self.pages_titles, button_title)

		local page_holder = Library:Create("Square", {
			Parent = window_holder,
			Visible = false,
			Transparency = 0,
			Size = UDim2.new(1, -40, 1, -40),
			Position = UDim2.new(0, 20, 0, 20),
			Thickness = 1,
			Filled = false,
			ZIndex = 13,
		})
		do
			table.insert(self.pages, page_holder)
		end

		local left = Library:Create("Square", {
			Transparency = 0,
			Filled = false,
			Thickness = 1,
			ZIndex = 13,
			Parent = page_holder,
			Size = UDim2.new(0.5, -14, 1, -10),
		})
		left:AddListLayout(15)
		local right = Library:Create("Square", {
			Transparency = 0,
			Filled = false,
			Thickness = 1,
			Parent = page_holder,
			ZIndex = 13,
			Size = UDim2.new(0.5, -14, 1, -10),
			Position = UDim2.new(0.5, 14, 0, 0),
		})
		right:AddListLayout(15)

		local pos = 0
		for _, v in next, self.pages_buttons do
			v.Size = UDim2.new(0, (window_page_holder_inline.AbsoluteSize.X / #self.pages_buttons), 1, 0)
			v.Position = UDim2.new(0, (_ - 1) * v.AbsoluteSize.X - 1, 0, 0)
		end

		if default then
			Library:ChangeObjectTheme(button_title, "Accent")
			page_holder.Visible = true
		end

		Library:Connect(button_holder.MouseButton1Click, function()
			for _, v in next, self.pages_titles do
				if v ~= button_tbl then
					Library:ChangeObjectTheme(v, "Text")
				end
			end

			for _, v in next, self.pages do
				if v ~= page_holder then
					v.Visible = false
				end
			end
			Library:ChangeObjectTheme(button_title, "Accent")
			page_holder.Visible = true
		end)

		function page:player_list(cfg)
			local playerlist = {}
			local max = 8
			local count = 0
			local startindex = 0
			local selected_plr = nil
			local last_plr = nil

			local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
			local players = Players

			local list_holder = Library:Create("Square", {
				Parent = page_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(19, 19, 19),
				Size = UDim2.new(1, 0, 0, ((max * 22) + 4) + 60 + 22),
				Position = UDim2.new(0, 0, 0, 0),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(list_holder, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			Library:Create("Square", {
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Accent",
				Size = UDim2.new(1, -2, 0, 2),
				Position = UDim2.new(0, 1, 0, 1),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})

			local list_title = Library:Create("Text", {
				Text = "player list - 0 player(s)",
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Text",
				Size = 13,
				Center = false,
				Outline = false,
				Font = Drawing.Fonts.Plex,
				Position = UDim2.new(0, 3, 0, 3),
				ZIndex = 14,
			})

			local list_inline = Library:Create("Square", {
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(13, 13, 13),
				Size = UDim2.new(1, -10, 0, (max * 20)),
				Position = UDim2.new(0, 5, 0, 22),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(list_inline, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local list_icon = Library:Create("Square", {
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(13, 13, 13),
				Size = UDim2.new(0, 60, 0, 60),
				Position = UDim2.new(0, 5, 1, -65),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(list_icon, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local player_data = Library:Create("Text", {
				Text = "no player selected.",
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Text",
				Size = 13,
				Center = false,
				Outline = false,
				Font = Drawing.Fonts.Plex,
				Position = UDim2.new(0, 70, 1, -67),
				ZIndex = 14,
			})

			local player_image = Library:Create("Image", {
				Size = UDim2.new(1, 0, 1, 0),
				Visible = true,
				ZIndex = 18,
				Parent = list_icon,
				Data = nil,
			})

			local list_content = Library:Create("Square", {
				Transparency = 0,
				Size = UDim2.new(1, -4, 1, -4),
				Position = UDim2.new(0, 2, 0, 3),
				Parent = list_inline,
			})

			local PriorityFrame = Library:Create("Square", {
				Filled = true,
				Visible = true,
				Thickness = 0,
				Color = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0, 100, 0, 17),
				Position = UDim2.new(1, -110, 1, -55),
				ZIndex = 14,
				Parent = list_holder,
			})

			PriorityFrame.MouseEnter:Connect(function()
				PriorityFrame.Color = Color3.fromRGB(27, 27, 27)
			end)

			PriorityFrame.MouseLeave:Connect(function()
				PriorityFrame.Color = Color3.fromRGB(25, 25, 25)
			end)

			local outline1 = Library:Outline(PriorityFrame, Color3.fromRGB(44, 44, 44), 14)
			Library:Outline(outline1, Color3.new(0, 0, 0), 14)

			local icon = Library:Create("Text", {
				Text = "priority",
				Transparency = 1,
				Visible = true,
				Parent = PriorityFrame,
				Theme = "Text",
				ZIndex = 16,
				Center = true,
				Position = UDim2.new(0.5, 0, 0, 1),
				Font = 2,
				Size = 13,
				Outline = true,
			})

			local FriendFrame = Library:Create("Square", {
				Filled = true,
				Visible = true,
				Thickness = 0,
				Color = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0, 100, 0, 17),
				Position = UDim2.new(1, -110, 1, -25),
				ZIndex = 14,
				Parent = list_holder,
			})

			FriendFrame.MouseEnter:Connect(function()
				FriendFrame.Color = Color3.fromRGB(27, 27, 27)
			end)

			FriendFrame.MouseLeave:Connect(function()
				FriendFrame.Color = Color3.fromRGB(25, 25, 25)
			end)

			local outline2 = Library:Outline(FriendFrame, Color3.fromRGB(44, 44, 44), 14)
			Library:Outline(outline2, Color3.new(0, 0, 0), 14)

			local friendicon = Library:Create("Text", {
				Text = "friendly",
				Transparency = 1,
				Visible = true,
				Parent = FriendFrame,
				Theme = "Text",
				ZIndex = 16,
				Center = true,
				Position = UDim2.new(0.5, 0, 0, 1),
				Font = 2,
				Size = 13,
				Outline = true,
			})
			list_content:AddListLayout(3)

			list_content:MakeScrollable()
			local scroll_connect = nil

			local scrollbar_outline = Library:Create("Square", {
				Transparency = 1,
				Size = UDim2.new(0, 6, 1, 0),
				Position = UDim2.new(1, -6, 0, 0),
				Parent = list_inline,
				ZIndex = 15,
				Thickness = 1,
				Color = Color3.fromRGB(45, 45, 45),
				Filled = true,
			})

			local scrollbar = Library:Create("Square", {
				Transparency = 1,
				Size = UDim2.new(0, 5, count == 0 and 1 or count / max, 0),
				Position = UDim2.new(1, -3, 0, 0),
				Parent = list_inline,
				ZIndex = 16,
				Thickness = 1,
				Color = Color3.fromRGB(65, 65, 65),
				Filled = true,
			})

			local function refreshscroll()
				local scale = startindex / (count > 0 and count or 1)
				scrollbar.Position = UDim2.new(1, -5, scale, 0)
				scrollbar.Size = UDim2.new(0, 5, math.clamp(count == 0 and 1 or 1 / (count / max), 0, 1), 0)
			end

			local function refreshfix()
				list_content.Visible = list_content.Visible
			end

			list_content.MouseEnter:Connect(function()
				scroll_connect = Library:Connect(InputService.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseWheel then
						local down = input.Position.Z < 0 and true or false
						if down then
							local indexesleft = count - max - startindex
							if indexesleft >= 0 then
								startindex = math.clamp(startindex + 1, 0, count - max)
								refreshscroll()
							end
						else
							local indexesleft = count - max + startindex
							if indexesleft >= count - max then
								startindex = math.clamp(startindex - 1, 0, count - max)
								refreshscroll()
							end
						end
					end
				end)
			end)

			list_content.MouseLeave:Connect(function()
				if scroll_connect then
					Library:Disconnect(scroll_connect)
				end
			end)
			refreshscroll()

			local chosen = nil
			local optioninstances = {}
			local function handleoptionclick(option, button)
				button.MouseButton1Click:Connect(function()
					chosen = option
					Library.Flags[flag] = option
					selected_plr = option

					if selected_plr ~= last_plr then
						last_plr = selected_plr
						player_data.Text = ("name : %s (@%s)\nid : %s\naccount age : %s"):format(
							selected_plr.Name,
							selected_plr.DisplayName ~= "" and selected_plr.DisplayName or selected_plr.Name,
							selected_plr.UserId,
							selected_plr.AccountAge
						)

						local response = Get(
							string.format(
								"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png&isCircular=false",
								selected_plr.UserId
							)
						)
						local data = HttpService:JSONDecode(response).data
						local avatar_url = data[1].imageUrl

						local imagedata = Get(avatar_url)

						player_image.Data = imagedata
					end
				end)
			end

			local function createoptions(tbl)
				for i, option in next, tbl do
					if option == game.Players.LocalPlayer then
						continue
					end
					optioninstances[option] = {}

					local button = Library:Create("Square", {
						Filled = true,
						Transparency = 0,
						Thickness = 1,
						Theme = "Toggle Background",
						Size = UDim2.new(1, 0, 0, 16),
						ZIndex = 19,
						Parent = list_content,
					})

					optioninstances[option].button = button

					local title = Library:Create("Text", {
						Text = option.Name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 3, 0, 1),
						Theme = "Text",
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					local team = Library:Create("Text", {
						Text = option.Team and tostring(option.Team) or "none",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(1 / 4, 6, 0, 1),
						Color = option.Team and option.TeamColor.Color or Color3.fromRGB(175, 175, 175),
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					local buyer = Library:Create("Text", {
						Text = isbuyer and "buyer" or "false",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(2 / 4, 6, 0, 1),
						Color = isbuyer and Library.Theme["Accent"] or Color3.fromRGB(175, 175, 175),
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					local status = Library:Create("Text", {
						Text = option == game.Players.LocalPlayer and "local player" or "none",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(3 / 4, 6, 0, 1),
						Color = option == game.Players.LocalPlayer and Color3.fromRGB(0, 255, 0)
							or Color3.fromRGB(175, 175, 175),
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					if table.find(Library.Friends, option) then
						status.Text = "friendly"
						status.Color = Color3.fromRGB(200, 55, 55)
					end
					if table.find(Library.Priorities, option) then
						status.Text = "priority"
						status.Color = Color3.fromRGB(55, 55, 200)
					end

					optioninstances[option].text = title
					optioninstances[option].status = status
					local firstline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(0, 2, 1, 0),
						Position = UDim2.new(1 / 4, 1, 0, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})
					local secondline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(0, 2, 1, 0),
						Position = UDim2.new(2 / 4, 1, 0, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})
					local thirdline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(0, 2, 1, 0),
						Position = UDim2.new(3 / 4, 1, 0, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})
					local bottomline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(1, -8, 0, 2),
						Position = UDim2.new(0, 3, 1, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})

					count = count + 1
					list_title.Text = tostring("player list - " .. count .. " player(s)")
					handleoptionclick(option, button)
				end
			end

			function playerlist:refresh(tbl, dontchange)
				content = table.clone(tbl)
				count = 0

				for _, opt in next, optioninstances do
					task.spawn(function()
						opt.button:Remove()
					end)
				end

				table.clear(optioninstances)

				createoptions(content)

				if dontchange then
					chosen = selected_plr
				else
					chosen = nil
				end
				refreshscroll()
				Library.Flags[flag] = chosen
			end

			PriorityFrame.MouseButton1Click:Connect(function()
				if selected_plr ~= nil and table.find(Library.Friends, selected_plr) then
					table.remove(Library.Friends, table.find(Library.Friends, selected_plr))
				end
				if
					selected_plr ~= nil
					and not table.find(Library.Priorities, selected_plr)
					and selected_plr ~= game.Players.LocalPlayer
				then
					table.insert(Library.Priorities, selected_plr)
					Library:notify({ text = tostring("player " .. selected_plr.Name .. " is now prioritized.") })
					optioninstances[selected_plr].status.Text = "priority"
					optioninstances[selected_plr].status.Color = Color3.fromRGB(55, 55, 200)
				elseif selected_plr ~= nil and selected_plr ~= game.Players.LocalPlayer then
					table.remove(Library.Priorities, table.find(Library.Priorities, selected_plr))
					Library:notify({ text = tostring("player " .. selected_plr.Name .. " is no longer prioritized.") })
					optioninstances[selected_plr].status.Text = "none"
					optioninstances[selected_plr].status.Color = Color3.fromRGB(175, 175, 175)
				else
					Library:notify({ text = "you cant do that dummy :P" })
				end
			end)

			FriendFrame.MouseButton1Click:Connect(function()
				if selected_plr ~= nil and table.find(Library.Priorities, selected_plr) then
					table.remove(Library.Priorities, table.find(Library.Priorities, selected_plr))
				end
				if
					selected_plr ~= nil
					and not table.find(Library.Friends, selected_plr)
					and selected_plr ~= game.Players.LocalPlayer
				then
					table.insert(Library.Friends, selected_plr)
					Library:notify({ text = tostring("player " .. selected_plr.Name .. " is now friendly.") })
					optioninstances[selected_plr].status.Text = "friendly"
					optioninstances[selected_plr].status.Color = Color3.fromRGB(200, 55, 55)
				elseif selected_plr ~= nil and selected_plr ~= game.Players.LocalPlayer then
					table.remove(Library.Friends, table.find(Library.Friends, selected_plr))
					Library:notify({ text = tostring("player " .. selected_plr.Name .. " is no longer friendly.") })
					optioninstances[selected_plr].status.Text = "none"
					optioninstances[selected_plr].status.Color = Color3.fromRGB(175, 175, 175)
				else
					Library:notify({ text = "you cant do that dummy :P" })
				end
			end)

			createoptions(players:GetPlayers())

			players.PlayerAdded:Connect(function()
				playerlist:refresh(players:GetPlayers(), true)
				refreshfix()
			end)

			players.PlayerRemoving:Connect(function()
				playerlist:refresh(players:GetPlayers(), true)
				refreshfix()
			end)

			refreshscroll()

			left.Size = UDim2.new(0.5, -14, 1, -210)
			right.Size = UDim2.new(0.5, -14, 1, -210)

			left.Position = UDim2.new(0, 0, 0, 275)
			right.Position = UDim2.new(0.5, 14, 0, 275)
		end
		function page:server_list(cfg)
			local serverlist = {}
			local max = 10
			local count = 0
			local startindex = 0
			local selected_server = nil
			local last_plr = nil

			local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
			local servers = HttpService:JSONDecode(
				Get(
					("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
				)
			).data

			local list_holder = Library:Create("Square", {
				Parent = page_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(19, 19, 19),
				Size = UDim2.new(1, 0, 0, ((max * 22) + 4) + 28),
				Position = UDim2.new(0, 0, 0, 0),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(list_holder, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			Library:Create("Square", {
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Accent",
				Size = UDim2.new(1, -2, 0, 2),
				Position = UDim2.new(0, 1, 0, 1),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})

			local list_title = Library:Create("Text", {
				Text = "server list - 0 servers",
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Text",
				Size = 13,
				Center = false,
				Outline = false,
				Font = Drawing.Fonts.Plex,
				Position = UDim2.new(0, 3, 0, 3),
				ZIndex = 14,
			})

			local list_inline = Library:Create("Square", {
				Parent = list_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(13, 13, 13),
				Size = UDim2.new(1, -10, 0, (max * 20)),
				Position = UDim2.new(0, 5, 0, 22),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(list_inline, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local list_content = Library:Create("Square", {
				Transparency = 0,
				Size = UDim2.new(1, -4, 1, -4),
				Position = UDim2.new(0, 2, 0, 3),
				Parent = list_inline,
			})

			local join_frame = Library:Create("Square", {
				Filled = true,
				Visible = true,
				Thickness = 0,
				Color = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0, 100, 0, 17),
				Position = UDim2.new(1, -105, 1, -21),
				ZIndex = 14,
				Parent = list_holder,
			})
			join_frame.MouseEnter:Connect(function()
				join_frame.Color = Color3.fromRGB(27, 27, 27)
			end)
			join_frame.MouseLeave:Connect(function()
				join_frame.Color = Color3.fromRGB(25, 25, 25)
			end)
			local outline1 = Library:Outline(join_frame, Color3.fromRGB(44, 44, 44), 14)
			Library:Outline(outline1, Color3.new(0, 0, 0), 14)
			local jointext = Library:Create("Text", {
				Text = "connect",
				Transparency = 1,
				Visible = true,
				Parent = join_frame,
				Theme = "Text",
				ZIndex = 16,
				Center = true,
				Position = UDim2.new(0.5, 0, 0, 1),
				Font = 2,
				Size = 13,
				Outline = true,
			})

			local sort_frame = Library:Create("Square", {
				Filled = true,
				Visible = true,
				Thickness = 0,
				Color = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0, 120, 0, 17),
				Position = UDim2.new(0, 5, 1, -21),
				ZIndex = 14,
				Parent = list_holder,
			})
			sort_frame.MouseEnter:Connect(function()
				sort_frame.Color = Color3.fromRGB(27, 27, 27)
			end)
			sort_frame.MouseLeave:Connect(function()
				sort_frame.Color = Color3.fromRGB(25, 25, 25)
			end)
			local outline2 = Library:Outline(sort_frame, Color3.fromRGB(44, 44, 44), 14)
			Library:Outline(outline2, Color3.new(0, 0, 0), 14)
			local text = Library:Create("Text", {
				Text = "swap filter",
				Transparency = 1,
				Visible = true,
				Parent = sort_frame,
				Theme = "Text",
				ZIndex = 16,
				Center = true,
				Position = UDim2.new(0.5, 0, 0, 1),
				Font = 2,
				Size = 13,
				Outline = true,
			})

			local sort_text = Library:Create("Text", {
				Text = "players ascending",
				Transparency = 0.6,
				Visible = true,
				Parent = list_holder,
				Theme = "Text",
				ZIndex = 16,
				Center = false,
				Position = UDim2.new(0, 135, 1, -21),
				Font = 2,
				Size = 13,
				Outline = true,
			})

			local refresh_frame = Library:Create("Square", {
				Filled = true,
				Visible = true,
				Thickness = 0,
				Color = Color3.fromRGB(25, 25, 25),
				Size = UDim2.new(0, 100, 0, 17),
				Position = UDim2.new(1, -215, 1, -21),
				ZIndex = 14,
				Parent = list_holder,
			})
			refresh_frame.MouseEnter:Connect(function()
				refresh_frame.Color = Color3.fromRGB(27, 27, 27)
			end)
			refresh_frame.MouseLeave:Connect(function()
				refresh_frame.Color = Color3.fromRGB(25, 25, 25)
			end)
			local outline1 = Library:Outline(refresh_frame, Color3.fromRGB(44, 44, 44), 14)
			Library:Outline(outline1, Color3.new(0, 0, 0), 14)
			local refreshtext = Library:Create("Text", {
				Text = "refresh",
				Transparency = 1,
				Visible = true,
				Parent = refresh_frame,
				Theme = "Text",
				ZIndex = 16,
				Center = true,
				Position = UDim2.new(0.5, 0, 0, 1),
				Font = 2,
				Size = 13,
				Outline = true,
			})

			list_content:AddListLayout(3)

			list_content:MakeScrollable()
			local scroll_connect = nil

			local scrollbar_outline = Library:Create("Square", {
				Transparency = 1,
				Size = UDim2.new(0, 6, 1, 0),
				Position = UDim2.new(1, -6, 0, 0),
				Parent = list_inline,
				ZIndex = 15,
				Thickness = 1,
				Color = Color3.fromRGB(45, 45, 45),
				Filled = true,
			})

			local scrollbar = Library:Create("Square", {
				Transparency = 1,
				Size = UDim2.new(0, 5, count == 0 and 1 or count / max, 0),
				Position = UDim2.new(1, -3, 0, 0),
				Parent = list_inline,
				ZIndex = 16,
				Thickness = 1,
				Color = Color3.fromRGB(65, 65, 65),
				Filled = true,
			})

			local function refreshscroll()
				local scale = startindex / (count > 0 and count or 1)
				scrollbar.Position = UDim2.new(1, -5, scale, 0)
				scrollbar.Size = UDim2.new(0, 5, math.clamp(count == 0 and 1 or 1 / (count / max), 0, 1), 0)
			end

			local function refreshfix()
				list_content.Visible = list_content.Visible
			end

			list_content.MouseEnter:Connect(function()
				scroll_connect = Library:Connect(InputService.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseWheel then
						local down = input.Position.Z < 0 and true or false
						if down then
							local indexesleft = count - max - startindex
							if indexesleft >= 0 then
								startindex = math.clamp(startindex + 1, 0, count - max)
								refreshscroll()
							end
						else
							local indexesleft = count - max + startindex
							if indexesleft >= count - max then
								startindex = math.clamp(startindex - 1, 0, count - max)
								refreshscroll()
							end
						end
					end
				end)
			end)

			list_content.MouseLeave:Connect(function()
				if scroll_connect then
					Library:Disconnect(scroll_connect)
				end
			end)
			refreshscroll()

			local chosen = nil
			local optioninstances = {}
			local function handleoptionclick(option, button)
				button.MouseButton1Click:Connect(function()
					chosen = option.id
					Library.Flags[flag] = option.id
					selected_server = option.id

					for i, v in next, optioninstances do
						if i == option then
							Library:ChangeObjectTheme(v.text, "Accent")
							Library:ChangeObjectTheme(v.ping, "Accent")
							Library:ChangeObjectTheme(v.players, "Accent")
						else
							Library:ChangeObjectTheme(v.text, "Text")
							Library:ChangeObjectTheme(v.ping, "Text")
							Library:ChangeObjectTheme(v.players, "Text")
						end
					end
				end)
			end

			local function createoptions(tbl)
				for i, option in next, tbl do
					optioninstances[option] = {}

					local button = Library:Create("Square", {
						Filled = true,
						Transparency = 0,
						Thickness = 1,
						Theme = "Toggle Background",
						Size = UDim2.new(1, 0, 0, 16),
						ZIndex = 19,
						Parent = list_content,
					})

					optioninstances[option].button = button

					local id = Library:Create("Text", {
						Text = option.id and string.sub(option.id, 0, 8) .. "-XXXX-XXXX-XXXX-XXXXXXXXXXXX" or "nil",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 3, 0, 1),
						Theme = "Text",
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					local ping = Library:Create("Text", {
						Text = option.ping and tostring(option.ping .. " ms") or "0 ms",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(2 / 4, 6, 0, 1),
						Color = isbuyer and Library.Theme["Accent"] or Color3.fromRGB(175, 175, 175),
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					local players = Library:Create("Text", {
						Text = option.playing and option.maxPlayers and tostring(
							option.playing .. "/" .. option.maxPlayers
						) or "0/0",
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(3 / 4, 6, 0, 1),
						Color = option.playing == option.maxPlayers and Color3.fromRGB(255, 0, 0)
							or Color3.fromRGB(175, 175, 175),
						ZIndex = 19,
						Outline = false,
						Parent = button,
					})

					optioninstances[option].text = id
					optioninstances[option].ping = ping
					optioninstances[option].players = players

					local firstline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(0, 2, 1, 0),
						Position = UDim2.new(2 / 4, 1, 0, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})
					local secondline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(0, 2, 1, 0),
						Position = UDim2.new(3 / 4, 1, 0, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})
					local bottomline = Library:Create("Square", {
						Transparency = 0.3,
						Size = UDim2.new(1, -8, 0, 2),
						Position = UDim2.new(0, 3, 1, 0),
						Parent = button,
						ZIndex = 19,
						Thickness = 1,
						Color = Color3.fromRGB(0, 0, 0),
						Filled = true,
					})

					count = count + 1
					list_title.Text = tostring("server list - " .. count .. " servers")
					handleoptionclick(option, button)
				end
			end

			function serverlist:refresh(tbl, dontchange)
				content = table.clone(tbl)
				count = 0

				for _, opt in next, optioninstances do
					task.spawn(function()
						opt.button:Remove()
					end)
				end

				table.clear(optioninstances)

				createoptions(content)

				if dontchange then
					chosen = selected_server
				else
					chosen = nil
				end
				refreshscroll()
				Library.Flags[flag] = chosen
			end

			local clicked_join, counting_join = false, false
			join_frame.MouseButton1Click:Connect(function()
				task.spawn(function()
					if clicked_join then
						clicked_join = false
						counting_join = false
						Library:ChangeObjectTheme(jointext, "Text")
						jointext.Text = "connect"

						TeleportService:TeleportToPlaceInstance(game.PlaceId, Library.Flags[flag])
					else
						clicked_join = true
						counting_join = true
						for i = 3, 1, -1 do
							if not counting_join then
								break
							end
							jointext.Text = "confirm? " .. tostring(i)
							Library:ChangeObjectTheme(jointext, "Accent")
							wait(1)
						end
						clicked_join = false
						counting_join = false
						Library:ChangeObjectTheme(jointext, "Text")
						jointext.Text = "connect"
					end
				end)
			end)

			local sortAscending, sortField = false, "players"
			sort_frame.MouseButton1Click:Connect(function()
				local compare
				if sortField == "ping" then
					if sortAscending then
						compare = function(a, b)
							return a.ping < b.ping
						end
					else
						compare = function(a, b)
							return a.ping > b.ping
						end
					end
				else
					if sortAscending then
						compare = function(a, b)
							return a.playing < b.playing
						end
					else
						compare = function(a, b)
							return a.playing > b.playing
						end
					end
				end

				table.sort(servers, compare)

				serverlist:refresh(servers, true)
				sort_text.Text = ("%s %s"):format(sortField, sortAscending and "ascending" or "descending")

				if not sortAscending then
					if sortField == "ping" then
						sortField = "players"
					else
						sortField = "ping"
					end
				end

				sortAscending = not sortAscending
			end)

			refresh_frame.MouseButton1Click:Connect(function()
				serverlist:refresh(
					HttpService:JSONDecode(
						Get(
							("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(
								game.PlaceId
							)
						)
					).data,
					false
				)
				sort_text.Text = "players ascending"
			end)

			createoptions(servers)

			refreshscroll()

			left.Size = UDim2.new(0.5, -14, 1, -210)
			right.Size = UDim2.new(0.5, -14, 1, -210)

			left.Position = UDim2.new(0, 0, 0, 265)
			right.Position = UDim2.new(0.5, 14, 0, 265)
		end

		function page:section(cfg)
			local section = { obj_amt = 0, startindex = 0 }
			local name = cfg.name or cfg.Name or "Page"
			local side = cfg.side == "left" and left
				or cfg.Side == "Left" and left
				or cfg.side == "right" and right
				or cfg.Side == "Right" and right
				or left
			local size = cfg.size or cfg.Size or 200

			local section_holder = Library:Create("Square", {
				Parent = side,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(19, 19, 19),
				Size = size ~= "auto" and UDim2.new(1, 0, 0, size) or UDim2.new(1, 0, 0, 28),
				Position = UDim2.new(0, 0, 0, 0),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(section_holder, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local section_title_cover = Library:Create("Square", {
				Parent = section_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(19, 19, 19),
				Size = UDim2.new(0, Utility.TextLength(name, Drawing.Fonts.Plex, 13).X + 2, 0, 4),
				Position = UDim2.new(0, 10, 0, -1),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			local section_title = Library:Create("Text", {
				Text = name,
				Parent = section_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Text",
				Size = 13,
				Center = false,
				Outline = false,
				Font = Drawing.Fonts.Plex,
				Position = UDim2.new(0, 11, 0, -8),
				ZIndex = 14,
			})

			local section_content = Library:Create("Square", {
				Transparency = 0,
				Size = UDim2.new(1, -32, 1, -10),
				Position = UDim2.new(0, 16, 0, 15),
				Parent = section_holder,
				ZIndex = 14,
			})
			section_content:AddListLayout(9)

			function section:toggle(cfg)
				local toggle = { section = self, colors = 0 }
				local name = cfg.name or cfg.Name or "new toggle"
				local risky = cfg.risky or cfg.Risky or false
				local state = cfg.state or cfg.State or false

				local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
				local callback = cfg.callback or cfg.Callback or function() end
				local toggled = false

				local holder = Library:Create("Square", {
					Parent = section_content,
					Visible = true,
					Transparency = 0,
					Size = UDim2.new(1, 0, 0, 6),
					Thickness = 1,
					Filled = false,
					ZIndex = 14,
				})

				local toggle_frame = Library:Create("Square", {
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Theme = "Toggle Background",
					Size = UDim2.new(0, 6, 0, 6),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
				})
				do
					local outline = Library:Outline(toggle_frame, Color3.fromRGB(0, 0, 0), 14)
				end
				local gradient = Library:Create("Image", {
					Data = Images.gradient,
					Transparency = 1,
					Visible = true,
					Parent = toggle_frame,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 14,
				})

				local toggle_title = Library:Create("Text", {
					Text = name,
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Theme = risky and "Risky Text" or "Text",
					Size = 13,
					Center = false,
					Outline = false,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0, 20, 0, -5),
					ZIndex = 14,
				})

				local function setstate()
					toggled = not toggled
					if toggled then
						Library:ChangeObjectTheme(toggle_frame, "Accent")
					else
						Library:ChangeObjectTheme(toggle_frame, "Toggle Background")
					end
					Library.Flags[flag] = toggled
					callback(toggled)
				end

				holder.MouseButton1Click:Connect(setstate)

				holder.MouseEnter:Connect(function()
					if not toggled then
						Library:ChangeObjectTheme(toggle_frame, "Toggle Background Highlight")
					end
				end)

				holder.MouseLeave:Connect(function()
					if not toggled then
						Library:ChangeObjectTheme(toggle_frame, "Toggle Background")
					end
				end)

				local function set(bool)
					bool = type(bool) == "boolean" and bool or false
					if toggled ~= bool then
						setstate()
					end
				end
				Flags[flag] = set
				set(state)

				function toggle:set(bool)
					set(bool)
				end

				function toggle:colorpicker(cfg)
					local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

					local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					local defaultalpha = cfg.alpha or cfg.Alpha or 1
					local colorpicker_tbl = {}

					toggle.colors += 1
					local cp =
						Library.ObjectColorPicker(default, defaultalpha, holder, toggle.colors - 1, flag, callback, -6)
					function colorpicker_tbl:set(color)
						cp:set(color, false, true)
					end
					return colorpicker_tbl
				end

				function toggle:keybind(cfg)
					local keybind = {}
					local default = cfg.default or cfg.Default or nil
					local mode = cfg.mode or cfg.Mode or "Hold"
					local blacklist = cfg.blacklist or cfg.Blacklist or {}

					local flag = cfg.flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					local key_mode = mode

					local keyholder = Library:Create("Square", {
						Size = UDim2.new(0, 40, 1, 0),
						Position = UDim2.new(1, -60, 0, 0),
						Transparency = 0,
						ZIndex = 15,
						Parent = holder,
						Thickness = 1,
						Filled = false,
					})

					local keytext = Library:Create("Text", {
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Theme = "Un-Selected_Text",
						Position = UDim2.new(1, -40, 0, -5),
						ZIndex = 14,
						Parent = holder,
						Outline = false,
						Center = true,
					})

					local key
					local state = false
					local binding

					local function set(newkey)
						if c then
							c:Disconnect()
							if flag then
								Library.Flags[flag] = false
							end
							callback(false)
						end
						if tostring(newkey):find("Enum.KeyCode.") then
							newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
						elseif tostring(newkey):find("Enum.UserInputType.") then
							newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
						end

						if newkey ~= nil and not table.find(blacklist, newkey) then
							key = newkey

							local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						else
							key = nil

							local text = "-"

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						end

						if bind ~= "" or bind ~= nil then
							state = false
							if flag then
								Library.Flags[flag] = state
							end
							callback(false)
						end
					end

					local function setkey(newkey)
						if tostring(newkey):find("Enum.KeyCode.") then
							newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
						elseif tostring(newkey):find("Enum.UserInputType.") then
							newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
						end

						if newkey ~= nil and not table.find(blacklist, newkey) then
							key = newkey
							Library.Flags[flag .. "_KEY"] = newkey

							local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						else
							key = nil
							Library.Flags[flag .. "_KEY"] = nil

							local text = "-"

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						end
					end

					Library:Connect(InputService.InputBegan, function(inp)
						if (inp.KeyCode == key or inp.UserInputType == key) and not binding then
							if key_mode == "Hold" then
								if flag then
									Library.Flags[flag] = true
								end
								c = Library:Connect(RunService.RenderStepped, function()
									if callback then
										callback(true)
									end
								end)
							elseif key_mode == "Toggle" then
								state = not state
								if flag then
									Library.Flags[flag] = state
								end
								callback(state)
							else
								callback()
							end
						end
					end)

					Flags[flag .. "_KEY"] = setkey

					set(default)

					keyholder.MouseButton1Click:Connect(function()
						if not binding then
							keytext.Text = "[-]"
							Library:ChangeObjectTheme(keytext, "Accent")

							binding = Library:Connect(InputService.InputBegan, function(input, gpe)
								set(
									input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
										or input.UserInputType
								)
								setkey(
									input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
										or input.UserInputType
								)
								Library:Disconnect(binding)
								task.wait()
								binding = nil
							end)
						end
					end)

					Library:Connect(InputService.InputEnded, function(inp)
						if key_mode == "Hold" then
							if key ~= "" or key ~= nil then
								if inp.KeyCode == key or inp.UserInputType == key then
									if c then
										c:Disconnect()
										if flag then
											Library.Flags[flag] = false
										end
										if callback then
											callback(false)
										end
									end
								end
							end
						end
					end)

					local keybindtypes = {}

					function keybindtypes:set(newkey)
						set(newkey)
					end

					return keybindtypes
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return toggle
			end

			function section:divider(cfg)
				local divider = { section = self }
				local name = cfg.name or cfg.Name or "new divider"

				local holder = Library:Create("Square", {
					Parent = section_content,
					Visible = true,
					Transparency = 0,
					Size = UDim2.new(1, 0, 0, 6),
					Thickness = 1,
					Filled = false,
					ZIndex = 14,
				})

				local div = Library:Create("Square", {
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Color = Color3.fromRGB(100, 100, 100),
					Size = UDim2.new(0, 6, 0, 1),
					Position = UDim2.new(0, 0, 0, 3),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
				})
				local title = Library:Create("Text", {
					Text = name,
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Color = Color3.fromRGB(100, 100, 100),
					Size = 13,
					Center = false,
					Outline = false,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0, 20, 0, -5),
					ZIndex = 14,
				})
				local div = Library:Create("Square", {
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Color = Color3.fromRGB(100, 100, 100),
					Size = UDim2.new(1, -Utility.TextLength(name, 2, 13).X - 45, 0, 1),
					Position = UDim2.new(0, 30 + Utility.TextLength(name, 2, 13).X, 0, 3),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
				})

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 5)
				end
				return divider
			end

			function section:slider(cfg)
				local slider = {}
				local name = cfg.name or cfg.Name or nil
				local min = cfg.min or cfg.minimum or 0
				local max = cfg.max or cfg.maximum or 100
				local allow = cfg.animation or false
				local fade_min = cfg.fade_min or min
				local fade_max = cfg.fade_max or max
				local suffix = cfg.suffix or cfg.Suffix or ""
				local text = cfg.text or ("[value]" .. suffix)
				local float = cfg.float or 1
				local default = cfg.default and math.clamp(cfg.default, min, max) or min

				local flag = cfg.flag or Utility.NextFlag()
				local callback = cfg.callback or function() end

				local holder = Library:Create("Square", {
					Parent = section_content,
					Visible = true,
					Transparency = 0,
					Size = name and UDim2.new(1, 0, 0, 22) or UDim2.new(1, 0, 0, 12),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
				})

				local slider_frame = Library:Create("Square", {
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Theme = "Toggle Background",
					Size = UDim2.new(1, -50, 0, 6),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
					Position = name and UDim2.new(0, 23, 0, 14) or UDim2.new(0, 23, 0, 3),
				})
				do
					local outline = Library:Outline(slider_frame, Color3.fromRGB(0, 0, 0), 14)
				end
				Library:Create("Image", {
					Data = Images.gradient,
					Transparency = 1,
					Visible = true,
					Parent = slider_frame,
					Size = UDim2.new(1, 0, 1, 0),
					ZIndex = 15,
				})

				if name then
					local slider_title = Library:Create("Text", {
						Text = name,
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Theme = "Text",
						Size = 13,
						Center = false,
						Outline = false,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 20, 0, -2),
						ZIndex = 14,
					})
				end

				local slider_fill = Library:Create("Square", {
					Parent = slider_frame,
					Visible = true,
					Transparency = 1,
					Theme = "Accent",
					Size = UDim2.new(1, 0, 1, 0),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
					Position = UDim2.new(0, 0, 0, 0),
				})

				local slider_value = Library:Create("Text", {
					Text = text,
					Parent = slider_fill,
					Visible = true,
					Transparency = 1,
					Theme = "Text",
					Size = 13,
					Center = true,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(1, 0, 0.5, -2),
					ZIndex = 15,
				})

				local slider_drag = Library:Create("Square", {
					Parent = slider_frame,
					Visible = true,
					Transparency = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
					Position = UDim2.new(0, 0, 0, 0),
				})

				local function set(value)
					value = math.clamp(Utility.Round(value, float), min, max)

					slider_value.Text = text:gsub("%[value%]", string.format("%.14g", value))

					local sizeX = ((value - min) / (max - min))
					slider_fill.Size = UDim2.new(sizeX, 0, 1, 0)

					Library.Flags[flag] = value
					callback(value)
				end
				Flags[flag] = set
				set(default)

				local sliding = false

				local function slide(input)
					local sizeX = (input.Position.X - slider_frame.AbsolutePosition.X) / slider_frame.AbsoluteSize.X
					local value = ((max - min) * sizeX) + min

					set(value)
				end

				holder.MouseEnter:Connect(function()
					Library:ChangeObjectTheme(slider_frame, "Toggle Background Highlight")
				end)

				holder.MouseLeave:Connect(function()
					Library:ChangeObjectTheme(slider_frame, "Toggle Background")
				end)

				Library:Connect(slider_drag.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						sliding = true
						slide(input)
					end
				end)

				Library:Connect(slider_drag.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						sliding = false
					end
				end)

				Library:Connect(slider_fill.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						sliding = true
						slide(input)
					end
				end)

				Library:Connect(slider_fill.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						sliding = false
					end
				end)

				Library:Connect(InputService.InputChanged, function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						if sliding then
							slide(input)
						end
					end
				end)

				if allow then
					local slider_question = Library:Create("Text", {
						Text = "?",
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Theme = "Text",
						Size = 13,
						Center = false,
						Outline = false,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(1, -36, 0, -2),
						ZIndex = 14,
					})
					local question_button = Library:Create("Square", {
						Filled = true,
						Thickness = 0,
						Parent = holder,
						Color = Color3.fromRGB(13, 13, 13),
						Size = UDim2.new(0, slider_question.TextBounds.X, 0, slider_question.TextBounds.Y),
						Position = UDim2.new(1, -36, 0, -2),
						Visible = true,
						Transparency = 0,
						ZIndex = 29,
					})

					local slider_window = Library:Create("Square", {
						Filled = true,
						Thickness = 0,
						Parent = slider_drag,
						Color = Color3.fromRGB(13, 13, 13),
						Size = UDim2.new(0, 205, 0, 107),
						Visible = false,
						Position = UDim2.new(1, -185, 1, 6),
						ZIndex = 29,
					})
					table.insert(FadeThings, slider_window)

					local outline3 = Library:Outline(slider_window, Color3.fromRGB(44, 44, 44))
					Library:Outline(outline3, Color3.fromRGB(0, 0, 0))

					local windowback = Library:Create("Square", {
						Filled = true,
						Thickness = 0,
						Parent = slider_window,
						Theme = "Accent",
						Size = UDim2.new(1, -2, 0, 1),
						Visible = true,
						Position = UDim2.new(0, 1, 0, 1),
						ZIndex = 29,
					})

					local window_page = Library:Create("Square", {
						Filled = false,
						Thickness = 0,
						Transparency = 0,
						Parent = slider_window,
						Color = Color3.fromRGB(0, 0, 0),
						Size = UDim2.new(1, -10, 1, -10),
						Position = UDim2.new(0, 5, 0, 25),
						Visible = true,
						ZIndex = 29,
					})
					window_page:AddListLayout(3)

					local slider_button = Library:Create("Square", {
						Filled = true,
						Thickness = 0,
						Parent = slider_window,
						Color = Color3.fromRGB(13, 13, 13),
						Size = UDim2.new(1, 0, 0, 17),
						Position = UDim2.new(0, 0, 0, 10),
						Visible = true,
						ZIndex = 29,
					})

					local isfading = false

					local fadetext = Library:Create("Text", {
						Text = "fading",
						Parent = slider_button,
						Visible = true,
						Transparency = 1,
						Theme = "Text",
						Size = 13,
						Center = true,
						Outline = false,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0.5, 0, 0, 1),
						ZIndex = 29,
					})

					local outline3 = Library:Outline(slider_window, Color3.fromRGB(44, 44, 44))
					Library:Outline(outline3, Color3.fromRGB(0, 0, 0))

					local startslide = Library.CreateSlider({
						parent = window_page,
						name = "start",
						flag = Library.Flags[flag .. "_FADING_START"],
						min = fade_min,
						max = fade_max,
						default = 0,
						callback = function(state)
							Library.Flags[flag .. "_FADING_START"] = state
						end,
					})

					local endslide = Library.CreateSlider({
						parent = window_page,
						name = "end",
						flag = Library.Flags[flag .. "_FADING_END"],
						min = fade_min,
						max = fade_max,
						default = 0,
						callback = function(state)
							Library.Flags[flag .. "_FADING_END"] = state
						end,
					})

					local speedslide = Library.CreateSlider({
						parent = window_page,
						name = "speed",
						flag = Library.Flags[flag .. "_FADING_SPEED"],
						min = 0,
						max = 500,
						default = 100,
						callback = function(state)
							Library.Flags[flag .. "_FADING_SPEED"] = state
						end,
					})

					local function setfade(state)
						Library.Flags[flag .. "_FADING"] = state
					end

					question_button.MouseButton1Click:Connect(function()
						for i, v in next, FadeThings do
							if v ~= slider_window then
								v.Visible = false
							end
						end
						slider_window.Visible = not slider_window.Visible
					end)
					question_button.MouseEnter:Connect(function()
						Library:ChangeObjectTheme(slider_question, "Accent")
					end)
					question_button.MouseLeave:Connect(function()
						Library:ChangeObjectTheme(slider_question, "Text")
					end)
					slider_button.MouseButton1Click:Connect(function()
						isfading = not isfading
						setfade(isfading)
						Library:ChangeObjectTheme(fadetext, isfading and "Accent" or "Text")
					end)
					task.spawn(function()
						while task.wait() do
							local val = nil
							if Library.Flags[flag .. "_FADING"] then
								local sinwave =
									math.abs(math.sin(os.clock() * (Library.Flags[flag .. "_FADING_SPEED"] / 50)))

								val = Utility.NumberLerp(sinwave, {
									[1] = {
										start = 0,
										number = Library.Flags[flag .. "_FADING_START"],
									},
									[2] = {
										start = 1,
										number = Library.Flags[flag .. "_FADING_END"] + 1,
									},
								})
							end
							if val ~= nil then
								set(val)
							end
						end
					end)
					Flags[flag .. "_FADING"] = setfade
				end

				function slider:set(value)
					set(value)
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return slider
			end

			function section:screen(cfg)
				local screen = { section = self }
				local name = cfg.name or cfg.Name or "no content"

				local holder = Library:Create("Square", {
					Parent = section_content,
					Visible = true,
					Transparency = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Thickness = 1,
					Filled = false,
					ZIndex = 14,
				})

				local title = Library:Create("Text", {
					Text = name,
					Font = Drawing.Fonts.Plex,
					Size = 13,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Color = Color3.fromRGB(100, 100, 100),
					ZIndex = 14,
					Center = true,
					Outline = false,
					Parent = holder,
				})
				return screen
			end

			function section:dropdown(cfg)
				local dropdown = {}
				local name = cfg.name or cfg.Name or nil
				local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
				local default = cfg.default or cfg.Default or content[1] or nil
				local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
				local scrollable = cfg.scrollable or cfg.Scrollable or false
				local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10

				local flag = cfg.flag or Utility.NextFlag()
				local callback = cfg.callback or function() end
				if not max and type(default) == "table" then
					default = nil
				end
				if max and default == nil then
					default = {}
				end
				if type(default) == "table" then
					if max then
						for i, opt in next, default do
							if not table.find(content, opt) then
								table.remove(default, i)
							elseif i > max then
								table.remove(default, i)
							end
						end
					else
						default = nil
					end
				elseif default ~= nil then
					if not table.find(content, default) then
						default = nil
					end
				end

				local holder = Library:Create("Square", {
					Transparency = 0,
					ZIndex = 14,
					Size = UDim2.new(1, 0, 0, name and 32 or 19),
					Parent = section_content,
					Thickness = 1,
				})

				if name then
					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 20, 0, -2),
						Theme = "Text",
						ZIndex = 14,
						Outline = false,
						Parent = holder,
					})
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return Library.CreateDropdown(holder, content, flag, callback, default, max, scrollable, scrollingmax)
			end

			function section:list(cfg)
				local list = {}
				local name = cfg.name or cfg.Name or nil
				local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
				local default = cfg.default or cfg.Default or content[1] or nil
				local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
				local scrollable = cfg.scrollable or cfg.Scrollable or false
				local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10

				local flag = cfg.flag or Utility.NextFlag()
				local callback = cfg.callback or function() end
				if not max and type(default) == "table" then
					default = nil
				end
				if max and default == nil then
					default = {}
				end
				if type(default) == "table" then
					if max then
						for i, opt in next, default do
							if not table.find(content, opt) then
								table.remove(default, i)
							elseif i > max then
								table.remove(default, i)
							end
						end
					else
						default = nil
					end
				elseif default ~= nil then
					if not table.find(content, default) then
						default = nil
					end
				end

				local holder = Library:Create("Square", {
					Transparency = 0,
					ZIndex = 18,
					Size = UDim2.new(1, 0, 0, name and 32 or 19),
					Parent = section_content,
					Thickness = 1,
				})

				if name then
					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 20, 0, -2),
						Theme = "Text",
						ZIndex = 14,
						Outline = false,
						Parent = holder,
					})
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return Library.CreateList(holder, content, flag, callback, default, max, scrollable, scrollingmax)
			end

			function section:multibox(cfg)
				local multibox = {}
				local name = cfg.name or cfg.Name or nil
				local default = cfg.default or cfg.Default or nil
				local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
				local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
				local scrollable = cfg.scrollable or cfg.Scrollable or false
				local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10

				local flag = cfg.flag or Utility.NextFlag()
				local callback = cfg.callback or function() end
				if not max and type(default) == "table" then
					default = nil
				end
				if max and default == nil then
					default = {}
				end
				if type(default) == "table" then
					if max then
						for i, opt in next, default do
							if not table.find(content, opt) then
								table.remove(default, i)
							elseif i > max then
								table.remove(default, i)
							end
						end
					else
						default = nil
					end
				elseif default ~= nil then
					if not table.find(content, default) then
						default = nil
					end
				end

				local holder = Library:Create("Square", {
					Transparency = 0,
					ZIndex = 14,
					Size = UDim2.new(1, 0, 0, name and 32 or 19),
					Parent = section_content,
					Thickness = 1,
				})

				if name then
					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 20, 0, -2),
						Theme = "Text",
						ZIndex = 14,
						Outline = false,
						Parent = holder,
					})
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return Library.CreateMultibox(holder, content, flag, callback, default, max, scrollable, scrollingmax)
			end

			function section:button(cfg)
				local button_tbl = {}
				local name = cfg.name or cfg.Name or "Button"
				local callback = cfg.callback or cfg.Callback or function() end
				local button_confirm = cfg.confirm or cfg.Confirm or false

				local holder = Library:Create("Square", {
					Transparency = 0,
					ZIndex = 14,
					Size = UDim2.new(1, 0, 0, 22),
					Parent = section_content,
					Thickness = 1,
				})
				local ButtonFrame = Library:Create("Square", {
					Filled = true,
					Visible = true,
					Thickness = 0,
					Color = Color3.fromRGB(25, 25, 25),
					Size = UDim2.new(1, -50, 0, 17),
					Position = UDim2.new(0, 23, 1, -22),
					ZIndex = 14,
					Parent = holder,
				})

				holder.MouseEnter:Connect(function()
					ButtonFrame.Color = Color3.fromRGB(27, 27, 27)
				end)

				holder.MouseLeave:Connect(function()
					ButtonFrame.Color = Color3.fromRGB(25, 25, 25)
				end)

				local outline1 = Library:Outline(ButtonFrame, Color3.fromRGB(44, 44, 44), 14)
				Library:Outline(outline1, Color3.new(0, 0, 0), 14)

				local icon = Library:Create("Text", {
					Text = name,
					Transparency = 1,
					Visible = true,
					Parent = ButtonFrame,
					Theme = "Text",
					ZIndex = 16,
					Center = true,
					Position = UDim2.new(0.5, 0, 0, 1),
					Font = 2,
					Size = 13,
					Outline = true,
				})

				local clicked, counting = false, false
				Library:Connect(ButtonFrame.MouseButton1Click, function()
					task.spawn(function()
						if button_confirm then
							if clicked then
								clicked = false
								counting = false
								Library:ChangeObjectTheme(icon, "Text")
								icon.Text = name
								callback()
							else
								clicked = true
								counting = true
								for i = 3, 1, -1 do
									if not counting then
										break
									end
									icon.Text = "confirm? " .. tostring(i)
									Library:ChangeObjectTheme(icon, "Accent")
									wait(1)
								end
								clicked = false
								counting = false
								Library:ChangeObjectTheme(icon, "Text")
								icon.Text = name
							end
						else
							callback()
						end
					end)
				end)
				Library:Connect(ButtonFrame.MouseButton1Down, function()
					Library:ChangeObjectTheme(icon, "Accent")
				end)
				Library:Connect(ButtonFrame.MouseButton1Up, function()
					Library:ChangeObjectTheme(icon, "Text")
				end)

				function button_tbl:button(cfg)
					local name = cfg.name or cfg.Name or "Button"
					local callback = cfg.callback or cfg.Callback or function() end
					ButtonFrame.Size = UDim2.new(1 / 2, -40, 0, 17)

					local ButtonFrame_2 = Library:Create("Square", {
						Filled = true,
						Visible = true,
						Thickness = 0,
						Color = Color3.fromRGB(25, 25, 25),
						Size = UDim2.new(1 / 2, -40, 0, 17),
						Position = UDim2.new(0.5, 13, 1, -22),
						ZIndex = 14,
						Parent = holder,
					})

					holder.MouseEnter:Connect(function()
						ButtonFrame_2.Color = Color3.fromRGB(27, 27, 27)
					end)

					holder.MouseLeave:Connect(function()
						ButtonFrame_2.Color = Color3.fromRGB(25, 25, 25)
					end)

					local outline1 = Library:Outline(ButtonFrame_2, Color3.fromRGB(44, 44, 44), 14)
					Library:Outline(outline1, Color3.new(0, 0, 0), 14)

					local icon = Library:Create("Text", {
						Text = name,
						Transparency = 1,
						Visible = true,
						Parent = ButtonFrame_2,
						Theme = "Text",
						ZIndex = 16,
						Center = true,
						Position = UDim2.new(0.5, 0, 0, 1),
						Font = 2,
						Size = 13,
						Outline = true,
					})

					local clicked, counting = false, false
					Library:Connect(ButtonFrame_2.MouseButton1Click, function()
						task.spawn(function()
							if button_confirm then
								if clicked then
									clicked = false
									counting = false
									Library:ChangeObjectTheme(icon, "Text")
									icon.Text = name
									callback()
								else
									clicked = true
									counting = true
									for i = 3, 1, -1 do
										if not counting then
											break
										end
										icon.Text = "confirm? " .. tostring(i)
										Library:ChangeObjectTheme(icon, "Accent")
										wait(1)
									end
									clicked = false
									counting = false
									Library:ChangeObjectTheme(icon, "Text")
									icon.Text = name
								end
							else
								callback()
							end
						end)
					end)
					Library:Connect(ButtonFrame_2.MouseButton1Down, function()
						Library:ChangeObjectTheme(icon, "Accent")
					end)
					Library:Connect(ButtonFrame_2.MouseButton1Up, function()
						Library:ChangeObjectTheme(icon, "Text")
					end)
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end
				return button_tbl
			end

			function section:colorpicker(cfg)
				local colorpicker_tbl = {}
				local name = cfg.name or cfg.Name or "new colorpicker"
				local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

				local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
				local callback = cfg.callback or function() end
				local allow_tool = cfg.tooltip or cfg.ToolTip or false
				local defaultalpha = cfg.alpha or cfg.Alpha or 1

				local holder = Library:Create("Square", {
					Transparency = 0,
					Filled = true,
					Thickness = 1,
					Size = UDim2.new(1, 0, 0, 6),
					ZIndex = 14,
					Parent = section_content,
				})

				local title = Library:Create("Text", {
					Text = name,
					Font = Drawing.Fonts.Plex,
					Size = 13,
					Position = UDim2.new(0, 20, 0, -5),
					Theme = "Text",
					ZIndex = 14,
					Outline = false,
					Parent = holder,
				})

				local colorpickers = 0

				local colorpickertypes =
					Library.ObjectColorPicker(default, defaultalpha, holder, colorpickers, flag, callback, -6)
				function colorpickertypes:new_colorpicker(cfg)
					colorpickers = colorpickers + 1
					local cp_tbl = {}

					Utility.Table(cfg)
					local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

					local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					local defaultalpha = cfg.alpha or cfg.Alpha or 1

					local cp =
						Library.ObjectColorPicker(default, defaultalpha, holder, colorpickers, flag, callback, -6)
					function cp_tbl:set(color)
						cp:set(color, false, true)
					end
					return cp_tbl
				end

				function colorpicker_tbl:set(color)
					colorpickertypes:set(color, false, true)
				end
				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end
				return colorpicker_tbl
			end

			function section:keybind(cfg)
				local keybind = {}
				local name = cfg.name or cfg.Name or "new keybind"
				local default = cfg.default or cfg.Default or nil
				local mode = cfg.mode or cfg.Mode or "Hold"
				local blacklist = cfg.blacklist or cfg.Blacklist or {}

				local flag = cfg.flag or Utility.NextFlag()
				local callback = cfg.callback or function() end
				local key_mode = mode

				local holder = Library:Create(
					"Square",
					{ Transparency = 0, ZIndex = 15, Size = UDim2.new(1, 0, 0, 6), Parent = section_content }
				)

				local title = Library:Create("Text", {
					Text = name,
					Font = Drawing.Fonts.Plex,
					Size = 13,
					Position = UDim2.new(0, 20, 0, -5),
					Theme = "Text",
					ZIndex = 14,
					Outline = false,
					Parent = holder,
				})

				local keybindname = key_name or ""

				local keytext = Library:Create("Text", {
					Font = Drawing.Fonts.Plex,
					Size = 13,
					Theme = "Un-Selected_Text",
					Position = UDim2.new(1, -40, 0, -5),
					ZIndex = 14,
					Parent = holder,
					Outline = false,
					Center = true,
				})

				local key
				local state = false
				local binding

				local function set(newkey)
					if c then
						c:Disconnect()
						if flag then
							Library.Flags[flag] = false
						end
						callback(false)
					end
					if tostring(newkey):find("Enum.KeyCode.") then
						newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
					elseif tostring(newkey):find("Enum.UserInputType.") then
						newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
					end

					if newkey ~= nil and not table.find(blacklist, newkey) then
						key = newkey

						local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

						keytext.Text = "[" .. text .. "]"
						Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
					else
						key = nil

						local text = "-"

						keytext.Text = "[" .. text .. "]"
						Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
					end

					if bind ~= "" or bind ~= nil then
						state = false
						if flag then
							Library.Flags[flag] = state
						end
						callback(false)
					end
				end

				local function setkey(newkey)
					if tostring(newkey):find("Enum.KeyCode.") then
						newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
					elseif tostring(newkey):find("Enum.UserInputType.") then
						newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
					end

					if newkey ~= nil and not table.find(blacklist, newkey) then
						key = newkey
						Library.Flags[flag .. "_KEY"] = newkey

						local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

						keytext.Text = "[" .. text .. "]"
						Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
					else
						key = nil
						Library.Flags[flag .. "_KEY"] = nil

						local text = "-"

						keytext.Text = "[" .. text .. "]"
						Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
					end
				end

				Library:Connect(InputService.InputBegan, function(inp)
					if (inp.KeyCode == key or inp.UserInputType == key) and not binding then
						if key_mode == "Hold" then
							if flag then
								Library.Flags[flag] = true
							end
							c = Library:Connect(RunService.RenderStepped, function()
								if callback then
									callback(true)
								end
							end)
						elseif key_mode == "Toggle" then
							state = not state
							if flag then
								Library.Flags[flag] = state
							end
							callback(state)
						else
							callback()
						end
					end
				end)

				Flags[flag .. "_KEY"] = setkey

				set(default)

				holder.MouseButton1Click:Connect(function()
					if not binding then
						keytext.Text = "[-]"
						Library:ChangeObjectTheme(keytext, "Accent")

						binding = Library:Connect(InputService.InputBegan, function(input, gpe)
							set(
								input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
									or input.UserInputType
							)
							setkey(
								input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
									or input.UserInputType
							)
							Library:Disconnect(binding)
							task.wait()
							binding = nil
						end)
					end
				end)

				Library:Connect(InputService.InputEnded, function(inp)
					if key_mode == "Hold" then
						if key ~= "" or key ~= nil then
							if inp.KeyCode == key or inp.UserInputType == key then
								if c then
									c:Disconnect()
									if flag then
										Library.Flags[flag] = false
									end
									if callback then
										callback(false)
									end
								end
							end
						end
					end
				end)

				local keybindtypes = {}

				function keybindtypes:set(newkey)
					set(newkey)
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return keybindtypes
			end

			function section:textbox(cfg)
				local textbox_tbl = {}
				local placeholder = cfg.placeholder or cfg.Placeholder or "new textbox"
				local default = cfg.Default or cfg.default or ""
				local middle = cfg.middle or cfg.Middle or false

				local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
				local callback = cfg.callback or function() end

				local holder = Library:Create("Square", {
					Transparency = 0,
					ZIndex = 14,
					Size = UDim2.new(1, 0, 0, 22),
					Parent = section_content,
					Thickness = 1,
				})
				local textbox = Library:Create("Square", {
					Filled = true,
					Visible = true,
					Thickness = 0,
					Color = Color3.fromRGB(19, 19, 19),
					Size = UDim2.new(1, -50, 0, 15),
					Position = UDim2.new(0, 23, 1, -17),
					ZIndex = 14,
					Parent = holder,
				})

				holder.MouseEnter:Connect(function()
					textbox.Color = Color3.fromRGB(22, 22, 22)
				end)

				holder.MouseLeave:Connect(function()
					textbox.Color = Color3.fromRGB(19, 19, 19)
				end)

				local outline1 = Library:Outline(textbox, Color3.fromRGB(44, 44, 44), 14)
				Library:Outline(outline1, Color3.new(0, 0, 0), 14)

				local text = Library:Create("Text", {
					Text = default,
					Transparency = 1,
					Visible = true,
					Parent = textbox,
					Theme = "Text",
					ZIndex = 14,
					Center = true,
					Position = UDim2.new(0.5, 0, 0, 1),
					Font = 2,
					Size = 13,
					Outline = true,
				})
				local placeholder = Library:Create("Text", {
					Text = placeholder,
					Transparency = 1,
					Visible = true,
					Parent = textbox,
					Theme = "Un-Selected_Text",
					ZIndex = 14,
					Center = true,
					Position = UDim2.new(0.5, 0, 0, 1),
					Font = 2,
					Size = 13,
					Outline = true,
				})

				Library.ObjectTextbox(textbox, text, function(str)
					if str == "" then
						placeholder.Visible = true
						text.Visible = false
					else
						placeholder.Visible = false
						text.Visible = true
					end
				end, function(str)
					Library.Flags[flag] = str
					callback(str)
				end)

				local function set(str)
					text.Visible = str ~= ""
					placeholder.Visible = str == ""

					text.Text = str
					Library.Flags[flag] = str
					callback(str)
				end

				set(default)

				function textbox_tbl:Set(str)
					set(str)
				end
				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end
				return textbox_tbl
			end

			function section:preview(cfg)
				local esp_preview = {}
				local all_enabled = cfg.toggled or false
				local maincolor = cfg.main_color or Color3.fromRGB(0, 255, 0)
				local emptycolor = cfg.empty_color or Color3.fromRGB(255, 0, 0)
				local healthamount = 100

				local holder = Library:Create("Square", {
					Parent = section_content,
					Visible = true,
					Transparency = 0,
					Size = UDim2.new(1, 0, 0, 285),
					Thickness = 1,
					Filled = false,
					ZIndex = 14,
				})

				local preview_frame = Library:Create("Square", {
					Parent = holder,
					Visible = true,
					Transparency = 1,
					Color = Color3.fromRGB(13, 13, 13),
					Size = UDim2.new(1, 0, 1, 0),
					Thickness = 1,
					Filled = true,
					ZIndex = 15,
				})
				do
					local outline = Library:Outline(preview_frame, Color3.fromRGB(37, 37, 37), 14)
					Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
				end

				local esp_head = Library:Create("Square", {
					Parent = preview_frame,
					Size = UDim2.new(0, 44, 0, 39),
					Position = UDim2.new(0, 86, 0, 45),
					Color = Color3.fromRGB(245, 245, 245),
					Thickness = 1,
					Filled = true,
					ZIndex = 16,
				})
				local esp_head_outline = Library:Outline(esp_head, Color3.fromRGB(0, 0, 0), 15)

				local esp_torso = Library:Create("Square", {
					Parent = preview_frame,
					Size = UDim2.new(0, 146, 0, 77),
					Position = UDim2.new(0, 34, 0, 85),
					Color = Color3.fromRGB(245, 245, 245),
					Thickness = 1,
					Filled = true,
					ZIndex = 16,
				})
				local esp_torso_outline = Library:Outline(esp_torso, Color3.fromRGB(0, 0, 0), 15)

				local esp_legs = Library:Create("Square", {
					Parent = preview_frame,
					Size = UDim2.new(0, 72, 0, 78),
					Position = UDim2.new(0, 72, 0, 163),
					Color = Color3.fromRGB(245, 245, 245),
					Thickness = 1,
					Filled = true,
					ZIndex = 16,
				})
				local esp_legs_outline = Library:Outline(esp_legs, Color3.fromRGB(0, 0, 0), 15)

				local esp_bounding_box = Library:Create("Square", {
					Visible = false,
					Parent = preview_frame,
					Size = UDim2.new(0, 195, 0, 240),
					Position = UDim2.new(0, 13.4, 0, 20),
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 1,
					Filled = false,
					ZIndex = 16,
				})
				local esp_bounding_box_outline = Library:Outline(esp_bounding_box, Color3.fromRGB(0, 0, 0), 16)

				local esp_health_bar_outline = Library:Create("Square", {
					Visible = false,
					Parent = preview_frame,
					Size = UDim2.new(0, 3, 0, 240),
					Position = UDim2.new(0, 6, 0, 20),
					Color = Color3.fromRGB(0, 0, 0),
					Thickness = 1,
					Filled = true,
					ZIndex = 16,
				})
				local esp_health_bar_outline_2 = Library:Outline(esp_health_bar_outline, Color3.new(0, 0, 0), 16)
				local esp_health_bar = Library:Create("Square", {
					Parent = esp_health_bar_outline,
					Size = UDim2.new(1, 0, 1, 0),
					Color = Color3.fromRGB(0, 255, 42),
					Thickness = 1,
					Filled = true,
					ZIndex = 16,
					Position = UDim2.new(0, 0, 1, 0),
				})
				local esp_health_text = Library:Create("Text", {
					Text = tostring("<- " .. healthamount),
					Parent = esp_health_bar,
					Visible = true,
					Transparency = 1,
					Color = maincolor,
					Size = 13,
					Center = false,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(1, 0, 0, 0),
					ZIndex = 16,
				})

				local esp_name = Library:Create("Text", {
					Text = "player",
					Parent = preview_frame,
					Visible = false,
					Transparency = 1,
					Color = Color3.fromRGB(255, 255, 255),
					Size = 13,
					Center = true,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0, 110, 0, 3),
					ZIndex = 16,
				})
				local esp_distance = Library:Create("Text", {
					Text = "0 meters",
					Parent = preview_frame,
					Visible = false,
					Transparency = 1,
					Color = Color3.fromRGB(255, 255, 255),
					Size = 13,
					Center = true,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0, 110, 0, 260),
					ZIndex = 16,
				})
				local esp_weapon = Library:Create("Text", {
					Text = "weapon",
					Parent = preview_frame,
					Visible = false,
					Transparency = 1,
					Color = Color3.fromRGB(255, 255, 255),
					Size = 13,
					Center = true,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0, 110, 0, 270),
					ZIndex = 16,
				})

				function esp_preview:set_health(amount)
					local value = amount / 100
					healthamount = amount / 100
					esp_health_bar.Size = UDim2.new(1, 0, 0, -(esp_health_bar_outline.Size.Y.Offset * value))
					esp_health_bar.Color = emptycolor:Lerp(maincolor, amount / 100)
					esp_health_text.Text = tostring("<- " .. math.floor(amount / 100 * 100))
					esp_health_text.Color = emptycolor:Lerp(maincolor, amount / 100)
					esp_health_text.Position = UDim2.new(1, 0, 0, -(esp_health_bar_outline.Size.Y.Offset * value) - 6)
				end

				function esp_preview:set_health_colors(type, color)
					if type == "main" then
						maincolor = color
						esp_health_bar.Color = emptycolor:Lerp(maincolor, healthamount)
						esp_health_text.Color = emptycolor:Lerp(maincolor, healthamount)
					elseif type == "empty" then
						emptycolor = color
						esp_health_bar.Color = emptycolor:Lerp(maincolor, healthamount)
						esp_health_text.Color = emptycolor:Lerp(maincolor, healthamount)
					end
				end

				function esp_preview:set_visibility(element, state)
					if element == "box" then
						esp_bounding_box.Visible = state
					elseif element == "healthbar" then
						esp_health_bar_outline.Visible = state
					elseif element == "name" then
						esp_name.Visible = state
					elseif element == "distance" then
						esp_distance.Visible = state
						if esp_weapon.Visible and esp_distance.Visible == false then
							esp_weapon.Position = UDim2.new(0, 110, 0, 260)
						else
							esp_weapon.Position = UDim2.new(0, 110, 0, 270)
						end
					elseif element == "weapon" then
						esp_weapon.Visible = state
						if esp_weapon.Visible and esp_distance.Visible == false then
							esp_weapon.Position = UDim2.new(0, 110, 0, 260)
						else
							esp_weapon.Position = UDim2.new(0, 110, 0, 270)
						end
					end
				end

				function esp_preview:set_color(element, state)
					if element == "box" then
						esp_bounding_box.Color = state
					elseif element == "box outline" then
						esp_bounding_box_outline.Color = state
					elseif element == "healthbar outline" then
						esp_health_bar_outline.Color = state
						esp_health_bar_outline_2.Color = state
					elseif element == "name" then
						esp_name.Color = state
					elseif element == "name outline" then
						esp_name.OutlineColor = state
					elseif element == "distance" then
						esp_distance.Color = state
					elseif element == "distance outline" then
						esp_distance.OutlineColor = state
					elseif element == "weapon" then
						esp_weapon.Color = state
					elseif element == "weapon outline" then
						esp_weapon.OutlineColor = state
					end
				end

				if size == "auto" then
					section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
				end

				return esp_preview
			end

			return section
		end

		function page:multisection(cfg)
			local multisection = { buttons = {}, sections = {}, lines = {}, titles = {} }
			local name = cfg.name or cfg.Name or "Page"
			local side = cfg.side == "left" and left
				or cfg.Side == "Left" and left
				or cfg.side == "right" and right
				or cfg.Side == "Right" and right
				or left
			local override = cfg.override or false
			local offset = cfg.offset or 0
			local size = cfg.size or cfg.Size or 200

			local section_holder = Library:Create("Square", {
				Parent = override and page_holder or side,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(19, 19, 19),
				Size = size ~= "auto" and UDim2.new(1, 0, 0, size) or UDim2.new(1, 0, 0, 28),
				Position = override and UDim2.new(0, 0, 0, offset) or UDim2.new(0, 0, 0, 0),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(section_holder, Color3.fromRGB(37, 37, 37), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local section_title = Library:Create("Text", {
				Text = name,
				Parent = section_holder,
				Visible = true,
				Transparency = 1,
				Theme = "Text",
				Size = 13,
				Center = false,
				Outline = false,
				Font = Drawing.Fonts.Plex,
				Position = UDim2.new(0, 11, 0, -8),
				ZIndex = 14,
			})

			local sections_holder = Library:Create("Square", {
				Parent = section_holder,
				Visible = true,
				Transparency = 1,
				Color = Color3.fromRGB(13, 13, 13),
				Size = UDim2.new(1, -20, 0, 24),
				Position = UDim2.new(0, 10, 0, 10),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})
			do
				local outline = Library:Outline(sections_holder, Color3.fromRGB(32, 32, 32), 14)
				Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
			end

			local sections_holder_inline = Library:Create("Square", {
				Parent = sections_holder,
				Visible = true,
				Transparency = 0,
				Size = UDim2.new(1, -8, 1, -4),
				Position = UDim2.new(0, 4, 0, 2),
				Thickness = 1,
				Filled = true,
				ZIndex = 14,
			})

			local function fix_pos()
				window_outline.Position = UDim2.new(
					window_outline.Position.X.Scale,
					window_outline.Position.X.Offset,
					window_outline.Position.Y.Scale,
					window_outline.Position.Y.Offset
				)
			end

			function multisection:fix()
				if size == "auto" then
					window_outline.Position = UDim2.new(
						window_outline.Position.X.Scale,
						window_outline.Position.X.Offset,
						window_outline.Position.Y.Scale,
						window_outline.Position.Y.Offset
					)
				end
			end

			function multisection:section(cfg)
				local section = {}
				local name = cfg.name or cfg.Name or "Section"
				local open = cfg.default or cfg.Default or false

				local button_holder = Library:Create("Square", {
					Parent = sections_holder_inline,
					Visible = true,
					Transparency = 0,
					Thickness = 1,
					Filled = true,
					ZIndex = 14,
				})
				table.insert(self.buttons, button_holder)

				local button_accent = Library:Create("Square", {
					Parent = button_holder,
					Visible = true,
					Transparency = 1,
					Theme = "Un-Selected",
					Size = UDim2.new(1, -6, 0, 2),
					Position = UDim2.new(0, 3, 1, -2),
					Thickness = 1,
					Filled = true,
					ZIndex = 15,
				})
				do
					Library:Outline(button_accent, Color3.new(0, 0, 0), 14)
					local gradient = Library:Create("Image", {
						Data = Images.gradient,
						Transparency = 1,
						Visible = true,
						Parent = button_accent,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 15,
					})
					table.insert(self.lines, button_accent)
				end

				local button_title = Library:Create("Text", {
					Text = name,
					Parent = button_holder,
					Visible = true,
					Transparency = 1,
					Theme = "Un-Selected_Text",
					Size = 13,
					Center = true,
					Outline = true,
					Font = Drawing.Fonts.Plex,
					Position = UDim2.new(0.5, 0, 0, 2),
					ZIndex = 15,
				})
				table.insert(self.titles, button_title)

				local section_content = Library:Create("Square", {
					Visible = false,
					Transparency = 0,
					Size = override and UDim2.new(0.5, -32, 1, -45) or UDim2.new(1, -32, 1, -45),
					Position = UDim2.new(0, 16, 0, 45),
					Parent = section_holder,
					ZIndex = 14,
				})
				section_content:AddListLayout(9)
				table.insert(self.sections, section_content)

				local section_content1 = Library:Create("Square", {
					Visible = false,
					Transparency = 0,
					Size = override and UDim2.new(0.5, -32, 1, -45) or UDim2.new(1, -32, 1, -45),
					Position = UDim2.new(0.5, 16, 0, 45),
					Parent = section_holder,
					ZIndex = 14,
				})
				section_content1:AddListLayout(9)
				table.insert(self.sections, section_content1)

				for _, v in next, self.buttons do
					v.Size = UDim2.new(1 / #self.buttons, _ == 1 and 1 or _ == #self.buttons and -2 or -1, 1, 0)
					v.Position = UDim2.new(1 / (#self.buttons / (_ - 1)), _ == 1 and 0 or 2, 0, 0)
				end

				if open then
					Library:ChangeObjectTheme(button_accent, "Accent")
					Library:ChangeObjectTheme(button_title, "Accent")
					section_content.Visible = true
					section_content1.Visible = true
					fix_pos()
				end

				Library:Connect(button_holder.MouseButton1Click, function()
					for _, v in next, self.lines do
						if v ~= button_accent then
							Library:ChangeObjectTheme(v, "Un-Selected")
						end
					end

					for _, v in next, self.titles do
						if v ~= button_title then
							Library:ChangeObjectTheme(v, "Un-Selected_Text")
						end
					end

					for _, v in next, self.sections do
						if v ~= section_content then
							v.Visible = false
						end
						if v ~= section_content1 then
							v.Visible = false
						end
					end

					if size == "auto" then
						section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
						section_holder.Size = UDim2.new(1, 0, 0, section_content1.AbsoluteContentSize + 55)
					end

					Library:ChangeObjectTheme(button_accent, "Accent")
					Library:ChangeObjectTheme(button_title, "Accent")
					section_content.Visible = true
					section_content1.Visible = true
				end)
				if override then
					local div = Library:Create("Square", {
						Parent = section_holder,
						Visible = true,
						Transparency = 1,
						Color = Color3.fromRGB(37, 37, 37),
						Position = UDim2.new(0.5, 0, 0, 45),
						Size = UDim2.new(0, 1, 1, -50),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
					})
					function section:preview1(cfg)
						local preview = {}
						local side = cfg.side == "left" and section_content
							or cfg.side == "right" and section_content1
							or section_content
						local preview_frame = Library:Create("Square", {
							Parent = side,
							Visible = true,
							Transparency = 0,
							Color = Color3.fromRGB(13, 13, 13),
							Size = UDim2.new(1, 0, 0, 220),
							Position = UDim2.new(0, 0, 0, 0),
							Thickness = 1,
							Filled = true,
							ZIndex = 15,
						})
						do
							local accent = Library:Create("Square", {
								Parent = preview_frame,
								Visible = true,
								Transparency = 1,
								Theme = "Accent",
								Size = UDim2.new(0, 140, 0, 2),
								Position = UDim2.new(0.5, -70, 1, -6),
								Thickness = 1,
								Filled = true,
								ZIndex = 15,
							})
							Library:Outline(accent, Color3.new(0, 0, 0), 14)
							local gradient = Library:Create("Image", {
								Data = Images.gradient,
								Transparency = 1,
								Visible = true,
								Parent = accent,
								Size = UDim2.new(1, 0, 1, 0),
								ZIndex = 15,
							})
						end

						local head = Library:Create("Square", {
							Parent = preview_frame,
							Size = UDim2.new(0, 44, 0, 39),
							Position = UDim2.new(0.5, -22, -0.175, 50),
							Theme = "Text",
							Thickness = 1,
							Filled = true,
							ZIndex = 16,
						})
						local head_outline = Library:Outline(head, Color3.fromRGB(0, 0, 0), 15)

						local larm = Library:Create("Square", {
							Parent = preview_frame,
							Size = UDim2.new(0, 36, 0, 77),
							Position = UDim2.new(0.5, -73, -0.175, 90),
							Theme = "Text",
							Thickness = 1,
							Filled = true,
							ZIndex = 16,
						})
						local larm_outline = Library:Outline(larm, Color3.fromRGB(0, 0, 0), 15)

						local rarm = Library:Create("Square", {
							Parent = preview_frame,
							Size = UDim2.new(0, 36, 0, 77),
							Position = UDim2.new(0.5, 37, -0.175, 90),
							Theme = "Text",
							Thickness = 1,
							Filled = true,
							ZIndex = 16,
						})
						local rarm_outline = Library:Outline(rarm, Color3.fromRGB(0, 0, 0), 15)

						local torso = Library:Create("Square", {
							Parent = preview_frame,
							Size = UDim2.new(0, 72, 0, 77),
							Position = UDim2.new(0.5, -36, -0.175, 90),
							Theme = "Text",
							Thickness = 1,
							Filled = true,
							ZIndex = 16,
						})
						local torso_outline = Library:Outline(torso, Color3.fromRGB(0, 0, 0), 15)

						local legs = Library:Create("Square", {
							Parent = preview_frame,
							Size = UDim2.new(0, 72, 0, 78),
							Position = UDim2.new(0.5, -36, -0.175, 168),
							Theme = "Text",
							Thickness = 1,
							Filled = true,
							ZIndex = 16,
						})
						local legs_outline = Library:Outline(legs, Color3.fromRGB(0, 0, 0), 15)

						function preview:change_state(obj, state)
							if obj == "arms" then
								Library:ChangeObjectTheme(larm, state == true and "Accent" or "Un-Selected_Text")
								Library:ChangeObjectTheme(rarm, state == true and "Accent" or "Un-Selected_Text")
							elseif obj == "legs" then
								Library:ChangeObjectTheme(legs, state == true and "Accent" or "Un-Selected_Text")
							elseif obj == "torso" then
								Library:ChangeObjectTheme(torso, state == true and "Accent" or "Un-Selected_Text")
							elseif obj == "head" then
								Library:ChangeObjectTheme(head, state == true and "Accent" or "Un-Selected_Text")
							end
						end
						return preview
					end
				end

				function section:toggle(cfg)
					local toggle = { section = self, colors = 0 }
					local name = cfg.name or cfg.Name or "new toggle"
					local risky = cfg.risky or cfg.Risky or false
					local state = cfg.state or cfg.State or false

					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
					local callback = cfg.callback or cfg.Callback or function() end
					local toggled = false

					local holder = Library:Create("Square", {
						Parent = side,
						Visible = true,
						Transparency = 0,
						Size = UDim2.new(1, 0, 0, 6),
						Thickness = 1,
						Filled = false,
						ZIndex = 14,
					})

					local toggle_frame = Library:Create("Square", {
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Theme = "Toggle Background",
						Size = UDim2.new(0, 6, 0, 6),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
					})
					do
						local outline = Library:Outline(toggle_frame, Color3.fromRGB(0, 0, 0), 14)
					end
					local gradient = Library:Create("Image", {
						Data = Images.gradient,
						Transparency = 1,
						Visible = true,
						Parent = toggle_frame,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 14,
					})

					local toggle_title = Library:Create("Text", {
						Text = name,
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Theme = risky and "Risky Text" or "Text",
						Size = 13,
						Center = false,
						Outline = false,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 20, 0, -5),
						ZIndex = 14,
					})

					local function setstate()
						toggled = not toggled
						if toggled then
							Library:ChangeObjectTheme(toggle_frame, "Accent")
						else
							Library:ChangeObjectTheme(toggle_frame, "Toggle Background")
						end
						Library.Flags[flag] = toggled
						callback(toggled)
					end

					holder.MouseButton1Click:Connect(setstate)

					holder.MouseEnter:Connect(function()
						if not toggled then
							Library:ChangeObjectTheme(toggle_frame, "Toggle Background Highlight")
						end
					end)

					holder.MouseLeave:Connect(function()
						if not toggled then
							Library:ChangeObjectTheme(toggle_frame, "Toggle Background")
						end
					end)

					local function set(bool)
						bool = type(bool) == "boolean" and bool or false
						if toggled ~= bool then
							setstate()
						end
					end
					Flags[flag] = set
					set(state)

					function toggle:set(bool)
						set(bool)
					end

					function toggle:colorpicker(cfg)
						local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

						local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
						local callback = cfg.callback or function() end
						local defaultalpha = cfg.alpha or cfg.Alpha or 1
						local colorpicker_tbl = {}

						toggle.colors += 1
						local cp = Library.ObjectColorPicker(
							default,
							defaultalpha,
							holder,
							toggle.colors - 1,
							flag,
							callback,
							-6
						)
						function colorpicker_tbl:set(color)
							cp:set(color, false, true)
						end
						return colorpicker_tbl
					end

					function toggle:keybind(cfg)
						local keybind = {}
						local default = cfg.default or cfg.Default or nil
						local mode = cfg.mode or cfg.Mode or "Hold"
						local blacklist = cfg.blacklist or cfg.Blacklist or {}

						local flag = cfg.flag or Utility.NextFlag()
						local callback = cfg.callback or function() end
						local key_mode = mode

						local keyholder = Library:Create("Square", {
							Size = UDim2.new(0, 40, 1, 0),
							Position = UDim2.new(1, -60, 0, 0),
							Transparency = 0,
							ZIndex = 15,
							Parent = holder,
							Thickness = 1,
							Filled = false,
						})

						local keytext = Library:Create("Text", {
							Font = Drawing.Fonts.Plex,
							Size = 13,
							Theme = "Un-Selected_Text",
							Position = UDim2.new(1, -40, 0, -5),
							ZIndex = 14,
							Parent = holder,
							Outline = false,
							Center = true,
						})

						local key
						local state = false
						local binding

						local function set(newkey)
							if c then
								c:Disconnect()
								if flag then
									Library.Flags[flag] = false
								end
								callback(false)
							end
							if tostring(newkey):find("Enum.KeyCode.") then
								newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
							elseif tostring(newkey):find("Enum.UserInputType.") then
								newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
							end

							if newkey ~= nil and not table.find(blacklist, newkey) then
								key = newkey

								local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

								keytext.Text = "[" .. text .. "]"
								Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
							else
								key = nil

								local text = "-"

								keytext.Text = "[" .. text .. "]"
								Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
							end

							if bind ~= "" or bind ~= nil then
								state = false
								if flag then
									Library.Flags[flag] = state
								end
								callback(false)
							end
						end

						local function setkey(newkey)
							if tostring(newkey):find("Enum.KeyCode.") then
								newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
							elseif tostring(newkey):find("Enum.UserInputType.") then
								newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
							end

							if newkey ~= nil and not table.find(blacklist, newkey) then
								key = newkey
								Library.Flags[flag .. "_KEY"] = newkey

								local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

								keytext.Text = "[" .. text .. "]"
								Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
							else
								key = nil
								Library.Flags[flag .. "_KEY"] = nil

								local text = "-"

								keytext.Text = "[" .. text .. "]"
								Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
							end
						end

						Library:Connect(InputService.InputBegan, function(inp)
							if (inp.KeyCode == key or inp.UserInputType == key) and not binding then
								if key_mode == "Hold" then
									if flag then
										Library.Flags[flag] = true
									end
									c = Library:Connect(RunService.RenderStepped, function()
										if callback then
											callback(true)
										end
									end)
								elseif key_mode == "Toggle" then
									state = not state
									if flag then
										Library.Flags[flag] = state
									end
									callback(state)
								else
									callback()
								end
							end
						end)

						Flags[flag .. "_KEY"] = setkey

						set(default)

						keyholder.MouseButton1Click:Connect(function()
							if not binding then
								keytext.Text = "[-]"
								Library:ChangeObjectTheme(keytext, "Accent")

								binding = Library:Connect(InputService.InputBegan, function(input, gpe)
									set(
										input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
											or input.UserInputType
									)
									setkey(
										input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
											or input.UserInputType
									)
									Library:Disconnect(binding)
									task.wait()
									binding = nil
								end)
							end
						end)

						Library:Connect(InputService.InputEnded, function(inp)
							if key_mode == "Hold" then
								if key ~= "" or key ~= nil then
									if inp.KeyCode == key or inp.UserInputType == key then
										if c then
											c:Disconnect()
											if flag then
												Library.Flags[flag] = false
											end
											if callback then
												callback(false)
											end
										end
									end
								end
							end
						end)

						local keybindtypes = {}

						function keybindtypes:set(newkey)
							set(newkey)
						end

						return keybindtypes
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end

					return toggle
				end

				function section:divider(cfg)
					local divider = { section = self }
					local name = cfg.name or cfg.Name or "new divider"
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content

					local holder = Library:Create("Square", {
						Parent = side,
						Visible = true,
						Transparency = 0,
						Size = UDim2.new(1, 0, 0, 6),
						Thickness = 1,
						Filled = false,
						ZIndex = 14,
					})

					local div = Library:Create("Square", {
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Color = Color3.fromRGB(100, 100, 100),
						Size = UDim2.new(0, 6, 0, 1),
						Position = UDim2.new(0, 0, 0, 3),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
					})
					local title = Library:Create("Text", {
						Text = name,
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Color = Color3.fromRGB(100, 100, 100),
						Size = 13,
						Center = false,
						Outline = false,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 20, 0, -5),
						ZIndex = 14,
					})
					local div = Library:Create("Square", {
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Color = Color3.fromRGB(100, 100, 100),
						Size = UDim2.new(1, -Utility.TextLength(name, 2, 13).X - 45, 0, 1),
						Position = UDim2.new(0, 30 + Utility.TextLength(name, 2, 13).X, 0, 3),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
					})

					if size == "auto" then
						section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 5)
					end
					return divider
				end

				function section:slider(cfg)
					local slider = {}
					local name = cfg.name or cfg.Name or nil
					local min = cfg.min or cfg.minimum or 0
					local max = cfg.max or cfg.maximum or 100
					local allow = cfg.animation or false
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local fade_min = cfg.fade_min or min
					local fade_max = cfg.fade_max or max
					local suffix = cfg.suffix or cfg.Suffix or ""
					local text = cfg.text or ("[value]" .. suffix)
					local float = cfg.float or 1
					local default = cfg.default and math.clamp(cfg.default, min, max) or min
					if not cfg.flag then
						print(name)
					end
					local flag = cfg.flag or Utility.NextFlag()
					local callback = cfg.callback or function() end

					local holder = Library:Create("Square", {
						Parent = side,
						Visible = true,
						Transparency = 0,
						Size = name and UDim2.new(1, 0, 0, 22) or UDim2.new(1, 0, 0, 12),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
					})

					local slider_frame = Library:Create("Square", {
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Theme = "Toggle Background",
						Size = UDim2.new(1, -50, 0, 6),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
						Position = name and UDim2.new(0, 23, 0, 14) or UDim2.new(0, 23, 0, 3),
					})
					do
						local outline = Library:Outline(slider_frame, Color3.fromRGB(0, 0, 0), 14)
					end
					Library:Create("Image", {
						Data = Images.gradient,
						Transparency = 1,
						Visible = true,
						Parent = slider_frame,
						Size = UDim2.new(1, 0, 1, 0),
						ZIndex = 15,
					})

					if name then
						local slider_title = Library:Create("Text", {
							Text = name,
							Parent = holder,
							Visible = true,
							Transparency = 1,
							Theme = "Text",
							Size = 13,
							Center = false,
							Outline = false,
							Font = Drawing.Fonts.Plex,
							Position = UDim2.new(0, 20, 0, -2),
							ZIndex = 14,
						})
					end

					local slider_fill = Library:Create("Square", {
						Parent = slider_frame,
						Visible = true,
						Transparency = 1,
						Theme = "Accent",
						Size = UDim2.new(1, 0, 1, 0),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
						Position = UDim2.new(0, 0, 0, 0),
					})

					local slider_value = Library:Create("Text", {
						Text = text,
						Parent = slider_fill,
						Visible = true,
						Transparency = 1,
						Theme = "Text",
						Size = 13,
						Center = true,
						Outline = true,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(1, 0, 0.5, -2),
						ZIndex = 15,
					})

					local slider_drag = Library:Create("Square", {
						Parent = slider_frame,
						Visible = true,
						Transparency = 0,
						Size = UDim2.new(1, 0, 1, 0),
						Thickness = 1,
						Filled = true,
						ZIndex = 14,
						Position = UDim2.new(0, 0, 0, 0),
					})

					local function set(value)
						value = math.clamp(Utility.Round(value, float), min, max)

						slider_value.Text = text:gsub("%[value%]", string.format("%.14g", value))

						local sizeX = ((value - min) / (max - min))
						slider_fill.Size = UDim2.new(sizeX, 0, 1, 0)

						Library.Flags[flag] = value
						callback(value)
					end
					Flags[flag] = set
					set(default)

					local sliding = false

					local function slide(input)
						local sizeX = (input.Position.X - slider_frame.AbsolutePosition.X) / slider_frame.AbsoluteSize.X
						local value = ((max - min) * sizeX) + min

						set(value)
					end

					holder.MouseEnter:Connect(function()
						Library:ChangeObjectTheme(slider_frame, "Toggle Background Highlight")
					end)
					holder.MouseLeave:Connect(function()
						Library:ChangeObjectTheme(slider_frame, "Toggle Background")
					end)

					Library:Connect(slider_drag.InputBegan, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							sliding = true
							slide(input)
						end
					end)

					Library:Connect(slider_drag.InputEnded, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							sliding = false
						end
					end)

					Library:Connect(slider_fill.InputBegan, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							sliding = true
							slide(input)
						end
					end)

					Library:Connect(slider_fill.InputEnded, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							sliding = false
						end
					end)

					Library:Connect(InputService.InputChanged, function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement then
							if sliding then
								slide(input)
							end
						end
					end)

					if allow then
						local slider_question = Library:Create("Text", {
							Text = "?",
							Parent = holder,
							Visible = true,
							Transparency = 1,
							Theme = "Text",
							Size = 13,
							Center = false,
							Outline = false,
							Font = Drawing.Fonts.Plex,
							Position = UDim2.new(1, -36, 0, -2),
							ZIndex = 14,
						})
						local question_button = Library:Create("Square", {
							Filled = true,
							Thickness = 0,
							Parent = holder,
							Color = Color3.fromRGB(13, 13, 13),
							Size = UDim2.new(0, slider_question.TextBounds.X, 0, slider_question.TextBounds.Y),
							Position = UDim2.new(1, -36, 0, -2),
							Visible = true,
							Transparency = 0,
							ZIndex = 29,
						})

						local slider_window = Library:Create("Square", {
							Filled = true,
							Thickness = 0,
							Parent = slider_drag,
							Color = Color3.fromRGB(13, 13, 13),
							Size = UDim2.new(0, 205, 0, 107),
							Visible = false,
							Position = UDim2.new(1, -185, 1, 6),
							ZIndex = 29,
						})
						table.insert(FadeThings, slider_window)

						local outline3 = Library:Outline(slider_window, Color3.fromRGB(44, 44, 44))
						Library:Outline(outline3, Color3.fromRGB(0, 0, 0))

						local windowback = Library:Create("Square", {
							Filled = true,
							Thickness = 0,
							Parent = slider_window,
							Theme = "Accent",
							Size = UDim2.new(1, -2, 0, 1),
							Visible = true,
							Position = UDim2.new(0, 1, 0, 1),
							ZIndex = 29,
						})

						local window_page = Library:Create("Square", {
							Filled = false,
							Thickness = 0,
							Transparency = 0,
							Parent = slider_window,
							Color = Color3.fromRGB(0, 0, 0),
							Size = UDim2.new(1, -10, 1, -10),
							Position = UDim2.new(0, 5, 0, 25),
							Visible = true,
							ZIndex = 29,
						})
						window_page:AddListLayout(3)

						local slider_button = Library:Create("Square", {
							Filled = true,
							Thickness = 0,
							Parent = slider_window,
							Color = Color3.fromRGB(13, 13, 13),
							Size = UDim2.new(1, 0, 0, 17),
							Position = UDim2.new(0, 0, 0, 10),
							Visible = true,
							ZIndex = 29,
						})

						local isfading = false

						local fadetext = Library:Create("Text", {
							Text = "fading",
							Parent = slider_button,
							Visible = true,
							Transparency = 1,
							Theme = "Text",
							Size = 13,
							Center = true,
							Outline = false,
							Font = Drawing.Fonts.Plex,
							Position = UDim2.new(0.5, 0, 0, 1),
							ZIndex = 29,
						})

						local outline3 = Library:Outline(slider_window, Color3.fromRGB(44, 44, 44))
						Library:Outline(outline3, Color3.fromRGB(0, 0, 0))

						local startslide = Library.CreateSlider({
							parent = window_page,
							name = "start",
							flag = Library.Flags[flag .. "_FADING_START"],
							min = fade_min,
							max = fade_max,
							default = 0,
							callback = function(state)
								Library.Flags[flag .. "_FADING_START"] = state
							end,
						})

						local endslide = Library.CreateSlider({
							parent = window_page,
							name = "end",
							flag = Library.Flags[flag .. "_FADING_END"],
							min = fade_min,
							max = fade_max,
							default = 0,
							callback = function(state)
								Library.Flags[flag .. "_FADING_END"] = state
							end,
						})

						local speedslide = Library.CreateSlider({
							parent = window_page,
							name = "speed",
							flag = Library.Flags[flag .. "_FADING_SPEED"],
							min = 0,
							max = 500,
							default = 100,
							callback = function(state)
								Library.Flags[flag .. "_FADING_SPEED"] = state
							end,
						})

						local function setfade(state)
							Library.Flags[flag .. "_FADING"] = state
						end

						question_button.MouseButton1Click:Connect(function()
							for i, v in next, FadeThings do
								if v ~= slider_window then
									v.Visible = false
								end
							end
							slider_window.Visible = not slider_window.Visible
						end)
						question_button.MouseEnter:Connect(function()
							Library:ChangeObjectTheme(slider_question, "Accent")
						end)
						question_button.MouseLeave:Connect(function()
							Library:ChangeObjectTheme(slider_question, "Text")
						end)
						slider_button.MouseButton1Click:Connect(function()
							isfading = not isfading
							setfade(isfading)
							Library:ChangeObjectTheme(fadetext, isfading and "Accent" or "Text")
						end)
						task.spawn(function()
							while task.wait() do
								local val = nil
								if Library.Flags[flag .. "_FADING"] then
									local sinwave =
										math.abs(math.sin(os.clock() * (Library.Flags[flag .. "_FADING_SPEED"] / 50)))

									val = Utility.NumberLerp(sinwave, {
										[1] = {
											start = 0,
											number = Library.Flags[flag .. "_FADING_START"],
										},
										[2] = {
											start = 1,
											number = Library.Flags[flag .. "_FADING_END"] + 1,
										},
									})
								end
								if val ~= nil then
									set(val)
								end
							end
						end)
						Flags[flag .. "_FADING"] = setfade
					end

					function slider:set(value)
						set(value)
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end

					return slider
				end

				function section:screen(cfg)
					local screen = { section = self }
					local name = cfg.name or cfg.Name or "no content."
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content

					local holder = Library:Create("Square", {
						Parent = side,
						Visible = true,
						Transparency = 0,
						Size = UDim2.new(1, 0, 1, 0),
						Thickness = 1,
						Filled = false,
						ZIndex = 14,
					})

					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Color = Color3.fromRGB(100, 100, 100),
						ZIndex = 14,
						Center = true,
						Outline = false,
						Parent = holder,
					})
					return screen
				end

				function section:dropdown(cfg)
					local dropdown = {}
					local name = cfg.name or cfg.Name or nil
					local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
					local default = cfg.default or cfg.Default or content[1] or nil
					local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
					local scrollable = cfg.scrollable or cfg.Scrollable or false
					local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10
					local flag = cfg.flag or Utility.NextFlag()
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local callback = cfg.callback or function() end
					if not max and type(default) == "table" then
						default = nil
					end
					if max and default == nil then
						default = {}
					end
					if type(default) == "table" then
						if max then
							for i, opt in next, default do
								if not table.find(content, opt) then
									table.remove(default, i)
								elseif i > max then
									table.remove(default, i)
								end
							end
						else
							default = nil
						end
					elseif default ~= nil then
						if not table.find(content, default) then
							default = nil
						end
					end

					local holder = Library:Create("Square", {
						Transparency = 0,
						ZIndex = 14,
						Size = UDim2.new(1, 0, 0, name and 32 or 19),
						Parent = side,
						Thickness = 1,
					})

					if name then
						local title = Library:Create("Text", {
							Text = name,
							Font = Drawing.Fonts.Plex,
							Size = 13,
							Position = UDim2.new(0, 20, 0, -2),
							Theme = "Text",
							ZIndex = 14,
							Outline = false,
							Parent = holder,
						})
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
					end

					return Library.CreateDropdown(
						holder,
						content,
						flag,
						callback,
						default,
						max,
						scrollable,
						scrollingmax
					)
				end

				function section:list(cfg)
					local list = {}
					local name = cfg.name or cfg.Name or nil
					local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
					local default = cfg.default or cfg.Default or content[1] or nil
					local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
					local scrollable = cfg.scrollable or cfg.Scrollable or false
					local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10

					local flag = cfg.flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					if not max and type(default) == "table" then
						default = nil
					end
					if max and default == nil then
						default = {}
					end
					if type(default) == "table" then
						if max then
							for i, opt in next, default do
								if not table.find(content, opt) then
									table.remove(default, i)
								elseif i > max then
									table.remove(default, i)
								end
							end
						else
							default = nil
						end
					elseif default ~= nil then
						if not table.find(content, default) then
							default = nil
						end
					end

					local holder = Library:Create("Square", {
						Transparency = 0,
						ZIndex = 18,
						Size = UDim2.new(1, 0, 0, name and 32 or 19),
						Parent = section_content,
						Thickness = 1,
					})

					if name then
						local title = Library:Create("Text", {
							Text = name,
							Font = Drawing.Fonts.Plex,
							Size = 13,
							Position = UDim2.new(0, 20, 0, -2),
							Theme = "Text",
							ZIndex = 14,
							Outline = false,
							Parent = holder,
						})
					end

					if size == "auto" then
						section_holder.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 20)
					end

					return Library.CreateList(holder, content, flag, callback, default, max, scrollable, scrollingmax)
				end

				function section:multibox(cfg)
					local multibox = {}
					local name = cfg.name or cfg.Name or nil
					local default = cfg.default or cfg.Default or nil
					local content = type(cfg.options or cfg.Options) == "table" and cfg.options or cfg.Options or {}
					local max = cfg.max or cfg.Max and (cfg.max > 1 and cfg.max) or nil
					local scrollable = cfg.scrollable or cfg.Scrollable or false
					local scrollingmax = cfg.scrollingmax or cfg.ScrollingMax or 10
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local flag = cfg.flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					if not max and type(default) == "table" then
						default = nil
					end
					if max and default == nil then
						default = {}
					end
					if type(default) == "table" then
						if max then
							for i, opt in next, default do
								if not table.find(content, opt) then
									table.remove(default, i)
								elseif i > max then
									table.remove(default, i)
								end
							end
						else
							default = nil
						end
					elseif default ~= nil then
						if not table.find(content, default) then
							default = nil
						end
					end

					local holder = Library:Create("Square", {
						Transparency = 0,
						ZIndex = 14,
						Size = UDim2.new(1, 0, 0, name and 32 or 19),
						Parent = side,
						Thickness = 1,
					})

					if name then
						local title = Library:Create("Text", {
							Text = name,
							Font = Drawing.Fonts.Plex,
							Size = 13,
							Position = UDim2.new(0, 20, 0, -2),
							Theme = "Text",
							ZIndex = 14,
							Outline = false,
							Parent = holder,
						})
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end

					return Library.CreateMultibox(
						holder,
						content,
						flag,
						callback,
						default,
						max,
						scrollable,
						scrollingmax
					)
				end

				function section:button(cfg)
					local button_tbl = {}
					local name = cfg.name or cfg.Name or "Button"
					local callback = cfg.callback or cfg.Callback or function() end
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local button_confirm = cfg.confirm or cfg.Confirm or false

					local holder = Library:Create(
						"Square",
						{ Transparency = 0, ZIndex = 14, Size = UDim2.new(1, 0, 0, 22), Parent = side, Thickness = 1 }
					)
					local ButtonFrame = Library:Create("Square", {
						Filled = true,
						Visible = true,
						Thickness = 0,
						Color = Color3.fromRGB(25, 25, 25),
						Size = UDim2.new(1, -50, 0, 17),
						Position = UDim2.new(0, 23, 1, -22),
						ZIndex = 14,
						Parent = holder,
					})

					holder.MouseEnter:Connect(function()
						ButtonFrame.Color = Color3.fromRGB(27, 27, 27)
					end)

					holder.MouseLeave:Connect(function()
						ButtonFrame.Color = Color3.fromRGB(25, 25, 25)
					end)

					local outline1 = Library:Outline(ButtonFrame, Color3.fromRGB(44, 44, 44), 14)
					Library:Outline(outline1, Color3.new(0, 0, 0), 14)

					local icon = Library:Create("Text", {
						Text = name,
						Transparency = 1,
						Visible = true,
						Parent = ButtonFrame,
						Theme = "Text",
						ZIndex = 16,
						Center = true,
						Position = UDim2.new(0.5, 0, 0, 1),
						Font = 2,
						Size = 13,
						Outline = true,
					})

					local clicked, counting = false, false
					Library:Connect(ButtonFrame.MouseButton1Click, function()
						task.spawn(function()
							if button_confirm then
								if clicked then
									clicked = false
									counting = false
									Library:ChangeObjectTheme(ButtonFrame, "Text")
									ButtonFrame.Text = button_name
									callback()
								else
									clicked = true
									counting = true
									for i = 3, 1, -1 do
										if not counting then
											break
										end
										ButtonFrame.Text = "confirm " .. button_name .. "? " .. tostring(i)
										Library:ChangeObjectTheme(ButtonFrame, "Accent")
										wait(1)
									end
									clicked = false
									counting = false
									Library:ChangeObjectTheme(ButtonFrame, "Text")
									ButtonFrame.Text = button_name
								end
							else
								callback()
							end
						end)
					end)
					Library:Connect(ButtonFrame.MouseButton1Down, function()
						Library:ChangeObjectTheme(icon, "Accent")
					end)
					Library:Connect(ButtonFrame.MouseButton1Up, function()
						Library:ChangeObjectTheme(icon, "Text")
					end)

					function button_tbl:button(cfg)
						local name = cfg.name or cfg.Name or "Button"
						local callback = cfg.callback or cfg.Callback or function() end
						ButtonFrame.Size = UDim2.new(1 / 2, -40, 0, 17)

						local ButtonFrame_2 = Library:Create("Square", {
							Filled = true,
							Visible = true,
							Thickness = 0,
							Color = Color3.fromRGB(25, 25, 25),
							Size = UDim2.new(1 / 2, -40, 0, 17),
							Position = UDim2.new(0.5, 13, 1, -22),
							ZIndex = 14,
							Parent = holder,
						})

						holder.MouseEnter:Connect(function()
							ButtonFrame_2.Color = Color3.fromRGB(27, 27, 27)
						end)

						holder.MouseLeave:Connect(function()
							ButtonFrame_2.Color = Color3.fromRGB(25, 25, 25)
						end)

						local outline1 = Library:Outline(ButtonFrame_2, Color3.fromRGB(44, 44, 44), 14)
						Library:Outline(outline1, Color3.new(0, 0, 0), 14)

						local icon = Library:Create("Text", {
							Text = name,
							Transparency = 1,
							Visible = true,
							Parent = ButtonFrame_2,
							Theme = "Text",
							ZIndex = 16,
							Center = true,
							Position = UDim2.new(0.5, 0, 0, 1),
							Font = 2,
							Size = 13,
							Outline = true,
						})

						local clicked, counting = false, false
						Library:Connect(ButtonFrame_2.MouseButton1Click, function()
							task.spawn(function()
								if button_confirm then
									if clicked then
										clicked = false
										counting = false
										Library:ChangeObjectTheme(icon, "Text")
										icon.Text = button_name
										callback()
									else
										clicked = true
										counting = true
										for i = 3, 1, -1 do
											if not counting then
												break
											end
											icon.Text = "confirm " .. button_name .. "? " .. tostring(i)
											Library:ChangeObjectTheme(icon, "Accent")
											wait(1)
										end
										clicked = false
										counting = false
										Library:ChangeObjectTheme(icon, "Text")
										icon.Text = button_name
									end
								else
									callback()
								end
							end)
						end)
						Library:Connect(ButtonFrame_2.MouseButton1Down, function()
							Library:ChangeObjectTheme(icon, "Accent")
						end)
						Library:Connect(ButtonFrame_2.MouseButton1Up, function()
							Library:ChangeObjectTheme(icon, "Text")
						end)
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end
					return button_tbl
				end

				function section:colorpicker(cfg)
					local colorpicker_tbl = {}
					local name = cfg.name or cfg.Name or "new colorpicker"
					local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

					local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local callback = cfg.callback or function() end
					local allow_tool = cfg.tooltip or cfg.ToolTip or false
					local defaultalpha = cfg.alpha or cfg.Alpha or 1

					local holder = Library:Create("Square", {
						Transparency = 0,
						Filled = true,
						Thickness = 1,
						Size = UDim2.new(1, 0, 0, 6),
						ZIndex = 14,
						Parent = side,
					})

					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 20, 0, -5),
						Theme = "Text",
						ZIndex = 14,
						Outline = false,
						Parent = holder,
					})

					local colorpickers = 0

					local colorpickertypes =
						Library.ObjectColorPicker(default, defaultalpha, holder, colorpickers, flag, callback, -6)
					function colorpickertypes:new_colorpicker(cfg)
						colorpickers = colorpickers + 1
						local cp_tbl = {}

						Utility.Table(cfg)
						local default = cfg.default or cfg.Default or Color3.fromRGB(255, 0, 0)

						local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
						local callback = cfg.callback or function() end
						local defaultalpha = cfg.alpha or cfg.Alpha or 1

						local cp =
							Library.ObjectColorPicker(default, defaultalpha, holder, colorpickers, flag, callback, -6)
						function cp_tbl:set(color)
							cp:set(color, false, true)
						end
						return cp_tbl
					end

					function colorpicker_tbl:set(color)
						colorpickertypes:set(color, false, true)
					end
					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end
					return colorpicker_tbl
				end

				function section:keybind(cfg)
					local keybind = {}
					local name = cfg.name or cfg.Name or "new keybind"
					local default = cfg.default or cfg.Default or nil
					local mode = cfg.mode or cfg.Mode or "Hold"
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local blacklist = cfg.blacklist or cfg.Blacklist or {}
					local flag = cfg.flag or Utility.NextFlag()
					local callback = cfg.callback or function() end
					local key_mode = mode

					local holder = Library:Create(
						"Square",
						{ Transparency = 0, ZIndex = 15, Size = UDim2.new(1, 0, 0, 6), Parent = side }
					)

					local title = Library:Create("Text", {
						Text = name,
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Position = UDim2.new(0, 20, 0, -5),
						Theme = "Text",
						ZIndex = 14,
						Outline = false,
						Parent = holder,
					})

					local keybindname = key_name or ""

					local keytext = Library:Create("Text", {
						Font = Drawing.Fonts.Plex,
						Size = 13,
						Theme = "Un-Selected_Text",
						Position = UDim2.new(1, -40, 0, -5),
						ZIndex = 14,
						Parent = holder,
						Outline = false,
						Center = true,
					})

					local key
					local state = false
					local binding

					local function set(newkey)
						if c then
							c:Disconnect()
							if flag then
								Library.Flags[flag] = false
							end
							callback(false)
						end
						if tostring(newkey):find("Enum.KeyCode.") then
							newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
						elseif tostring(newkey):find("Enum.UserInputType.") then
							newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
						end

						if newkey ~= nil and not table.find(blacklist, newkey) then
							key = newkey

							local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						else
							key = nil

							local text = "-"

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						end

						if bind ~= "" or bind ~= nil then
							state = false
							if flag then
								Library.Flags[flag] = state
							end
							callback(false)
						end
					end

					local function setkey(newkey)
						if tostring(newkey):find("Enum.KeyCode.") then
							newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.", "")]
						elseif tostring(newkey):find("Enum.UserInputType.") then
							newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.", "")]
						end

						if newkey ~= nil and not table.find(blacklist, newkey) then
							key = newkey
							Library.Flags[flag .. "_KEY"] = newkey

							local text = (Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.", ""))

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						else
							key = nil
							Library.Flags[flag .. "_KEY"] = nil

							local text = "-"

							keytext.Text = "[" .. text .. "]"
							Library:ChangeObjectTheme(keytext, "Un-Selected_Text")
						end
					end

					Library:Connect(InputService.InputBegan, function(inp)
						if (inp.KeyCode == key or inp.UserInputType == key) and not binding then
							if key_mode == "Hold" then
								if flag then
									Library.Flags[flag] = true
								end
								c = Library:Connect(RunService.RenderStepped, function()
									if callback then
										callback(true)
									end
								end)
							elseif key_mode == "Toggle" then
								state = not state
								if flag then
									Library.Flags[flag] = state
								end
								callback(state)
							else
								callback()
							end
						end
					end)

					Flags[flag .. "_KEY"] = setkey

					set(default)

					holder.MouseButton1Click:Connect(function()
						if not binding then
							keytext.Text = "[-]"
							Library:ChangeObjectTheme(keytext, "Accent")

							binding = Library:Connect(InputService.InputBegan, function(input, gpe)
								set(
									input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
										or input.UserInputType
								)
								setkey(
									input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode
										or input.UserInputType
								)
								Library:Disconnect(binding)
								task.wait()
								binding = nil
							end)
						end
					end)

					Library:Connect(InputService.InputEnded, function(inp)
						if key_mode == "Hold" then
							if key ~= "" or key ~= nil then
								if inp.KeyCode == key or inp.UserInputType == key then
									if c then
										c:Disconnect()
										if flag then
											Library.Flags[flag] = false
										end
										if callback then
											callback(false)
										end
									end
								end
							end
						end
					end)

					local keybindtypes = {}

					function keybindtypes:set(newkey)
						set(newkey)
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end

					return keybindtypes
				end

				function section:textbox(cfg)
					local textbox_tbl = {}
					local placeholder = cfg.placeholder or cfg.Placeholder or "new textbox"
					local default = cfg.Default or cfg.default or ""
					local middle = cfg.middle or cfg.Middle or false
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local flag = cfg.flag or cfg.Flag or Utility.NextFlag()
					local callback = cfg.callback or function() end

					local holder = Library:Create(
						"Square",
						{ Transparency = 0, ZIndex = 14, Size = UDim2.new(1, 0, 0, 22), Parent = side, Thickness = 1 }
					)
					local textbox = Library:Create("Square", {
						Filled = true,
						Visible = true,
						Thickness = 0,
						Color = Color3.fromRGB(19, 19, 19),
						Size = UDim2.new(1, -50, 0, 15),
						Position = UDim2.new(0, 23, 1, -17),
						ZIndex = 14,
						Parent = holder,
					})

					holder.MouseEnter:Connect(function()
						textbox.Color = Color3.fromRGB(22, 22, 22)
					end)

					holder.MouseLeave:Connect(function()
						textbox.Color = Color3.fromRGB(19, 19, 19)
					end)

					local outline1 = Library:Outline(textbox, Color3.fromRGB(44, 44, 44), 14)
					Library:Outline(outline1, Color3.new(0, 0, 0), 14)

					local text = Library:Create("Text", {
						Text = default,
						Transparency = 1,
						Visible = true,
						Parent = textbox,
						Theme = "Text",
						ZIndex = 14,
						Center = true,
						Position = UDim2.new(0.5, 0, 0, 1),
						Font = 2,
						Size = 13,
						Outline = true,
					})
					local placeholder = Library:Create("Text", {
						Text = placeholder,
						Transparency = 1,
						Visible = true,
						Parent = textbox,
						Theme = "Un-Selected_Text",
						ZIndex = 14,
						Center = true,
						Position = UDim2.new(0.5, 0, 0, 1),
						Font = 2,
						Size = 13,
						Outline = true,
					})

					Library.ObjectTextbox(textbox, text, function(str)
						if str == "" then
							placeholder.Visible = true
							text.Visible = false
						else
							placeholder.Visible = false
							text.Visible = true
						end
					end, function(str)
						Library.Flags[flag] = str
						callback(str)
					end)

					local function set(str)
						text.Visible = str ~= ""
						placeholder.Visible = str == ""

						text.Text = str
						Library.Flags[flag] = str
						callback(str)
					end

					set(default)

					function textbox_tbl:Set(str)
						set(str)
					end
					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end
					return textbox_tbl
				end

				function section:preview(cfg)
					local esp_preview = {}
					local all_enabled = cfg.toggled or false
					local maincolor = cfg.main_color or Color3.fromRGB(0, 255, 0)
					local side = cfg.side == "left" and section_content
						or cfg.side == "right" and section_content1
						or section_content
					local emptycolor = cfg.empty_color or Color3.fromRGB(255, 0, 0)
					local healthamount = 100

					local holder = Library:Create("Square", {
						Parent = side,
						Visible = true,
						Transparency = 0,
						Size = UDim2.new(1, 0, 0, 285),
						Thickness = 1,
						Filled = false,
						ZIndex = 14,
					})

					local preview_frame = Library:Create("Square", {
						Parent = holder,
						Visible = true,
						Transparency = 1,
						Color = Color3.fromRGB(13, 13, 13),
						Size = UDim2.new(1, 0, 1, 0),
						Thickness = 1,
						Filled = true,
						ZIndex = 15,
					})
					do
						local outline = Library:Outline(preview_frame, Color3.fromRGB(37, 37, 37), 14)
						Library:Outline(outline, Color3.fromRGB(0, 0, 0), 14)
					end

					local esp_head = Library:Create("Square", {
						Parent = preview_frame,
						Size = UDim2.new(0, 44, 0, 39),
						Position = UDim2.new(0, 86, 0, 45),
						Color = Color3.fromRGB(245, 245, 245),
						Thickness = 1,
						Filled = true,
						ZIndex = 16,
					})
					local esp_head_outline = Library:Outline(esp_head, Color3.fromRGB(0, 0, 0), 15)

					local esp_torso = Library:Create("Square", {
						Parent = preview_frame,
						Size = UDim2.new(0, 146, 0, 77),
						Position = UDim2.new(0, 34, 0, 85),
						Color = Color3.fromRGB(245, 245, 245),
						Thickness = 1,
						Filled = true,
						ZIndex = 16,
					})
					local esp_torso_outline = Library:Outline(esp_torso, Color3.fromRGB(0, 0, 0), 15)

					local esp_legs = Library:Create("Square", {
						Parent = preview_frame,
						Size = UDim2.new(0, 72, 0, 78),
						Position = UDim2.new(0, 72, 0, 163),
						Color = Color3.fromRGB(245, 245, 245),
						Thickness = 1,
						Filled = true,
						ZIndex = 16,
					})
					local esp_legs_outline = Library:Outline(esp_legs, Color3.fromRGB(0, 0, 0), 15)

					local esp_bounding_box = Library:Create("Square", {
						Visible = false,
						Parent = preview_frame,
						Size = UDim2.new(0, 195, 0, 240),
						Position = UDim2.new(0, 13.4, 0, 20),
						Color = Color3.fromRGB(255, 255, 255),
						Thickness = 1,
						Filled = false,
						ZIndex = 16,
					})
					local esp_bounding_box_outline = Library:Outline(esp_bounding_box, Color3.fromRGB(0, 0, 0), 16)

					local esp_health_bar_outline = Library:Create("Square", {
						Visible = false,
						Parent = preview_frame,
						Size = UDim2.new(0, 3, 0, 240),
						Position = UDim2.new(0, 6, 0, 20),
						Color = Color3.fromRGB(0, 0, 0),
						Thickness = 1,
						Filled = true,
						ZIndex = 16,
					})
					local esp_health_bar_outline_2 = Library:Outline(esp_health_bar_outline, Color3.new(0, 0, 0), 16)
					local esp_health_bar = Library:Create("Square", {
						Parent = esp_health_bar_outline,
						Size = UDim2.new(1, 0, 1, 0),
						Color = Color3.fromRGB(0, 255, 42),
						Thickness = 1,
						Filled = true,
						ZIndex = 16,
						Position = UDim2.new(0, 0, 1, 0),
					})
					local esp_health_text = Library:Create("Text", {
						Text = tostring("<- " .. healthamount),
						Parent = esp_health_bar,
						Visible = true,
						Transparency = 1,
						Color = maincolor,
						Size = 13,
						Center = false,
						Outline = true,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(1, 0, 0, 0),
						ZIndex = 16,
					})

					local esp_name = Library:Create("Text", {
						Text = "player",
						Parent = preview_frame,
						Visible = false,
						Transparency = 1,
						Color = Color3.fromRGB(255, 255, 255),
						Size = 13,
						Center = true,
						Outline = true,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 110, 0, 3),
						ZIndex = 16,
					})
					local esp_distance = Library:Create("Text", {
						Text = "0 meters",
						Parent = preview_frame,
						Visible = false,
						Transparency = 1,
						Color = Color3.fromRGB(255, 255, 255),
						Size = 13,
						Center = true,
						Outline = true,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 110, 0, 260),
						ZIndex = 16,
					})
					local esp_weapon = Library:Create("Text", {
						Text = "weapon",
						Parent = preview_frame,
						Visible = false,
						Transparency = 1,
						Color = Color3.fromRGB(255, 255, 255),
						Size = 13,
						Center = true,
						Outline = true,
						Font = Drawing.Fonts.Plex,
						Position = UDim2.new(0, 110, 0, 270),
						ZIndex = 16,
					})

					function esp_preview:set_health(amount)
						local value = amount / 100
						healthamount = amount / 100
						esp_health_bar.Size = UDim2.new(1, 0, 0, -(esp_health_bar_outline.Size.Y.Offset * value))
						esp_health_bar.Color = emptycolor:Lerp(maincolor, amount / 100)
						esp_health_text.Text = tostring("<- " .. math.floor(amount / 100 * 100))
						esp_health_text.Color = emptycolor:Lerp(maincolor, amount / 100)
						esp_health_text.Position =
							UDim2.new(1, 0, 0, -(esp_health_bar_outline.Size.Y.Offset * value) - 6)
					end

					function esp_preview:set_health_colors(type, color)
						if type == "main" then
							maincolor = color
							esp_health_bar.Color = emptycolor:Lerp(maincolor, healthamount)
							esp_health_text.Color = emptycolor:Lerp(maincolor, healthamount)
						elseif type == "empty" then
							emptycolor = color
							esp_health_bar.Color = emptycolor:Lerp(maincolor, healthamount)
							esp_health_text.Color = emptycolor:Lerp(maincolor, healthamount)
						end
					end

					function esp_preview:set_visibility(element, state)
						if element == "box" then
							esp_bounding_box.Visible = state
						elseif element == "healthbar" then
							esp_health_bar_outline.Visible = state
						elseif element == "name" then
							esp_name.Visible = state
						elseif element == "distance" then
							esp_distance.Visible = state
							if esp_weapon.Visible and esp_distance.Visible == false then
								esp_weapon.Position = UDim2.new(0, 110, 0, 260)
							else
								esp_weapon.Position = UDim2.new(0, 110, 0, 270)
							end
						elseif element == "weapon" then
							esp_weapon.Visible = state
							if esp_weapon.Visible and esp_distance.Visible == false then
								esp_weapon.Position = UDim2.new(0, 110, 0, 260)
							else
								esp_weapon.Position = UDim2.new(0, 110, 0, 270)
							end
						end
					end

					function esp_preview:set_color(element, state)
						if element == "box" then
							esp_bounding_box.Color = state
						elseif element == "box outline" then
							esp_bounding_box_outline.Color = state
						elseif element == "healthbar outline" then
							esp_health_bar_outline.Color = state
							esp_health_bar_outline_2.Color = state
						elseif element == "name" then
							esp_name.Color = state
						elseif element == "name outline" then
							esp_name.OutlineColor = state
						elseif element == "distance" then
							esp_distance.Color = state
						elseif element == "distance outline" then
							esp_distance.OutlineColor = state
						elseif element == "weapon" then
							esp_weapon.Color = state
						elseif element == "weapon outline" then
							esp_weapon.OutlineColor = state
						end
					end

					if size == "auto" then
						side.Size = UDim2.new(1, 0, 0, section_content.AbsoluteContentSize + 55)
					end

					return esp_preview
				end

				return section
			end

			return multisection
		end

		return page
	end

	function window:get_config()
		local configtbl = {}

		for flag, _ in next, Flags do
			if not table.find(ConfigIgnores, flag) then
				local value = Library.Flags[flag]

				if typeof(value) == "EnumItem" then
					configtbl[flag] = tostring(value)
				elseif typeof(value) == "Color3" then
					configtbl[flag] = { color = value:ToHex(), alpha = value.A }
				else
					configtbl[flag] = value
				end
			end
		end

		local config = HttpService:JSONEncode(configtbl)

		return config
	end

	function window:update_title(a, b)
		if type(b) == "string" then
			if a == "name" then
				window_title.Text = b
			elseif a == "sub" then
				window_color.Text = b
			end
		end
	end

	return window
end

function Library:Notify(info)
	local Ntif = { instances = {}, create_tick = tick() }
	local title = info.text or info.Text or "nil name"
	local time = info.time or info.Time or 5
	local z = 10

	local holder = Library:Create("Square", {
		Position = UDim2.new(0, 19, 0, 75),
		Transparency = 0,
		Thickness = 1,
	}, true)

	local background = Library:Create("Square", {
		Size = UDim2.new(0, Utility.TextLength(title, 2, 13).X + 5, 0, 19),
		Position = UDim2.new(0, -500, 0, 0),
		Parent = holder,
		Color = Color3.fromRGB(13, 13, 13),
		ZIndex = z,
		Thickness = 1,
		Filled = true,
	}, true)

	local outline1 = Library:Outline(background, Color3.fromRGB(44, 44, 44), z, true)
	local outline2 = Library:Outline(outline1, Color3.fromRGB(0, 0, 0), z, true)

	local line = Library:Create("Square", {
		Parent = background,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Thickness = 1,
		Filled = true,
		ZIndex = 11,
	})
	local line1 = Library:Create("Square", {
		Parent = background,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = UDim2.new(0, 1, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		Thickness = 1,
		Filled = true,
		ZIndex = 11,
	})

	local notiftext = Library:Create("Text", {
		Text = title,
		Parent = background,
		Visible = true,
		Transparency = 1,
		Theme = "Text",
		Size = 13,
		Center = false,
		Outline = false,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(0, 3, 0, 2),
		ZIndex = 11,
	})

	function Ntif.Remove()
		local goaway = Tween.new(
			Ntif.Instances[2],
			TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, -500, 0, 0) }
		):Play()

		task.wait(0.7)

		Ntif.Instances[1]:Remove()

		table.remove(Library.NotifList.Ntifs, table.find(Library.NotifList.Ntifs, Ntif))

		Library.NotifList.Reposition(true)
	end

	task.spawn(function()
		Tween.new(
			line1,
			TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ Size = UDim2.new(0, Utility.TextLength(title, 2, 13).X + 5, 0, 1) }
		):Play()
		task.wait(time)
		Ntif.Remove()
	end)

	Ntif.Instances = { holder, background, outline1, outline2, line, notiftext }

	table.insert(Library.NotifList.Ntifs, Ntif)

	function Library.NotifList.Reposition(isleaving)
		local position_to_go = 60 + 12
		for i, v in pairs(Library.NotifList.Ntifs) do
			local position = UDim2.new(0, 19, 0, position_to_go)

			local lerp_table = { Position = position }
			local valuestring = tostring(v.instances[1].Position.X.Offset)

			if tonumber(valuestring) < 0 then
				v.instances[1].Position = position + UDim2.new(0, -4, 0, 7)
			end
			if isleaving then
				Tween.new(
					v.instances[1],
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{ Position = lerp_table.Position }
				):Play()
			else
				v.instances[1].Position = lerp_table.Position
				Tween.new(
					v.instances[2],
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{ Position = UDim2.new(0, 0, 0, 0) }
				):Play()
			end
			position_to_go = position_to_go + v.instances[1].Size.Y + 12
		end
	end

	Library.NotifList.Reposition()
end

function Library:CreateWatermark(info)
	local title = info.title or "Watermak"
	title = Utility.FindTriggers(title)

	local position = info.position or UDim2.new(0, 9.5, 0, 22)
	local Watermark = { objects = {}, tickrate = 25 }
	Watermark.Objects.holder = Library:Create("Square", {
		Position = position,
		Transparency = 0,
		Thickness = 1,
	}, true)

	Watermark.Objects.background = Library:Create("Square", {
		Size = UDim2.new(0, Utility.TextLength(title, 2, 13).X + 5, 0, 19),
		Position = position,
		Parent = Watermark.Objects.holder,
		Color = Color3.fromRGB(13, 13, 13),
		ZIndex = z,
		Thickness = 1,
		Filled = true,
	}, true)

	Watermark.Objects.outline1 = Library:Outline(Watermark.Objects.background, Color3.fromRGB(44, 44, 44), 10, true)
	Watermark.Objects.outline2 = Library:Outline(Watermark.Objects.outline1, Color3.fromRGB(0, 0, 0), 10, true)

	Watermark.Objects.text2 = Library:Create("Text", {
		Parent = Watermark.Objects.background,
		Visible = true,
		Transparency = 1,
		Theme = "Accent",
		Size = 13,
		Text = "seere",
		Center = false,
		Outline = false,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(0, 3, 0, 2),
		ZIndex = 11,
	})
	Watermark.Objects.text3 = Library:Create("Text", {
		Text = title,
		Parent = Watermark.Objects.background,
		Visible = true,
		Transparency = 1,
		Theme = "Text",
		Size = 13,
		Center = false,
		Outline = false,
		Font = Drawing.Fonts.Plex,
		Position = UDim2.new(0, 1 + Utility.TextLength(Watermark.Objects.text2.Text, 2, 13).X, 0, 2),
		ZIndex = 11,
	})

	function Watermark.SetState(bool)
		for i, v in next, Watermark.Objects do
			v.Visible = bool
		end
	end
	function Watermark.SetText(text)
		title = Utility.FindTriggers(".{game} | " .. text)
		Watermark.Update()
	end

	function Watermark.SetPos(pos)
		local size = Watermark.Objects.background.AbsoluteSize
		local screensize = workspace.CurrentCamera.ViewportSize

		if pos == "top left" then
			position = UDim2.new(0, 9.5, 0, 22)
		elseif pos == "top right" then
			position = UDim2.new(0, (screensize.X - size.X - 9.5) / 2, 0, 22)
		elseif pos == "bottom left" then
			position = UDim2.new(0, 9.5, 0, (screensize.Y - size.Y - 22) / 2)
		elseif pos == "bottom right" then
			position = UDim2.new(0, (screensize.X - size.X - 9.5) / 2, 0, (screensize.Y - size.Y - 22) / 2)
		elseif pos == "top center" then
			position = UDim2.new(0, (screensize.X / 2 - size.X / 2) / 2, 0, 22)
		elseif pos == "bottom center" then
			position = UDim2.new(0, (screensize.X / 2 - size.X / 2) / 2, 0, (screensize.Y - size.Y - 22) / 2)
		elseif pos == "unlocked" then
			return
		end
		Watermark.Update()
	end
	function Watermark.Update()
		if Watermark.Objects.holder.Visible then
			Watermark.Objects.text3.Text = title
			Watermark.Objects.background.Size = UDim2.new(
				0,
				1 + Utility.TextLength(Watermark.Objects.text2.Text, 2, 13).X + Utility.TextLength(title, 2, 13).X + 5,
				0,
				19
			)
			Watermark.Objects.background.Position = position
			Watermark.Objects.holder.Position = position
		end
	end
	Watermark.SetState(false)
	return Watermark
end

return Library
