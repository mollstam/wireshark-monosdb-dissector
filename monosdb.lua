
local handshake_str = "DWP-Handshake"
local handshake_len = handshake_str:len()

local header_length = ProtoField.int32("monosdb.length", "length", base.DEC)
local header_id = ProtoField.int32("monosdb.id", "id", base.DEC)
local header_flags = ProtoField.uint8("monosdb.flags", "flags", base.DEC)
local header_command_set = ProtoField.int8("monosdb.command_set", "command set", base.DEC)
local header_command = ProtoField.int8("monosdb.command", "command", base.DEC)
local header_error_code = ProtoField.int16("monosdb.error_code", "error code", base.DEC)

local field_breakpoint_event = ProtoField.bool("monosdb.breakpoint_event", "breakpoint event")
local field_get_types_name = ProtoField.string("monosdb.get_types_name", "get types")

monosdb_protocol = Proto("MonoSDB", "Mono Soft Debugger Protocol")
monosdb_protocol.fields = { header_length, header_id, header_flags, header_command_set, header_command, header_error_code, field_breakpoint_event, field_get_types_name }

local proto_version_major = -1
local proto_version_minor = -1
local proto_version_set = false
local function check_proto_version(major, minor)
    if not proto_version_set then
        return false
    end

    return proto_version_major > major or (proto_version_major == major and proto_version_minor >= minor)
end

local function number_to_bin(x)
	ret=""
	while x~=1 and x~=0 do
		ret=tostring(x%2)..ret
		x=math.modf(x/2)
	end
	ret=tostring(x)..ret
	return ret
end

local function get_command_set_name(value)
    local command_set_name = "Unknown"

      if value ==  1 then command_set_name = "Virtual Machine"
  elseif value ==  9 then command_set_name = "Object reference"
  elseif value == 10 then command_set_name = "String reference"
  elseif value == 11 then command_set_name = "Threads"
  elseif value == 13 then command_set_name = "Array reference"
  elseif value == 15 then command_set_name = "Event request"
  elseif value == 16 then command_set_name = "Stack frame"
  elseif value == 20 then command_set_name = "AppDomain"
  elseif value == 21 then command_set_name = "Assembly"
  elseif value == 22 then command_set_name = "Method"
  elseif value == 23 then command_set_name = "Type"
  elseif value == 24 then command_set_name = "Module"
  elseif value == 64 then command_set_name = "Events" end

  return command_set_name
end

local function get_command_name(command_set, value)
    local command_name = "Unknown"

    if command_set == 1 then -- Virtual Machine
        if value == 1 then command_name = "VERSION"
        elseif value == 2 then command_name = "ALL_THREADS"
        elseif value == 3 then command_name = "SUSPEND"
        elseif value == 4 then command_name = "RESUME"
        elseif value == 5 then command_name = "EXIT"
        elseif value == 6 then command_name = "DISPOSE"
        elseif value == 7 then command_name = "INVOKE_METHOD"
        elseif value == 8 then command_name = "SET_PROTOCOL_VERSION"
        elseif value == 9 then command_name = "ABORT_INVOKE"
        elseif value == 10 then command_name = "SET_KEEPALIVE"
        elseif value == 11 then command_name = "GET_TYPES_FOR_SOURCE_FILE"
        elseif value == 12 then command_name = "GET_TYPES"
        elseif value == 13 then command_name = "INVOKE_METHODS"
        elseif value == 14 then command_name = "VM_START_BUFFERING"
        elseif value == 15 then command_name = "VM_STOP_BUFFERING" end
    elseif command_set == 15 or command_set == 64 then -- Event request and Events
        if value == 1 then command_name = "REQUEST_SET"
        elseif value == 2 then command_name = "REQUEST_CLEAR"
        elseif value == 3 then command_name = "REQUEST_CLEAR_ALL_BREAKPOINTS"
        elseif value == 100 then command_name = "COMPOSITE" end
    end

    return command_name
end

local function get_error_code_str(num)
    local error_code_str = "Unknown"

        if num ==   0 then error_code_str = "Success"
    elseif num ==  20 then error_code_str = "Invalid object"
    elseif num ==  25 then error_code_str = "Invalid field ID"
    elseif num ==  30 then error_code_str = "Invalid frame ID"
    elseif num == 100 then error_code_str = "Not Implemented"
    elseif num == 101 then error_code_str = "Not Suspended"
    elseif num == 102 then error_code_str = "Invalid argument"
    elseif num == 103 then error_code_str = "Unloaded"
    elseif num == 104 then error_code_str = "No Invocation"
    elseif num == 105 then error_code_str = "Absent information"
    elseif num == 106 then error_code_str = "No seq point at IL Offset" end

    return error_code_str
end

local function get_event_kind_name(value)
    local event_kind_name = "Unknown"

    if value == 0 then event_kind_name = "EVENT_KIND_VM_START"
    elseif value == 1 then event_kind_name = "EVENT_KIND_VM_DEATH"
    elseif value == 2 then event_kind_name = "EVENT_KIND_THREAD_START"
    elseif value == 3 then event_kind_name = "EVENT_KIND_THREAD_DEATH"
    elseif value == 4 then event_kind_name = "EVENT_KIND_APPDOMAIN_CREATE"
    elseif value == 5 then event_kind_name = "EVENT_KIND_APPDOMAIN_UNLOAD"
    elseif value == 6 then event_kind_name = "EVENT_KIND_METHOD_ENTRY"
    elseif value == 7 then event_kind_name = "EVENT_KIND_METHOD_EXIT"
    elseif value == 8 then event_kind_name = "EVENT_KIND_ASSEMBLY_LOAD"
    elseif value == 9 then event_kind_name = "EVENT_KIND_ASSEMBLY_UNLOAD"
    elseif value == 10 then event_kind_name = "EVENT_KIND_BREAKPOINT"
    elseif value == 11 then event_kind_name = "EVENT_KIND_STEP"
    elseif value == 12 then event_kind_name = "EVENT_KIND_TYPE_LOAD"
    elseif value == 13 then event_kind_name = "EVENT_KIND_EXCEPTION"
    elseif value == 14 then event_kind_name = "EVENT_KIND_KEEPALIVE"
    elseif value == 15 then event_kind_name = "EVENT_KIND_USER_BREAK"
    elseif value == 16 then event_kind_name = "EVENT_KIND_USER_LOG" end

    return event_kind_name
end

local function get_mod_kind_str(value)
    local mod_kind_str = "Unknown"

    if value == 1 then mod_kind_str = "MOD_KIND_COUNT"
    elseif value == 3 then mod_kind_str = "MOD_KIND_THREAD_ONLY"
    elseif value == 7 then mod_kind_str = "MOD_KIND_LOCATION_ONLY"
    elseif value == 8 then mod_kind_str = "MOD_KIND_EXCEPTION_ONLY"
    elseif value == 10 then mod_kind_str = "MOD_KIND_STEP"
    elseif value == 11 then mod_kind_str = "MOD_KIND_ASSEMBLY_ONLY"
    elseif value == 12 then mod_kind_str = "MOD_KIND_SOURCE_FILE_ONLY"
    elseif value == 13 then mod_kind_str = "MOD_KIND_TYPE_NAME_ONLY"
    elseif value == 14 then mod_kind_str = "MOD_KIND_NONE" end

    return mod_kind_str
end

local function dissect_vm_set_protocol_version(subtree, buffer, offset)
    local major = buffer(offset, 4):uint()
    local minor = buffer(offset + 4, 4):uint()
    subtree:add(buffer(offset, 4), "Major (" .. major .. ")")
    subtree:add(buffer(offset + 4, 4), "Minor (" .. minor .. ")")
    proto_version_major = major
    proto_version_minor = minor
    proto_version_set = true
end

local function dissect_vm_get_types(subtree, buffer, offset)
    local name_len = buffer(offset, 4):uint()
    local name = buffer(offset + 4, name_len):string()
    subtree:add(field_get_types_name, buffer(offset + 4, name_len), name)
    local ignore_case = buffer(offset + 4 + name_len, 1):uint()
    subtree:add(buffer(offset + 4 + name_len, 1), "Ignore case (" .. ignore_case .. ")")
end

local function dissect_event_composite(subtree, buffer, offset)
    subtree:add(buffer(offset, 1), "Suspend policy"):append_text(" (" .. buffer(offset, 1):uint() .. ")")
    local num_events = buffer(offset + 1, 4):uint()
    subtree:add(buffer(offset + 1, 4), num_events .. " Event(s)")
    local event_offset = offset + 5
    for i=1,num_events do
        local event_subtree = subtree:add(monosdb_protocol, buffer(), "Event " .. i)
        local event_kind = buffer(event_offset, 1):uint()
        local event_kind_name = get_event_kind_name(event_kind)
        event_subtree:add(buffer(event_offset, 1), "Event kind"):append_text(" (" .. event_kind_name .. ")")
        event_subtree:add(field_breakpoint_event, event_kind == 10)
        local event_request_id = buffer(event_offset + 1, 4):uint()
        event_subtree:add(buffer(event_offset + 1, 4), "Request ID"):append_text(" (" .. event_request_id .. ")")
        local event_thread_id = buffer(event_offset + 5, 4):uint()
        event_subtree:add(buffer(event_offset + 5, 4), "Thread ID"):append_text(" (" .. event_thread_id .. ")")
        event_offset = event_offset + 9
        if event_kind == 8 then -- Assembly load
            event_subtree:add(buffer(event_offset, 4), "Assembly ID"):append_text(" (" .. buffer(event_offset, 4):uint() .. ")")
            event_offset = event_offset + 4
        elseif event_kind == 10 or event_kind == 11 then -- Breakpoint and Step
            event_subtree:add(buffer(event_offset, 4), "Method ID"):append_text(" (" .. buffer(event_offset, 4):uint() .. ")")
            event_subtree:add(buffer(event_offset + 4, 8), "IL Offset"):append_text(" (" .. buffer(event_offset + 4, 8):uint64() .. ")")
            event_offset = event_offset + 12
        else
            event_subtree:add(buffer(event_offset), "Not implemented")
        end
    end
end

local function dissect_event_set(subtree, buffer, offset)
    local event_subtree = subtree:add(monosdb_protocol, buffer(), "Event")
    local event_kind = buffer(offset, 1):uint()
    local event_kind_name = get_event_kind_name(event_kind)
    event_subtree:add(buffer(offset, 1), "Event kind"):append_text(" (" .. event_kind_name .. ")")
    event_subtree:add(buffer(offset + 1, 1), "Suspend policy"):append_text(" (" .. buffer(offset + 1, 1):uint() .. ")")
    local num_mods = buffer(offset + 2, 1):uint()
    local modifiers_subtree = event_subtree:add(buffer(offset + 2), "Modifiers")
    modifiers_subtree:add(buffer(offset + 2, 1), "Count: " .. num_mods)
    local mod_offset = offset + 3    
    for i=1,num_mods do
        local mod_start = mod_offset
        local mod_kind = buffer(mod_offset, 1):uint()
        local mod_kind_str = get_mod_kind_str(mod_kind)
        local mod_subtree = modifiers_subtree:add(monosdb_protocol, buffer(mod_start), mod_kind_str)
        mod_subtree:add(buffer(mod_offset, 1), "ModKind (" .. mod_kind .. ")")
        if mod_kind == 1 then -- Count
            mod_subtree:add(buffer(mod_offset + 1, 4), "MethodID")
            mod_offset = mod_offset + 5
        elseif mod_kind == 3 then -- Thread only
            mod_subtree:add(buffer(mod_offset + 1, 4), "ThreadID")
            mod_offset = mod_offset + 5
        elseif mod_kind == 7 then -- Location only
            mod_subtree:add(buffer(mod_offset + 1, 4), "MethodID")
            mod_subtree:add(buffer(mod_offset + 5, 8), "Location")
            mod_offset = mod_offset + 13
        elseif mod_kind == 8 then -- Exception only
            mod_subtree:add(buffer(mod_offset + 1, 4), "TypeID (" .. buffer(mod_offset + 1, 4):uint() .. ")")
            mod_subtree:add(buffer(mod_offset + 5, 1), "Caught (" .. buffer(mod_offset + 5, 1):uint() .. ")")
            mod_subtree:add(buffer(mod_offset + 6, 1), "Uncaught (" .. buffer(mod_offset + 6, 1):uint() .. ")")
            mod_offset = mod_offset + 7
            if check_proto_version(2, 25) then
                mod_subtree:add(buffer(mod_offset, 1), "Subclasses (" .. buffer(mod_offset, 1):uint() .. ")")
                mod_offset = mod_offset + 1
            end
            if check_proto_version(2, 54) then
                mod_subtree:add(buffer(mod_offset, 1), "Not filtered feature (" .. buffer(mod_offset, 1):uint() .. ")")
                mod_subtree:add(buffer(mod_offset + 1, 1), "Everything else (" .. buffer(mod_offset + 1, 1):uint() .. ")")
                mod_offset = mod_offset + 2
            end
        -- implement more here
        end

        mod_subtree:set_len(mod_offset-mod_start)
    end
end

function monosdb_protocol.dissector(buffer, pinfo, tree)
    length = buffer:len()
    if length == 0 then return end

    pinfo.cols.protocol = monosdb_protocol.name

    local subtree = tree:add(monosdb_protocol, buffer(), "Mono Soft Debugger Protocol")

    if buffer:len() >= handshake_len and buffer(0, handshake_len):string() == handshake_str then
        local handshake_subtree = subtree:add(monosdb_protocol, buffer(), "Handshake")
        handshake_subtree:add(buffer(0, handshake_len), handshake_str)
        subtree:append_text(", Bootstrap")
        return
    end

    local flags_num = buffer(8, 1):uint()
    if flags_num == 0x00 then -- Command
        local command_header_subtree = subtree:add(monosdb_protocol, buffer(), "Command packet header")
        command_header_subtree:add(header_length, buffer(0, 4))
        local command_id = buffer(4, 4):uint()
        command_header_subtree:add(header_id, buffer(4, 4))
        command_header_subtree:add(header_flags, buffer(8, 1))
        local command_set_num = buffer(9, 1):uint()
        local command_set_name = get_command_set_name(command_set_num)
        command_header_subtree:add(header_command_set, buffer(9, 1)):append_text(" (" .. command_set_name .. ")")
        local command_num = buffer(10, 1):uint()
        local command_name = get_command_name(command_set_num, command_num)
        command_header_subtree:add(header_command, buffer(10, 1)):append_text(" (" .. command_name .. ")")

        local command_subtree = subtree:add(monosdb_protocol, buffer(), "Command " .. command_set_name .. " " .. command_name .. " packet")
        if command_set_num == 1 then -- Virtual machine
            if command_num == 5 then
                -- Exit
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 7 then
                -- Invoke method
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 8 then
                -- Set protocol version
                dissect_vm_set_protocol_version(command_subtree, buffer, 11)
            elseif command_num == 9 then
                -- Abort invoke
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 10 then
                -- Set keep alive
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 11 then
                -- Get types for source file
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 12 then
                -- Get types
                dissect_vm_get_types(command_subtree, buffer, 11)
            elseif command_num == 13 then
                -- Invoke methods
                command_subtree:add(buffer(), "Not implemented")
            end
        elseif command_set_num == 15 or command_set_num == 64 then -- Event requests and Events
            if command_num == 1 then
                -- Set
                dissect_event_set(command_subtree, buffer, 11)
            elseif command_num == 2 then
                -- Clear
                command_subtree:add(buffer(), "Not implemented")
            elseif command_num == 100 then
                -- Composite
                dissect_event_composite(command_subtree, buffer, 11)
            end
        end

        subtree:append_text(", Command #" .. command_id .. ", " .. command_set_name)

    elseif flags_num == 0x80 then -- Reply
        local reply_header_subtree = subtree:add(monosdb_protocol, buffer(), "Reply packet header")
        reply_header_subtree:add(header_length, buffer(0, 4))
        local command_id = buffer(4, 4):uint()
        reply_header_subtree:add(header_id, command_id)
        reply_header_subtree:add(header_flags, flags_num)
        local error_code_num = buffer(9, 2):uint()
        local error_code_str = get_error_code_str(error_code_num)
        reply_header_subtree:add(header_error_code, error_code_num):append_text(" (".. error_code_str .. ")")

        subtree:append_text(", Reply #" .. command_id .. ", " .. error_code_str)
    end
end

local tcp_table = DissectorTable.get("tcp.port")
--tcp_table:add_for_decode_as(monosdb_protocol)
tcp_table:add(56792, monosdb_protocol)
