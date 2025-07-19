function table.merge(og_table, new_table)
	if not new_table then
		return og_table
	end

	for i, data in pairs(new_table) do
		i = type(data) == "table" and data.index or i
		if type(data) == "table" and type(og_table[i]) == "table" then
			og_table[i] = table.merge(og_table[i], data)
		else
			og_table[i] = data
		end
	end
	return og_table
end
