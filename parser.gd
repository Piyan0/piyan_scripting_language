class_name PiyanScript
extends Node

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
    x = 1,
    y = true,
}
var _labels = {}
var _callbacks = {}
var _setted_var = {}


func _init() -> void:
    _callbacks.test = func(arg):
        # print("args ", arg)
        if arg == "godot":
            return true
        return false

    _callbacks.test2 = func(args, remaining_commands):
        print("test2 with ", args[0])        
        await Engine.get_main_loop().create_timer(1).timeout
        
    _setted_var.test = "_internal var"

    # print(_split_args("anjay \"keren euy\""))
    # print(_check_if_conditions("if $test oke"))

    
func from_path(path):
    var file = FileAccess.open(path, FileAccess.READ)
    await from_text(file.get_as_text())


func from_text(text):
    var labels = _parse_label(text)
    _labels = labels.labels
    var lines = labels.main_commands
    # print(lines)
    await run(lines)


func _split_args(line):
    var args = []
    var word = ""
    var inside_QUOTE = false
   
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


func _is_compare_pass(source_var, operator, expected_var):
    # printt("source_var ", source_var, "operator ",operator, "expected_var ", expected_var)
    match operator:
        "==":
            return source_var == expected_var
        ">":
            return source_var > expected_var
        ">=":
            return source_var >= expected_var
        "<":
            return source_var < expected_var
        "<=":
            return source_var <= expected_var
        "!=":
            return source_var != expected_var


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


func _get_commands_from_sources(lines):
    var commands = []
    for line in lines:
        var split = _split_args(line)
        commands.append(split[0])
    
    return commands



func _check_if_conditions(code = "if $y == on"):
    # print("if ", code)
    var regex = RegEx.new()
    # if $(x) (==) (on)
    regex.compile(r"if\s*\$(\w+)\s*(==|!=)\s*(\w+)")
    var result= regex.search(code)

    if result != null:
        var match = result.strings
        # print(match)
        return _is_compare_pass(variable[match[1]], match[2], str_to_var(match[3]))
    else:
        # if $(x) (args)]
        regex.compile(r"if \$(\w+)\s*(.*)")
        result = regex.search(code)
        var match = result.strings
        var id = match[1]

        if id in variable:
            return _is_compare_pass(variable[match[1]], "==", true)
        else:
            assert(id in _callbacks, str(id))
            var args = _split_args(match[2])
            # print("args ", args)
            return _callbacks[id].callv(args)



func run(lines: Array):
    var loop_stack = []
    var line_index = 0
    var skip_depth = 0
    var code_list = _get_commands_from_sources(lines)
    var ignore_line = [Keyword.ENDIF]
    
    while line_index < lines.size():
        # print(line_index)
        var line = lines[line_index]
        var args = line
        args = _split_args(args)
        var code: String = args.pop_front()

        if skip_depth > 0:
            if code.begins_with(Keyword.IF):
                skip_depth += 1
            elif code.begins_with(Keyword.ENDIF):
                skip_depth -= 1
            line_index += 1
            continue

        if code.begins_with(Keyword.IF):
            if !_check_if_conditions(line):
                skip_depth = 1
        elif code.begins_with(Keyword.EXIT):
            break
        
        elif code in ignore_line:
            pass

        else:
            assert(code in _callbacks, str(code))
            await _callbacks[code].callv([args, code_list.slice(line_index + 1)])
        
        line_index += 1
