extends RefCounted

## Parses .sm file
## [path] - Path to .sm
## [beat] - Beat duration in seconds
## [offset] - Song start offset
static func full_parser(path: String, beat: float, offset: float) -> Array:
	var current_time: float = offset
	var holds: Dictionary = {}			# Keep hold starts by lane
	var all_notes_data: Array = []		# Save all parsed notes here
	
	# Prepare parser
	var sm_file := FileAccess.open(path, FileAccess.READ)
	if not sm_file:
		push_error("Cannot open chart file: " + path)
		return all_notes_data
	var content: String = sm_file.get_as_text()
	sm_file.close()

	# Skip
	var pos: int = content.find("0,0,0,0,0:")
	if pos == -1:
		push_error("Chart marker not found: " + path)
		return all_notes_data
	pos += 10

	# Split into measures
	var raw_data: String = content.substr(pos)
	var measures: PackedStringArray = raw_data.replace(";", " ").split(",")
	
	# Parse each measure
	for measure in measures:
		var lines: Array = []
		for i in measure.strip_edges().split("\n"):
			if i.length() == 4:		# Keep only 4-lane rows
				lines.append(i)

		if lines.is_empty():
			continue

		var time_per_line: float = (beat * 4.0) / float(lines.size())	# One measure has 4 beats
		
		# Parse symbols in each lane
		for line in lines:
			for j in range(4):
				var symbol = line[j]
				match symbol:
					"1":
						all_notes_data.append({"time": current_time, "type": "note", "lane": j})
					"2":
						holds[j] = current_time	
					"3":
						if holds.has(j):
							var duration: float = current_time - float(holds[j])
							all_notes_data.append({"time": float(holds[j]), "type": "hold", "lane": j, "duration": duration})
							holds.erase(j)
			current_time += time_per_line		# Move timeline to next row

	# Sort by time for stable spawn order
	all_notes_data.sort_custom(func(a, b): return a.time < b.time)
	return all_notes_data
