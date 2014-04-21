function yes_no_to_bool(x)
	if(x == "y") then return true end
	return false
end

function prompt_yes_no(y)
	local x = "n"
	repeat
		 io.write(y)
		 io.flush()
		 x=io.read()
	until x=="y" or x=="n"
	return x
end

function prompt(y,xval)
	local x = xval
	io.write(y)
	io.flush()
	x=io.read()
	if x == "" then
		return xval
	end
	return x
end

local configLines = {}
local configOps = {}

io.write("This is the configure script built for aroop\n")
local haslfs,lfs = pcall(require,"lfs")
local phome = "";
if haslfs then
	phome = lfs.currentdir()
end

configLines["PROJECT_HOME"] = prompt("Project path " .. phome .. " > " , phome)
local ahome = string.gsub(configLines["PROJECT_HOME"],"core/build/android$","core")
configLines["CORE_PATH"] = prompt("Project path " .. ahome .. " > " , ahome)

local conf = assert(io.open("jni/.config.mk", "w"))
for x in pairs(configLines) do
	local op = configOps[x]
	if op == nil then
		op = "="
	end
	conf:write(x .. op .. configLines[x] .. "\n")
end
assert(conf:close())

