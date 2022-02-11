-- common functions

-- convert an delimiter seperated string into an element array 
-- @return [array]
function string.split(str, delimiter)
	local start = 1
	local stop = 1
	local strs = {}
	
	stop = string.find(str, delimiter, stop, false)
	if not stop then
		table.insert(strs, str)
	else
		while stop do
			table.insert(strs, string.sub(str, start, stop-1))
			stop = stop + 1
			start = stop
			stop = string.find(str, delimiter, stop, false)
		end
		table.insert(strs, string.sub(str, start))
	end

	return strs
end

-- remove empty characters in both side of a string
function string.trim(str)
	local char
	local start
	local stop
	
	-- ltrim
	start = 1
	while start <= string.len(str) do
		char = string.sub(str, start, start)
		-- stop at the first non-empty character
		if not (char == " " or char == "\n" or char == "\t") then
			break
		end
		start = start + 1
	end
	if start > 1 then
		str = string.sub(str, start)
	end

	-- rtrim
	start = string.len(str) 
	stop = start
	while start >=1 do
		char = string.sub(str, start, start)
		-- stop at the first non-empty character
		if not (char == " " or char == "\n" or char == "\t") then
			break
		end
		start = start - 1
	end
	if start < stop then
		str = string.sub(str, 1, start)
	end

	return str
end

-- a list of C internal datatype
local Ctype = {
	"char", "short", "int", "long", "float", "double", 
	"void", 
	"int8_t", "int16_t", "int32_t", "int64_t",
	"uint8_t", "uint16_t", "uint32_t", "uint64_t",
	"static", "const", "signed", "unsigned"
}
local Ctype_hash = {}
for _, v in pairs(Ctype) do
	Ctype_hash[v] = true
end

-- check if the given type is a C internal datatype
-- @return [bool]
function is_ctype(t)
	if Ctype_hash[t] then
		return true
	else
		return false
	end
end

-- print key based on type, only used in table.dump
local function printkey(key)
    if type(key) == "number" then
        io.write("[".. key .. "] = ")
    else
        io.write("[\"".. key .. "\"] = ")
    end
end

-- print all the table elements recursively, for debugging
-- and for demostrating(you can use the output as lua script).
-- @optional [number] level, recursive level
function table.dump(tb, level)
    io.output(io.stdout)

    -- give default value
    if level == nil then
        level = 1
    end

    if type(tb) == "table" then
        io.write("{\n")

        for key, value in pairs(tb) do
            -- indent
            io.write(string.rep(" ", (level) * 4))

            if type(value) == "table" then
                printkey(key)
                table.dump(value, level + 1)
            else
                if type(value) == "string" then
                    value = "\"" .. value .. "\""
                end
                printkey(key)
                io.write(tostring(value) .. ",\n")
            end
        end

        -- indent
        io.write(string.rep(" ", (level - 1) * 4))
        io.write("},\n")
    end
end