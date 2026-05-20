class_name PiyanScript
extends RefCounted

const DELIMITER = " "
const QUOTE = "\""
const OPERATOR_LIST = ["==", ">", ">=", "<", "<=", "!="]
const KEYWORD_EXIT= "exit"

const Keyword = {
    JUMP = "jump",
    LABEL = "label",
    SET = "set",
    ENDLABEL = "endlabel",
    IF = "if",
    ENDIF = "endif",
    LOOP = "loop",
    BREAK = "break",
    ENDLOOP = "endloop", 
    EXIT = "exit"
    
}

var variable = {
    x = true,
    y = 2,
    z = true
}


var _labels = {}

var _block = {
    Keyword.IF : Keyword.ENDIF,
    Keyword.LOOP : Keyword.ENDLOOP,
}

var _keyword_split = {
    Keyword.IF : func(line: String):
        line = line.substr(Keyword.IF.length() + DELIMITER.length())
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
                return [Keyword.IF, var_id, split]
            else:
                return [Keyword.IF, var_id, "==", "true"]

        var condition = line.split(op)
        var result = [Keyword.IF, condition[0].strip_edges(), op, condition[1].strip_edges()]
        return result
        ,
}

var _runner = {
    Keyword.IF: _runner_if,
    Keyword.LOOP : _runner_loop,
    Keyword.JUMP : _runner_jump,
    Keyword.SET : _runner_set,
        
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

var _setted_var = {"_internal_var" : "anjay"}

    
func from_path(path):
    var file = FileAccess.open(path, FileAccess.READ)
    await from_text(file.get_as_text())


func from_text(text):
    var labels = _parse_label(text)
    _labels = labels.labels
    var lines = labels.main_commands
    await run(lines)


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
    

func _split_lines(lines_str):
    var lines = []
    var split = lines_str.split("\n")
    for line: String in split:
        line = line.strip_edges()
        if line.is_empty():
            continue
        lines.push_back(line)
    
    return lines

    
    
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
        if line.begins_with(Keyword.LABEL):
            var label_split = line.split(" ")
            var label_name = label_split[1]
            current_label = label_name
            continue
        elif line.begins_with(Keyword.ENDLABEL):
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


func run(lines):
    var line_index = -1
    while true:
        line_index += 1
        if line_index > lines.size()-1:
            break
        
        var line = _split_args(lines[line_index])
        print(line[0])
