dofile("/home/demon/下载/mccode/search.lua")
dofile("/home/demon/下载/mccode/generator.lua")

local argc = #arg
if argc ~= 1 then 
	print("Please input y_api function name.") 
	os.exit(-1)
end
local funcName = arg[1]


params = Search.y_api_func(funcName)


output = ""
function_head = ""
output_definition = "\t\tint ret = 0;\n"
output_expression = ""

function_head = string.gsub(TEMPLATES_function_head, "$y_api", funcName)
function_footer = TEMPLATES_function_footer
fuction_closing = TEMPLATES_function_closing


for _, param in pairs(params) do
	local _
	local varType
	local tmpstr
	local filename
	local members
	local level = 0

	if Pair.is_ctype(param) then
		output_definition = output_definition .. Generator.ctype_def(param)
		output_expression = output_expression .. Generator.ctype_expr(param, level, "true")
	else
		-- some works need to be done before search for the symbol
		_, match = Pair.is_ctype(param)
		if match then
			varType = string.trim(string.gsub(Pair.get_type(param), match, ""))	-- remove struct/union
		end

		filename = Search.datatype(varType)
		filename = "/home/demon/下载/mccode/ForwardingPlane/include/be/arp.h"
		members = Parse.datatype(Pair.get_type(param), filename)

		if level == 0 then
			output_definition = output_definition .. Generator.ctype_def(param)
			output_expression = output_expression .. Generator.getsubtable(Pair.get_name(param), level, true)

			level = level + 1
			for _, member in pairs(members) do
				output_expression = output_expression .. Generator.ctype_expr(member ,level, "false")
			end
			output_expression = output_expression .. string.rep(INDENT, 2 + level-1) .. ")\n"

		else

		end
	end
end

output = function_head .. output_definition .. "\n" .. output_expression .. "\n" .. function_footer .. fuction_closing
print(output)