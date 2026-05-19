class_name PiyanScript
extends RefCounted

const DELIMITER = " "
const QUOTE = "\""
const OPERATOR_LIST = ["==", ">", ">=", "<", "<=", "!="]

const KEYWORD_IF = "if"
const KEYWORD_ENDIF = "endif"
const KEYWORD_LOOP= "loop"
const KEYWORD_BREAK= "break"
const KEYWORD_ENDLOOP= "endloop"
const KEYWORD_exit= "exit"

var variable = {
    x = true,
    y = 1
}

var _block = {
    KEYWORD_IF : KEYWORD_ENDIF,
    KEYWORD_LOOP : KEYWORD_ENDLOOP,
}

var _custom_split = {
    KEYWORD_IF : (func(line):
        line = line.replace(KEYWORD_IF, "")
        var op = ""
        for operator in OPERATOR_LIST:
            if operator in line:
                op = operator
                break
        var condition = line.split(op)
        
        var result = [KEYWORD_IF, condition[0].strip_edges(), op, condition[1].strip_edges()]
        return result
        ),
}

var _built_in_keyword_runner = {
    # remaining_lines add arg
    KEYWORD_IF : func(args):
        var _var = _get_var(args[0])
        var op = args[1]
        var expected_value = args[2]
        
        if _is_compare_pass(_var, str_to_var(expected_value), op):
            var block = args.back()
            for line in block:
                await _run_line(line)
                
}


var runner = {
    text = func(args):
        print("text with ", args[0])
}


func _init() -> void:
    var line = "text salwa \"nah ini dia yamg aku maksud bro..\" token_1"
    var line_2 = ("
if $y==1
        text salwa
        open-inv $my var
        exit
        
        if $x == true
            text this-is-nested-loop...
        endif
endif
text anjay-mabar
" 
    )
    var lines = _split_lines(line_2)
    var x = _preparse(lines)
    print(JSON.stringify(x, "\t"))

func _split_args(line):
    var args = []
    var word = ""
    var inside_QUOTE = false
    
    for custom_split_id in _custom_split:
        if line.begins_with(custom_split_id):
            return _custom_split[custom_split_id].call(line)
    
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
    
    return args


func _preparse(lines: Array):
    var parsed_lines = []
    while !lines.is_empty():
        var line = lines.pop_front()
        if line.begins_with(KEYWORD_IF):
            var block_data = _parse_block(lines, KEYWORD_IF, KEYWORD_ENDIF)
            for i in range(0, block_data.line_count):
                lines.pop_front()

            parsed_lines.push_back({source = line, block = _preparse(block_data.block)})

        else:
            parsed_lines.push_back({source = line})
    
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


func _find_pair_from_lines_arr(lines: Array, pair_end):
    var line_count = 0
    var valid_lines = []
    for line in lines:
        if line == pair_end:
            return {lines = lines, line_count = line_count}
        line_count += 1
        valid_lines.push_back(line)


func _run_line(line):
    var code = line.pop_front()
    var args = line
    printt("running", code)
    if code in _built_in_keyword_runner:
        await _built_in_keyword_runner[code].callv(args)
    else:
        await runner[code].callv(args)


func run_lines(sources):
    pass
            
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
