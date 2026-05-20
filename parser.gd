class_name PiyanScript
extends RefCounted

const DELIMITER = " "
const QUOTE = "\""
const OPERATOR_LIST = ["==", ">", ">=", "<", "<=", "!="]

const STATUS_BREAK = 0
const STATUS_RETURN = 1

const KEYWORD_LABEL = "label"
const KEYWORD_SET = "set"
const KEYWORD_ENDLABEL = "endlabel"
const KEYWORD_JUMP = "jump"
const KEYWORD_IF = "if"
const KEYWORD_ENDIF = "endif"
const KEYWORD_LOOP= "loop"
const KEYWORD_BREAK= "break"
const KEYWORD_ENDLOOP= "endloop"
const KEYWORD_EXIT= "exit"

var variable = {
    x = true,
    y = 2,
    z = true
}


var _labels = {}

var _block = {
    KEYWORD_IF : KEYWORD_ENDIF,
    KEYWORD_LOOP : KEYWORD_ENDLOOP,
}

var _keyword_split = {
    KEYWORD_IF : func(line: String):
        line = line.substr(KEYWORD_IF.length() + DELIMITER.length())
        var op = ""
        for operator in OPERATOR_LIST:
            if operator in line:
                op = operator
                break
        
        if op.is_empty():
            var split = Array(line.split(DELIMITER))
            var var_id = split.pop_front().strip_edges()
            var func_name = var_id.replace("$", "")
            if func_name in _custom_if_condition:
                return [KEYWORD_IF, var_id, split]
            else:
                return [KEYWORD_IF, var_id, "==", "true"]

        var condition = line.split(op)
        var result = [KEYWORD_IF, condition[0].strip_edges(), op, condition[1].strip_edges()]
        return result
        ,
}

var _runner = {
    KEYWORD_IF : func(args, block, remaining_commands):
            var func_name = args[0].replace("$", "")
            if func_name in _custom_if_condition:
                var is_pass = _custom_if_condition[func_name].callv(args[1])
                if is_pass:
                    return await _run_parsed_lines(block)
                return
                
            var _var = _get_var(args[0])
            var op = args[1]
            var expected_value = args[2]
            
            if _is_compare_pass(_var, str_to_var(expected_value), op):
                var status = await _run_parsed_lines(block)
                return status
            ,

    KEYWORD_LOOP : func(_args, block, remaining_commands):
            while true:
                var status = await _run_parsed_lines(block)
                print("while status ", status)
                if status != null:
                    break
            ,

    KEYWORD_JUMP : func(args, _block):
        var label_name = args[0]
        var source_list= []
        for line in _labels[label_name]:
            source_list.append({
                source = line,
                block = []
            })

        for source in source_list:
            var code = source.source
            await run_line(source)
        ,
    KEYWORD_SET : func(args, block, remaining_commands):
        var id = args[0]
        var value = args[1]
        _setted_var[id] = value
        ,
        
    "text" : func(args, block, remaining_commands):
        print("text with ", args[0])        
        if remaining_commands.front() == null || remaining_commands.front() != "text":
            print("showing dialogue...")
        await Engine.get_main_loop().create_timer(1).timeout
        ,

    "shop" : func(args, block, remaining_commands):
        print("shopping")        
        await Engine.get_main_loop().create_timer(1).timeout
        ,
                
}


var _custom_if_condition = {
    "test" = func(text):
        if text == "anjay":
            return true

        return false
}

var _is_exit = false
var _setted_var = {"_internal_var" : "anjay"}

    
func from_path(path):
    var file = FileAccess.open(path, FileAccess.READ)
    await from_text(file.get_as_text())


func from_text(text):
    var labels = _parse_label(text)
    _labels = labels.labels

    _is_exit = false
    var lines = labels.main_commands
    var parsed = _preparse(lines)
    await _run_parsed_lines(parsed)


func _run_parsed_lines(parsed_lines):
    var remaining_commands = _get_commands_from_sources(parsed_lines)

    for line in parsed_lines:
        remaining_commands.pop_front()
        var status = await run_line(line, remaining_commands)
        
        if status == STATUS_BREAK:
            return STATUS_BREAK
        elif status == STATUS_RETURN:
            return STATUS_RETURN
            
        if line.source == KEYWORD_EXIT:
            return STATUS_RETURN
        elif line.source == KEYWORD_BREAK:
            print(KEYWORD_EXIT)
            return STATUS_BREAK


func _split_args(line):
    var args = []
    var word = ""
    var inside_QUOTE = false
    
    for custom_split_id in _keyword_split:
        if line.begins_with(custom_split_id):
            return _keyword_split[custom_split_id].call(line)
    
    for char in line:
        if char == DELIMITER:
            if !inside_QUOTE:
                args.append(word)
                word = ""
                continue
            
        if char == QUOTE:
            inside_QUOTE = !inside_QUOTE
            continue
        word += char
    
    if !word.is_empty():
        args.push_back(word)
    
    for i in range(0, args.size()):
        if args[i].begins_with("_"):
            if args[i] in _setted_var:
                args[i] = _setted_var[args[i]]
            
    return args


func _preparse(lines: Array):
    var parsed_lines = []
    while !lines.is_empty():
        var line = lines.pop_front()
        var is_line_added = false
        for block_keyword in _block.keys():
            if line.begins_with(block_keyword):
                is_line_added = true
                var block_data = _parse_block(lines, block_keyword, _block[block_keyword])
                for i in range(0, block_data.line_count):
                    lines.pop_front()
                parsed_lines.push_back({source = line, block = _preparse(block_data.block)})
                break
        
        if !is_line_added:
            parsed_lines.push_back({source = line, block = []})
    
    return parsed_lines
    

func _split_lines(lines_str):
    var lines = []
    var split = lines_str.split("\n")
    for line: String in split:
        line = line.strip_edges()
        if line.is_empty():
            continue
        lines.push_back(line)
    
    return lines


func run_line(source = {source = "", block = []}, remaining_commands = []):
    var args = _split_args(source.source)
    var code = args.pop_front()
    
    if code in _runner:
        var status = await _runner[code].callv([args, source.block, remaining_commands])
        return status
        
        
func _parse_block(lines, start_pair, end_pair):
    var block = []
    var pair_found = 1
    var line_count = 0
    for line in lines:
        
        block.append(line)
        line_count += 1
        if line.begins_with(start_pair):
            pair_found += 1
            # print("found", pair_found)
            continue
        elif line.begins_with(end_pair):
            pair_found -= 1

            if pair_found == 0:
                # erase the end pair at the very back.
                block.pop_back()
                var result = {block = block, line_count = line_count}
                return result
            # print("end pair", pair_found)

                
    
func _get_var(var_str):
    var var_id = var_str.replace("$", "")
    assert(var_id in variable, str(var_id))
    return variable[var_id]


func _is_compare_pass(var_source, expected_str, operator):
    match operator:
        "==":
            return var_source == expected_str
        ">":
            return var_source > expected_str
        ">=":
            return var_source >= expected_str
        "<":
            return var_source < expected_str
        "<=":
            return var_source <= expected_str
        "!=":
            return var_source != expected_str


func _parse_label(text):
    var main_label = []
    var labels = {}
    var label_lines = []
    var lines = _split_lines(text)
    var current_label = ""
    var main_commands = []
    for line in lines:
        if line.begins_with(KEYWORD_LABEL):
            var label_split = line.split(" ")
            var label_name = label_split[1]
            current_label = label_name
            continue
        elif line.begins_with(KEYWORD_ENDLABEL):
            labels[current_label] = label_lines
            current_label = ""
            label_lines = []
            continue
            
        if !current_label.is_empty():
            label_lines.append(line)
        else:
            main_commands.append(line)
    
    return {labels = labels, main_commands = main_commands}


func _get_commands_from_sources(sources):
    var commands = []
    for source in sources:
        var split = _split_args(source.source)
        commands.append(split[0])
    
    return commands
