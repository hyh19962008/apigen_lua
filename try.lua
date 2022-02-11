require "cparser"

local options = {
	"-std=c99",
	"-Zpass",
}

parse = {}

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

function parse.datatype(symbol, filename)
	local di

	di = cparser.declarationIterator(options, filename)
	-- di = cparser.declarationIterator(options, io.lines(filename))
	for decl in di do 
		if decl.name == symbol then
			print(decl) 
			print(">>", cparser.declToString(decl)) 
			if decl.sclass == "[typetag]" then
				for i in ipairs(decl.type) do
					print(decl.type[i][1])
					print(decl.type[i][2])
				end
			end
		end
	end
end


-- parse.datatype("struct arp_response", '/home/demon/下载/mccode/main.c')
