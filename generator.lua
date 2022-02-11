-- dofile("common.lua")
dofile("/home/demon/下载/mccode/common.lua")



-- string templates
TEMPLATES_ctype = "getKey(L, LUAC_STR_VAR($var), $debug, apiName);\n"
TEMPLATES_function_head = "\tint luac_$y_api(lua_State *L) {\n"
TEMPLATES_function_footer = [[
		if(ret != 0)
			return ret;
		return $y_api_full;
]]
TEMPLATES_function_closing = "\t}\n"

TPL_getsubtable = "LUAC_GETSUBTABLE($var,\n"
TPL_getsubtable_else = "LUAC_GETSUBTABLE_ELSE($var,\n"

INDENT = "\t"

Generator = {}

function Generator.ctype_def(param)
	return string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. Pair.get_name(param) .. ";\n"
end

function Generator.ctype_expr(param, level, debug)
	local tmpstr

	tmpstr = string.gsub(TEMPLATES_ctype, "$var", Pair.get_name(param))
	return string.rep(INDENT, 2 + level) .. string.gsub(tmpstr, "$debug", debug)
end

function Generator.getsubtable(var, level, is_else)
	if is_else then
		return string.rep(INDENT, 2 + level) .. string.gsub(TPL_getsubtable_else, "$var", var)
	else
		return string.rep(INDENT, 2 + level) .. string.gsub(TPL_getsubtable, "$var", var)
	end
end