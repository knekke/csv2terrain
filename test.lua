-- Function to read the block names from the file and store them in a set
local function readBlockNames()
  local blockNames = {}

  -- Open the file in read mode
  local file = io.open("block_names.txt", "r")

  -- Read the file line by line
  local x = 1
  local result = ""
  for line in file:lines() do

    -- Strip line breaks and leading/trailing whitespaces
    line = line:gsub("^%s*(.-)%s*$", "%1")
    a = string.match(line, ":(.+)")
    -- print(a)
    -- Add the block name to the set
    if a ~= nil then
      blockNames[a] = line
    end
    x  = x+1
  end

  -- Close the file
  file:close()
  return blockNames
end

local blockNames = readBlockNames()

print(blockNames['concrete_magenta'])
for keys, value in ipairs(blockNames) do
  print(value)
end