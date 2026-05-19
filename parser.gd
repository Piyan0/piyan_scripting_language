class_name PiyanScript
extends RefCounted

var variable = {
    x = true,
    y = "Hawa"
}

const delimiter = " "
const quote = "\""

var built_in_code = {
         
}

func _init() -> void:
    var line = "text salwa \"nah ini dia yamg aku maksud bro..\" token_1"
    var line_2 = ("
if $salwa == 2
        text salwa
    open-inv $my_var
endif
text piyan
    "    
    )
    var lines = _split_lines(line_2)
    _run_lines(lines)
    # print(_tokenize_line(line_2))


func _tokenize_line(line):
    var args = []
    var word = ""
    var inside_quote = false

    for char in line:
        if char == delimiter:
            if !inside_quote:
                args.append(word)
                word = ""
                continue
            
        if char == quote:
            inside_quote = !inside_quote
            continue
        word += char
    
    if !word.is_empty():
        args.push_back(word)
    
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


func _find_pair_from_lines_arr(lines: Array, pair_end):
    var valid_lines = []
    for line in lines:
        if line == pair_end:
            return valid_lines
        valid_lines.push_back(line)
    
    return valid_lines


func _run_lines(lines):
    print(lines)
    return 
    for line in lines:
        var token = _tokenize_line(line)
        var code = token.pop_front()

        print(code)


func _detect_builtin_keyword():
    pass
