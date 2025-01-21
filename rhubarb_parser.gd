extends Object

func parse(input: String) -> Array:
	var split_input = input.split("\r\n")
	var result = []
	for pair in split_input:
		var split_pair = pair.split("\t")
		if split_pair.size() != 2:
			continue
		result.append([float(split_pair[0]), split_pair[1]])
	return result
