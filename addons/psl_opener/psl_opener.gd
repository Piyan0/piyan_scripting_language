@tool
extends EditorPlugin

var found_trees: Array[Tree] = []

func _enter_tree() -> void:
	# Wait for the editor interface to fully stabilize
	await get_tree().process_frame
	
	var fs_dock = get_editor_interface().get_file_system_dock()
	_find_all_trees(fs_dock)
	
	# Connect to all Tree components found inside the FileSystem dock
	for tree in found_trees:
		if is_instance_valid(tree):
			tree.item_activated.connect(_on_item_double_clicked.bind(tree))

func _exit_tree() -> void:
	for tree in found_trees:
		if is_instance_valid(tree) and tree.item_activated.is_connected(_on_item_double_clicked):
			tree.item_activated.disconnect(_on_item_double_clicked)
	found_trees.clear()

# Recursively harvests all Tree layouts inside the dock (handles split-view)
func _find_all_trees(node: Node) -> void:
	if node is Tree:
		found_trees.append(node)
	for child in node.get_children():
		_find_all_trees(child)

func _on_item_double_clicked(tree: Tree) -> void:
	var selected_item = tree.get_selected()
	if not selected_item:
		return
		
	# Grab file path stored in metadata slot 0
	var file_path = selected_item.get_metadata(0)
	
	if file_path and typeof(file_path) == TYPE_STRING:
		if file_path.get_extension().to_lower() == "psl":
			var absolute_path = ProjectSettings.globalize_path(file_path)
			OS.shell_open(absolute_path)
