require "cparser"

Parse = {}
Pair = {}
Tag = {}

Parse.options = {
	"-std=c99",
	"-Zpass",
}

Tag = {
	type = "Type",
	qual = "Qualified",
	ptr = "Pointer",
	array = "Array",
	struct = "Struct",
	union = "Union",
	enum = "Enum",
	func = "Function",

	pair = "Pair",
	typedef = "TypeDef",
}

function Pair.is_bitfield(pair)
	assert(pair.tag == Tag.pair, "parameter is no of Pair type.")

	return pair.bitfield ~= nil
end

function Pair.is_pointer(pair)
	assert(pair.tag == Tag.pair, "parameter is no of Pair type.")

	return pair.tag == Tag.ptr
end

function Pair.get_type(pair)
	assert(pair.tag == Tag.pair, "parameter is no of Pair type.")

	if pair[1].tag == Tag.type then
		return pair[1].n
	else
		return pair[1].t.n
	end
end

function Pair.get_name(pair)
	assert(pair.tag == Tag.pair, "parameter is no of Pair type.")

	return pair[2]
end


-- @return [bool] ret, [string] match
function Pair.is_ctype(pair)
	assert(pair.tag == Tag.pair, "parameter is no of Pair type.")

	local match
	local ret

	-- check if it's struct or union
	match = string.match(Pair.get_type(pair), "^struct")
	if not match then 
		match = string.match(Pair.get_type(pair), "^union") 
	end

	if pair[1].tag == Tag.type then
		if match then 
			ret = false 
		else
			ret = true
		end
	else
		ret = false
	end

	return ret, match
end

-- TypeDef
cparse_struct = {
	name = "",
	sclass = "",		-- storage class, 
	tag = "",
	type = {
		n = "$name",
		tag = "Struct", 
		{
			mem1, mem2, mem3,
			mem4 = {
				bitfield = Slength,		-- optional
				tag = "Pair",
				{
					[1] = {
						n = "$typename",
						tag = "Type"
					},
					[2] = "$memName"
				}
			},
			mem5 = {
				tag = "Pair",
				{
					[1] = {
						n = "$typename",		-- "e.g. strcut abc_t"
						tag = "Type",
						_def = {				-- exists if definition were found
							n = "$typename",
							tag = "Struct",
							{mem1, mem2}
						}
					},
					[2] = "$memName"
				}
			}
		}
	},
	where = ":$line"
}

-- parse the given file and return member information 
-- of the provided symbol
-- @param [string] symbol
-- @param [string] filename
-- @return [array] members
function Parse.datatype(symbol, filename)
	local di
	local found = false
	local members = {}

	-- di = cparser.declarationIterator(Parse.options, filename)
	di = cparser.declarationIterator(Parse.options, io.lines(filename))
	for decl in di do 
		if decl.name == symbol then
			if decl.tag == Tag.typedef then
				for _, v in ipairs(decl.type) do
					table.insert(members, v)
				end
			else
				members = nil
			end

			found = true
			break
		end
	end

	if not found then
		print("symbol " .. symbol .. " not found in file " .. filename)
		members = nil
	end
	return members
end


-- parse.datatype("struct arp_response", '/home/demon/下载/mccode/main.c')
