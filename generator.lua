-- dofile("common.lua")
dofile("/home/demon/下载/mccode/common.lua")



-- string templates
TEMPLATES_ctype = "getKey(L, LUAC_STR_VAR($var), $debug, apiName);\n"
TPL_bitfield = "LUAC_BITFIELD_GET($var, $prefix, $debug);\n"
TEMPLATES_function_head = "\tint luac_$y_api(lua_State *L) {\n"
TEMPLATES_function_footer = [[
		if(ret != 0)
			return ret;
		return $y_api_full($params);
]]
TEMPLATES_function_closing = "\t}\n"

TPL_getsubtable = "LUAC_GETSUBTABLE($var,\n"
TPL_getsubtable_else = "LUAC_GETSUBTABLE_ELSE($var,\n"

INDENT = "\t"

Generator = {}

function Generator.ctype_def(param)
	return string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. Pair.get_name(param) .. ";\n"
end

function Generator.struct_def(param)
	return string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. Pair.get_name(param) .. " = {};\n"
end

-- check if var is a valid field
-- @param [string] var
-- @return [bool]
local function is_valid_field(var)
	local no_use = {"pad%d*", "rsv%d*", "reserve%d*", "reserved%d*"}

	for _, v in pairs(no_use) do
		if  string.find(var, v) then
			return false
		end
	end

	return true
end

function Generator.ctype_expr(param, level, debug)
	local tmpstr
	local var
	local debug_str

	debug_str = "true"
	if not debug then debug_str = "false" end

	var = Pair.get_name(param)
	if is_valid_field(var) then
		if Pair.is_bitfield(param) then
			-- tmpstr = string.gsub(TPL_bitfield, "$var", )
			-- tmpstr = string.gsub(tmpstr, "$prefix", )
			-- return string.rep(INDENT, 2 + level) .. string.gsub(tmpstr, "$debug")
			return ""
		else
			tmpstr = string.gsub(TEMPLATES_ctype, "$var", Pair.get_name(param))
			return string.rep(INDENT, 2 + level) .. string.gsub(tmpstr, "$debug", debug_str)
		end
	else
		return ""
	end
end

function Generator.getsubtable(var, level, is_else)
	if is_else then
		return string.rep(INDENT, 2 + level) .. string.gsub(TPL_getsubtable_else, "$var", var)
	else
		return string.rep(INDENT, 2 + level) .. string.gsub(TPL_getsubtable, "$var", var)
	end
end

function Generator.function_footer(funcName, params_str)
	local function_footer

	function_footer = string.gsub(TEMPLATES_function_footer, "$y_api_full", funcName)
	function_footer = string.gsub(function_footer, "$params", params_str)

	return function_footer
end