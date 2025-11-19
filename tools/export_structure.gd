# tools/export_structure.gd
@tool
extends EditorScript

func _run():
	var output = "# Project Structure\n\n"
	var script_dir = "res://"
	
	output += scan_directory(script_dir, 0)
	
	var file = FileAccess.open("res://docs/code_structure.md", FileAccess.WRITE)
	file.store_string(output)
	file.close()
	
	print("结构导出完成！")


func scan_directory(path: String, depth: int) -> String:
	var result = ""
	var dir = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var indent = "  ".repeat(depth)
			
			if dir.current_is_dir():
				result += indent + "📁 " + file_name + "/\n"
				result += scan_directory(path + file_name + "/", depth + 1)
			else:
				if file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".godot") or file_name.ends_with(".cfg") or file_name.ends_with(".svg") or file_name.ends_with(".tres"):
					var line_count = count_lines(path + file_name)
					result += indent + "📄 " + file_name + " (%d lines)\n" % line_count
			
			file_name = dir.get_next()
	
	return result


func count_lines(file_path: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var count = 0
	
	while not file.eof_reached():
		file.get_line()
		count += 1
	
	file.close()
	return count
