dofile("/home/demon/下载/mccode/search.lua")
dofile("/home/demon/下载/mccode/generator.lua")

-- check command line parameter
local argc = #arg
if argc ~= 1 then 
	print("Please input y_api function name.") 
	os.exit(-1)
end
local funcName = arg[1]


output = ""
function_head = ""
output_definition = "\t\tint ret = 0;\n"
output_expression = ""

params_str = ""
function_head = string.gsub(TPL_function_head, "$y_api", funcName)
function_footer = ""
fuction_closing = TPL_function_closing


function get_struct(param, level, prefix, debug)
	local expression = ""
	local is_ctype
	local match
	local varType
	local tmpstr
	local filename
	local members
	local is_else = false
	
	is_ctype, match = Pair.is_ctype(param)
	if is_ctype then
		expression = expression .. Generator.ctype_expr(param, level, prefix, debug)
	-- special treatment 
	elseif Generator.is_special_field(param) then
		expression = expression .. Generator.special_field(param, level, prefix, debug)
	else
		-- some works need to be done before search for the symbol
		if match then
			varType = string.trim(string.gsub(Pair.get_type(param), match, ""))	-- remove struct/union
		end

		filename = Search.datatype(varType)
		filename = "/home/demon/下载/mccode/" .. filename
		-- filename = "/home/demon/下载/mccode/ForwardingPlane/include/be/arp.h"
		members = Parse.datatype(Pair.get_type(param), filename)

		if level == 0 then is_else = true end		
		expression = expression .. Generator.getsubtable(Pair.get_name(param), level, is_else)

		-- recursively generate code here
		level = level + 1
		if not prefix then 
			prefix = Pair.get_name(param)
		else
			prefix = prefix .. "." .. Pair.get_name(param)
		end
		for _, member in pairs(members) do
			expression = expression .. get_struct(member, level, prefix, debug)
		end

		expression = expression .. string.rep(INDENT, 2 + level-1) .. ")\n"		-- the ) for getsubtable
	end

	return expression
end


params = Search.y_api_func(funcName)

-- 主循环里处理定义，loop里不处理
for _, param in pairs(params) do
	local level = 0

	if Pair.is_ctype(param) then
		output_definition = output_definition .. Generator.ctype_def(param)
		output_expression = output_expression .. Generator.ctype_expr(param, level, nil, true)
	else
		output_definition = output_definition .. Generator.struct_def(param)
		output_expression = output_expression .. get_struct(param, level, nil, false)
	end

	if Pair.is_pointer(param) then
		params_str = params_str .. "&" .. Pair.get_name(param) .. ", "
	else
		params_str = params_str .. Pair.get_name(param) .. ", "
	end
end

params_str = string.sub(params_str, 1, string.len(params_str) - 2)
function_footer = Generator.function_footer(funcName, params_str)
output = function_head .. output_definition .. "\n" .. output_expression .. "\n" .. function_footer .. fuction_closing
print(output)