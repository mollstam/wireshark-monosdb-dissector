
# Wireshark Mono SDB Dissector

Use to analyze Mono Soft Debugger packets between debuggee runtime and debugger client.

Very basic, mostly just decodes the packet headers. Some commands are more deeply decoded.

Place `monosdb.lua` file in `%APPDATA%\Wireshark\plugins\` (see Wireshark docs for more info). Bottom line in Lua file binds the dissector to a specific port, change that to whatever port you are using so you don't have to keep selecting "Decode As..." in Wireshark.