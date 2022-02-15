package.path = package.path .. ";" .. "./apigen_lua/?.lua"
package.path = package.path .. ";" .. "./apigen_lua/cparser/?.lua"

require("search")
require("generator")
require("parse")

-- check command line parameter
local argc = #arg
if argc ~= 1 then 
	print("Please input y_api function name.") 
	os.exit(-1)
end
local funcName = arg[1]

-- global_stats can be changed in anywhere
global_stats = {
	function_prefix = "luac",		-- default
	comment_more = {},
	has_bitfield = false,
	is_em_tbale = false,
	is_lpm_table = false,
	def_mac_string = false,
	def_ipv6_string = false
}
output = ""
function_head = ""
output_comment = ""
output_definition = "\t\tint ret = 0;\n"
output_expression = ""

params_str = ""
function_head = string.gsub(TPL_function_head, "$y_api", funcName)
output_comment = string.gsub(TPL_comment, "$y_api", funcName)
function_footer = ""
fuction_closing = TPL_function_closing

-- recursivly go through strcut/union members and return expression 
function get_struct(param, level, prefix, debug, in_union)
	local expression = ""
	local is_ctype
	local match
	local varType
	local filename
	local members
	local is_else = false
	local _in_union	= false			-- local var, differ from the para in_union
	local first_in_union = false
	
	is_ctype, match = Pair.is_ctype(param)
	if is_ctype then
		expression = expression .. Generator.ctype_expr(param, level, prefix, debug, in_union)
	-- special treatment 
	elseif Generator.is_special_field(param) then
		expression = expression .. Generator.special_field(param, level, prefix, debug)
	else
		-- some works need to be done before search for the symbol
		if match then
			varType = string.trim(string.gsub(Pair.get_type(param), match, ""))	-- remove struct/union
		end

		-- in_union flag determines whether to set the debug field to false
		-- in Generator.ctype_expr(). Once the flag was set, it should be carried
		-- to all its' subsidiary data members.
		if match == "union" then
			_in_union = true
		end
		if not in_union then 
			in_union = _in_union
			if in_union then first_in_union = true end
		end

		filename = Search.datatype(varType)
		filename = "/home/demon/下载/mccode/" .. filename
		members = Parse.datatype(Pair.get_type(param), filename)

		if level == 0 then is_else = true end		
		expression = expression .. Generator.getsubtable(Pair.get_name(param), level, is_else, first_in_union)

		-- recursively generate code here
		level = level + 1
		if not prefix then 
			prefix = Pair.get_name(param)
		else
			prefix = prefix .. "." .. Pair.get_name(param)
		end
		for _, member in pairs(members) do
			expression = expression .. get_struct(member, level, prefix, debug, in_union)
		end

		expression = expression .. string.rep(INDENT, 2 + level-1) .. ")\n"		-- the ) for getsubtable
	end

	return expression
end


params = Search.y_api_func(funcName)

-- 主循环里处理定义，get_struct里不处理
local has_request = false
for _, param in pairs(params) do
	local level = 0

	if Pair.is_ctype(param) then
		output_definition = output_definition .. Generator.ctype_def(param)
		output_expression = output_expression .. Generator.ctype_expr(param, level, nil, true)
	else
		output_definition = output_definition .. Generator.struct_def(param)
		output_expression = output_expression .. get_struct(param, level, nil, false) .. "\n"		-- debug default set to false
	end

	-- add "&" before parameter if it's a pointer
	if Pair.is_pointer(param) then
		params_str = params_str .. "&" .. Pair.get_name(param) .. ", "
	else
		params_str = params_str .. Pair.get_name(param) .. ", "
	end

	if Pair.get_name(param) == "entry_index" then
		global_stats.is_em_tbale = true
	elseif Pair.get_name(param) == "request" then
		has_request = true
	elseif Pair.get_name(param) == "response" then
		if has_request then global_stats.is_em_tbale = true end
	elseif Pair.get_name(param) == "prefix_length" then
		global_stats.is_lpm_table = true
	end
end

-- setting function_head and comment
if global_stats.is_em_tbale or global_stats.is_lpm_table then
	global_stats.function_prefix = "luac_luac"
end
function_head = string.gsub(function_head, "$prefix", global_stats.function_prefix)
output_comment = string.gsub(output_comment, "$prefix", global_stats.function_prefix)
do
	local more = ""
	if #global_stats.comment_more > 0 then
		for _, comment in ipairs(global_stats.comment_more) do
			more = more .. COMMENT_INDENT .. comment
		end
	end
	output_comment = string.gsub(output_comment, "$more", more)
end
if string.find(funcName, "_add") and (global_stats.is_em_tbale or global_stats.is_lpm_table) then
	output_comment = string.gsub(output_comment, "_add", "_set")
	function_head = string.gsub(function_head, "_add", "_set")
end

-- setting function footer
params_str = string.sub(params_str, 1, string.len(params_str) - 2)
function_footer = Generator.function_footer(funcName, params_str, params)

-- fixing definition
if global_stats.has_bitfield then
	output_definition = output_definition .. "\t\tuint32_t uintVar;\n"
end
if global_stats.def_ipv6_string then
	output_definition = output_definition .. string.rep(INDENT, 2) .. "std::string ipv6Str;\n"
end
if global_stats.def_mac_string  then
	output_definition = output_definition .. string.rep(INDENT, 2) .. "std::string macStr;\n"
end
output_definition = output_definition .. "\t\tstd::string apiName = \"" .. funcName .. '";\n'


output = output_comment .. function_head .. output_definition .. "\n" .. output_expression .. "\n" .. function_footer .. fuction_closing
print(output)