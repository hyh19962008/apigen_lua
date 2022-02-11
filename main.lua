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
	local varType
	local tmpstr
	-- print(param.type, param.name)

	if is_ctype(param.type) then
		output_definition = output_definition .. Generator.ctype_def(param)
		output_expression = output_expression .. Generator.ctype_expr(param, "true")
	else
		-- some works need to be done before search for the symbol
		match = string.match(param.type, "^struct")
		if not match then 
			match = string.match(param.type, "^union") 
		end
		if match then
			varType = string.trim(string.gsub(param.type, match, ""))	-- remove struct/union
			-- print(varType, match)
		end

		varType = string.gsub(varType, "%*", "")					-- remove pointer "*"
		Search.datatype(varType)
	end
end

output = function_head .. output_definition .. "\n" .. output_expression .. "\n" .. function_footer .. fuction_closing
print(output)