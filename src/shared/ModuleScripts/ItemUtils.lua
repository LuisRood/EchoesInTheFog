local ItemUtils = {}

function ItemUtils.NormalizeItemName(itemName, ...)
	if typeof(itemName) ~= "string" then
		return itemName
	end

	local trimmed = string.match(itemName, "^%s*(.-)%s*$")
	if trimmed == "" then
		return itemName
	end

	local databases = { ... }

	for _, db in ipairs(databases) do
		if db and db[trimmed] then
			return trimmed
		end
	end

	local lowered = string.lower(trimmed)
	for _, db in ipairs(databases) do
		if db then
			for key in pairs(db) do
				if string.lower(key) == lowered then
					return key
				end
			end
		end
	end

	return trimmed
end

return ItemUtils
