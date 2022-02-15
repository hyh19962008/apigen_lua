# apigen_lua
用来自动生成y_api函数所需的cpp代码的生成器，使用global进行符号查找，[CParser](https://github.com/facebookresearch/CParser)进行.h文件结构体解析。

# Requirement
> - Lua >= 5.3
> - Gnu global

# Usage
放到simulator目录下  
`$ ./apigen_lua.sh y_api_function > output.cpp`

# Functionality
[x] 忽略pad, rsv 等字段  
[x] 关键字段加上debug=true(需要完善, 目前只有entry_valid字段)  
[x] union 类型后继全部设置debug=false, 优先级高于关键字段  
[x] bitfield 和 getkey语句分开  
[x] 特殊处理字段 MacAddress, IPv6, mask  
[x] function footer 特殊处理 (EM/LPM表)  
[x] y_api_full 的指针  
[x] 搜索失败时检查set, 提示add/modify  
[x] 添加正确的注释   
[x] function_head 的命名规范  
[x] void 类型报错处理  

# Other
global工具会生成以下文件，请不要删除:  
`GPATH  GRTAGS  GTAGS  gtags_list`