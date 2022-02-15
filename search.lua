dofile("common.lua")
dofile("parse.lua")


Search = {}

-- search for symbol using external tools global
-- @param [string] symbol
-- @param [string] format, global search result format
local function global(symbol, format)
	local f
	local tmp
	local result

	format = format or "ctags-x"
	f = io.popen("cd ~/下载/mccode;global --result " .. format .. " -d " .. symbol , "r")
	result = {}
	repeat tmp = f:read()
		table.insert(result, tmp)
	until not tmp
	f:close()

	return result
end

-- check the number of result found
-- @return [int] index, the index of the result to be used
local function check_result(result, message)
	local index

	if #result == 0 then
		print("symbol " .. message .. " not found.")
		if string.find(message, "_set") then
			print("Try " ..  string.gsub(message, "_set", "_add") .. " maybe?")
		end
		os.exit(-2)
	elseif #result > 1 then
		for i, v in ipairs(result) do
			print("[" .. i .. "]", v)
		end
		print("#### More than 1 results were found, which one should be used? ####")
		index = io.read("num")

		if index > #result or index <= 0 then
			print("Please input a valid index.")
		end
	else
		index = 1
	end

	return index
end

-- convert an empty character seperated result string into an k-v table
-- @return [table] result
local function split_result(str)
	local i = 1
	local begin = 1
	local start = 1
	local stop = 1
	local keys = {"name", "line", "filename", "def"}
	local result = {}
	
	while i <= 3 do
		start, stop = string.find(str, "%s+", begin, false)
		result[keys[i]] = string.sub(str, begin, start-1)
		begin = stop + 1
		i = i + 1
	end
	result[keys[i]] = string.sub(str, begin)

	return result
end

-- search for y_api function
-- @param [string] funcname, function name
-- @return [array], an array describing all the parameters of the given function
function Search.y_api_func(funcname)
	assert(type(funcname) == "string", "parameter type error.")

	local result
	local index
	local params
	local di
	local func

	result = global(funcname)
	index = check_result(result, funcname)
	result = result[index]
	result = split_result(result)
	
	-- parse the function definition
	di = cparser.declarationIterator(Parse.options, string.gmatch(result.def, '[^\n]+'))
	func = di()
	params = {}
	for _, v in ipairs(func.type) do
		table.insert(params, v)
	end
	
	return params
end

-- search for a datatype, return full path of the file where it locates
-- @param [string] varType
-- @return [string] filename
function Search.datatype(varType)
	local result
	local index
	local filename

	result = global(varType, "path")
	index = check_result(result, varType)
	result = result[index]
	filename = result

	return filename
end