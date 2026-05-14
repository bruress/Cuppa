extends RefCounted

static func full_parser(path: String, beat: float, offset: float) -> Array:
	var current_time: float = offset						# initial song timestamp
	var holds: Dictionary = {}								# temp for holds
	var all_notes_data: Array = []							# parsed notes buffer
	
	## Prepare to parsing
	var sm_file := FileAccess.open(path, FileAccess.READ)	# open file for reading
	if not sm_file:
		push_error("Cannot open chart file: " + path)
		return all_notes_data
	var content: String = sm_file.get_as_text()
	sm_file.close()
	var pos: int = content.find("0,0,0,0,0:")				# return id "0,0,0,0,0:"
	if pos == -1:
		push_error("Chart marker not found: " + path)
		return all_notes_data
	pos += 10												# skip 10 symbols without data notes
	var raw_data: String = content.substr(pos)				# load only clear text with data notes
	var measures: PackedStringArray = raw_data.replace(";", " ").split(",")	# split into measures
	
	## Work with one measure
	for measure in measures:								# take one measure
		var lines: Array = []
		for i in measure.strip_edges().split("\n"):			# split at "\n" and keep only lane rows
			if i.length() == 4:								# if it is our 4-lane data
				lines.append(i)

		if lines.is_empty():
			continue

		var time_per_line: float = (beat * 4.0) / float(lines.size())	# one measure has 4 beats
		
		## Work with line and symbols in it to know notes and holds
		for line in lines:
			for j in range(4):
				var symbol = line[j]						# current symbol
				match symbol:								# compare
					"1":
						all_notes_data.append({"time": current_time, "type": "note", "lane": j})
					"2":
						holds[j] = current_time				# start time
					"3":
						if holds.has(j):
							var duration: float = current_time - float(holds[j])
							all_notes_data.append({"time": float(holds[j]), "type": "hold", "lane": j, "duration": duration})
							holds.erase(j)
			current_time += time_per_line					# next line timestamp

	all_notes_data.sort_custom(func(a, b): return a.time < b.time)	# sort by time for spawn queue
	return all_notes_data
