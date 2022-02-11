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
INDENT = "\t"

Generator = {}

function Generator.ctype_def(param)
	return string.rep(INDENT, 2) .. param.type .. " " .. param.name .. ";\n"
end

function Generator.ctype_expr(param, debug)
	local tmpstr

	tmpstr = string.gsub(TEMPLATES_ctype, "$var", param.name)
	return string.rep(INDENT, 2) .. string.gsub(tmpstr, "$debug", debug)
end