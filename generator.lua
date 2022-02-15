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
-- the $expr, though in a weird position, are intented to fix the indent
TPL_mask = [[// if mask provided a string "all", set all the mask field to 1
		if(getKey(L, "mask", maskMode, false) != 0) {
			luaL_getsubtable(L, -1, "mask");
			if(lua_istable(L, -1)) {
				lua_pop(L, 1);			// the generated $.expr should reload mask
$expr
			}
			else{
				printDebugInfo(apiName, "mask not found");
				lua_pop(L, 1);
			}
		}
		else {
			if(maskMode == "all") {
				std::array<uint8_t, sizeof($type)> tmpFFArray;
				tmpFFArray.fill(0xff);
				memcpy(&mask, tmpFFArray.data(), sizeof($type));
			}
			else 
				printDebugInfo("Error getting " + apiName + " Mask.");
		}
]]

TPL_comment = [[
	/**
	 * $prefix_$y_api
	 * $more
	 */ 
]]
TPL_function_head = "\tint $prefix_$y_api(lua_State *L) {\n"
TPL_function_footer = [[
		if(ret != 0)
			return ret;
		return $y_api_full($params);
]]
TPL_function_footer_em = [[
		if(ret != 0)
			return ret;
		else {
			ret = $funcp_match(npu_id, &request, &dummy, &entry_index);
			if(ret != 0)
				ret = $funcp_add(npu_id, &request, &response, &index);
			else
				ret = $funcp_modify(npu_id, &request, &response, &index);
			return ret;
		}
]]
TPL_function_footer_lpm = [[
		if(ret != 0)
			return ret;
		else {
			ret = $funcp_lookup(npu_id, table_index, &request, &tmpLpmResponse);
			if(tmpLpmResponse.route_type == 3 && tmpLpmResponse.l3_path_id == L3PathID_MAX)
				ret = $funcp_add(npu_id, table_index, &request, prefix_length, &response);
			else
				ret = $funcp_modify(npu_id, table_index, &request, prefix_length, &response);
			return ret;
		}
]]
TPL_function_closing = "\t}\n"

TPL_getsubtable = "LUAC_GETSUBTABLE($var,\n"
TPL_getsubtable_else = "LUAC_GETSUBTABLE_ELSE($var,\n"
---------------------------------------------------

INDENT = "\t"
COMMENT_INDENT = "\n\t * "

Generator = {}

-- generate defintion code for ctype
function Generator.ctype_def(param)
	return string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. Pair.get_name(param) .. ";\n"
end

-- generate defintion code for struct/union
function Generator.struct_def(param)
	return string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. Pair.get_name(param) .. " = {};\n"
end

-- check if var is a valid field
-- @param [string] var
-- @return [bool]
local function is_valid_field(var)
	local no_use = {"pad%d*$", "padding$", "rsv(_?)%d*$", "resv%d$", "reserve%d*$", "reserved%d*$"}

	for _, v in pairs(no_use) do
		if string.find(string.lower(var), v) then
			return false
		end
	end

	return true
end

-- check if var is a key field (whose debug filed should be set to true)
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
	elseif Pair.get_name(param) == "mask" and not param.not_special then
		return true
	else
		return false
	end
end

-- handle special fields, note that we directly modified 
-- the global variable `output_definition` here instead of return def
-- for further processing, just to keep the code logic clean.
-- @return [string] expr
function Generator.special_field(param, level, prefix, debug)
	local debug_str
	local tpl
	local tmpstr
	local var
	local varType
	local indent
	local def = ""
	local ss

	if debug then 
		debug_str = "true" 
	else 
		debug_str = "false" 
	end

	var = Pair.get_name(param)
	varType = Pair.get_type(param)
	tpl = TPL_special[varType]
	indent = string.rep(INDENT, level+2)

	if varType == "struct mac_address_t" then
		global_stats.def_mac_string = true
		ss = string.gsub("@mod $var_full = string", "$var_full", prefix .. "." .. var)
		table.insert(global_stats.comment_more, ss)
	elseif string.find(varType, "ipv6") or string.find(varType, "srv6") then
		global_stats.def_ipv6_string = true
		ss = string.gsub("@mod $var_full = ipv6 string", "$var_full", prefix .. "." .. var)
		table.insert(global_stats.comment_more, ss)
	elseif var == "mask" then
		def = string.rep(INDENT, 2) .. "std::string maskMode;\n"
		ss = string.gsub('@mod mask = string "all" | $type', "$type", varType)
		table.insert(global_stats.comment_more, ss)
		level = 2					-- fix indent
		param.not_special = true	-- skip is_special_field checking for get_struct()
		tmpstr = string.gsub(TPL_mask, "$type", varType)
		tmpstr = string.gsub(tmpstr, "$expr", get_struct(param, level, prefix, debug))
		tpl = ""					-- fix string concat at the end
		goto finish
	end

	-- code for mac_address_t, ipv6
	tmpstr = string.gsub(tpl[1], "$var", var)
	tmpstr = string.gsub(tmpstr, "$debug", debug_str)
	tpl = string.gsub(tpl[2], "$var_full", prefix .. "." .. var)

::finish::
	output_definition = output_definition .. def			-- output_definition is a global variable
	return indent .. tmpstr .. indent .. tpl
end

-- generate expression to read Lua script for ctype variable and field
-- @param [bool] debug, optional
-- @param [bool] in_union, optional
-- @return [string] expr
function Generator.ctype_expr(param, level, prefix, debug, in_union)
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
	if in_union then debug_str = "false" end		-- in_union is superior to is_key_field

	if is_valid_field(var) then
		if Pair.is_bitfield(param) then
			global_stats.has_bitfield = true
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

-- generate getsubtable code
-- @param [string] var
-- @param [int] level
-- @param [bool] is_else, optional
-- @param [bool] first_in_union, optional 
-- @retrun [string] expr
function Generator.getsubtable(var, level, is_else, first_in_union)
	local indent = string.rep(INDENT, 2 + level)
	local code = ""

	if first_in_union then
		code = indent .. "// union datatype, stop generating debug info\n"
	end

	if is_else then
		code = code .. indent .. string.gsub(TPL_getsubtable_else, "$var", var)
	else
		code = code .. indent .. string.gsub(TPL_getsubtable, "$var", var)
	end

	return code
end

-- generate function_footer code
-- @return [string] expr
function Generator.function_footer(funcName, params_str, params)
	local function_footer
	local is_add_func = false
	local funcp = ""
	local str1
	local str2

	if string.find(funcName, "_add") then 
		is_add_func = true 
		funcp = string.gsub(funcName, "_add", "")
	end

	-- lpm must be checked before em, cause is_lpm_table and is_em_table can be true at the same time
	if global_stats.is_lpm_table and is_add_func then
		for _, param in pairs(params) do
			if Pair.get_name(param) == "response" then
				str1 = Generator.struct_def(param)
				str2 = string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. "tmpLpmResponse" .. " = {};\n"
				output_definition = string.gsub(output_definition, str1, 
					str1 .. str2)
			end
		end
		function_footer = string.gsub(TPL_function_footer_lpm, "$funcp", funcp)
	elseif global_stats.is_em_tbale and is_add_func then
		output_definition = output_definition .. string.rep(INDENT, 2) .. "uint32_t entry_index;\n"
		for _, param in pairs(params) do
			if Pair.get_name(param) == "response" then
				str1 = Generator.struct_def(param)
				str2 = string.rep(INDENT, 2) .. Pair.get_type(param) .. " " .. "dummy" .. " = {};\n"
				output_definition = string.gsub(output_definition, str1, 
					str1 .. str2)
			end
		end
		function_footer = string.gsub(TPL_function_footer_em, "$funcp", funcp)
	else
		function_footer = string.gsub(TPL_function_footer, "$y_api_full", funcName)
		function_footer = string.gsub(function_footer, "$params", params_str)
	end

	return function_footer
end