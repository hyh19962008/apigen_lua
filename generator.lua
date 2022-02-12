-- dofile("common.lua")
dofile("/home/demon/下载/mccode/common.lua")



-- string templates-------------------------------
TPL_ctype = "getKey(L, LUAC_STR_VAR($var), $debug, apiName);\n"
TPL_ctype_pre = "getKey(L, LUAC_STR_PREVAR($var, $prefix), $debug, apiName);\n"
TPL_bitfield = "LUAC_BITFIELD_GET($var, $prefix, $debug);\n"
TPL_ipv6 = {
	'if(!getKey(L, "$var", ipv6Str, $debug, apiName))\n',
		'\t$var_full = IPv6Address(ipv6Str);\n'
}
TPL_special = {
	["struct mac_address_t"] = {
		'if(!getKey(L, "$var", macStr, $debug, apiName))\n',
		"\t$var_full = MacAddress(macStr);\n"
	},
	-- the struct datatype of ipv6 can be even more, because IPv6Address::operator T() is a class template
	["struct ipv6_address_t"] = TPL_ipv6,
	["struct srv6_sid_response"] = TPL_ipv6,
	["struct srv6_nhi_tbl_response"] = TPL_ipv6,
}

TPL_function_head = "\tint luac_$y_api(lua_State *L) {\n"
TPL_function_footer = [[
		if(ret != 0)
			return ret;
		return $y_api_full($params);
]]
TPL_function_closing = "\t}\n"

TPL_getsubtable = "LUAC_GETSUBTABLE($var,\n"
TPL_getsubtable_else = "LUAC_GETSUBTABLE_ELSE($var,\n"
---------------------------------------------------

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
	local no_use = {"^pad%d*", "^padding", "^rsv(_?)%d*", "^resv%d", "^reserve%d*", "^reserved%d*"}

	for _, v in pairs(no_use) do
		if string.find(string.lower(var), v) then
			return false
		end
	end

	return true
end

-- check if var is a key field (whose debug should be set to true)
-- @param [string] var
-- @return [bool]
local function is_key_field(var)
	local key_field = {"entry_valid"}

	for _, v in pairs(key_field) do
		if string.find(string.lower(var), v) then
			return true
		end
	end

	return false
end

-- check if param is a special field
-- @param [table] param
-- @return [bool]
function Generator.is_special_field(param)
	if TPL_special[Pair.get_type(param)] then
		return true
	else
		return false
	end
end

-- handle special fields, note that we directly modified 
-- the global variable `output_definition` here instead of return def,
-- just to keep the code clean.
-- @return [string] expr
function Generator.special_field(param, level, prefix, debug)
	local debug_str
	local tpl
	local tmpstr
	local var
	local _type
	local indent
	local def

	if debug then 
		debug_str = "true" 
	else 
		debug_str = "false" 
	end

	var = Pair.get_name(param)
	_type = Pair.get_type(param)
	tpl = TPL_special[_type]
	indent = string.rep(INDENT, level+2)

	if _type == "struct mac_address_t" then
		def = string.rep(INDENT, 2) .. "std::string macStr;\n"
	elseif string.find(_type, "ipv6") or string.find(_type, "srv6") then
		def = string.rep(INDENT, 2) .. "std::string ipv6Str;\n"
	end

	tmpstr = string.gsub(tpl[1], "$var", var)
	tmpstr = string.gsub(tmpstr, "$debug", debug_str)
	tpl = string.gsub(tpl[2], "$var_full", prefix .. "." .. var)

	output_definition = output_definition .. def			-- output_definition is a global variable
	return indent .. tmpstr .. indent .. tpl
end

-- generate expression to read Lua script for ctype variable and field
-- @param [bool] debug, optional
-- @return [string]expr
function Generator.ctype_expr(param, level, prefix, debug)
	local tmpstr
	local var
	local debug_str
	local indent

	var = Pair.get_name(param)
	indent = string.rep(INDENT, 2 + level)

	-- setting debug field
	debug_str = "true"
	if not debug then debug_str = "false" end		-- default value
	if is_key_field(var) then debug_str = "true" end

	if is_valid_field(var) then
		if Pair.is_bitfield(param) then
			tmpstr = string.gsub(TPL_bitfield, "$var", var)
			tmpstr = string.gsub(tmpstr, "$prefix", prefix)
			return indent .. string.gsub(tmpstr, "$debug", debug_str)
		elseif prefix then
			tmpstr = string.gsub(TPL_ctype_pre, "$var", var)
			tmpstr = string.gsub(tmpstr, "$prefix", prefix)
			return indent .. string.gsub(tmpstr, "$debug", debug_str)
		else
			tmpstr = string.gsub(TPL_ctype, "$var", var)
			return indent .. string.gsub(tmpstr, "$debug", debug_str)
		end
	else
		return ""
	end
end

function Generator.getsubtable(var, level, is_else)
	local indent = string.rep(INDENT, 2 + level)
	if is_else then
		return indent .. string.gsub(TPL_getsubtable_else, "$var", var)
	else
		return indent .. string.gsub(TPL_getsubtable, "$var", var)
	end
end

function Generator.function_footer(funcName, params_str)
	local function_footer

	function_footer = string.gsub(TPL_function_footer, "$y_api_full", funcName)
	function_footer = string.gsub(function_footer, "$params", params_str)

	return function_footer
end