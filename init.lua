-- See the README for information


function get_node_names ()
	-- Open the output file in write mode
	local file = io.open(minetest.get_modpath("csv2terrain").."/block_names.txt", "w")

	-- Iterate over all registered nodes
	for name, def in pairs(minetest.registered_nodes) do
	  -- Write the block name to the file
	  file:write(name .. "\n")
	end

	-- Close the file
	file:close()

end

-- Function to read the block names from the file and store them in a set
local function readBlockNames()
  local blockNames = {}

  -- Open the file in read mode
  local file = io.open(minetest.get_modpath("csv2terrain").."/block_names.txt", "r")

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

local function round(value)
  	return math.floor(value + 0.5)
end


function csv2terrain()
	
    -- Get the player and their position
    local player = minetest.get_player_by_name("singleplayer")
    local player_pos = player:get_pos()
    local player_yaw = player:get_look_horizontal()

    -- Variables for bounding box coordinates and player position
    local x0, y0, z0, x1, y1, z1
    local player_x, player_y, player_z

    -- Read the coordinates from the CSV file
    for line in io.lines(minetest.get_modpath("csv2terrain") .. "/blocks.csv") do
        local x, y, z, block = line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-),")
        if block == "min" then
            x0, y0, z0 = round(tonumber(x)), round(tonumber(y)), round(tonumber(z))
        elseif block == "max" then
            x1, y1, z1 = round(tonumber(x)), round(tonumber(y)), round(tonumber(z))
        elseif block == "player" then
            player_x, player_y, player_z = round(tonumber(x)), round(tonumber(y)), round(tonumber(z))
        end
    end

    -- Define the bounding box positions relative to the player
    local pos1 = {x = x0 + player_pos.x, y = y0 + player_pos.y, z = z0 + player_pos.z}
    local pos2 = {x = x1 + player_pos.x, y = y1 + player_pos.y, z = z1 + player_pos.z}
    minetest.log("pos1: " ..minetest.pos_to_string(pos1))
    minetest.log("player: " ..minetest.pos_to_string(player_pos))

    -- Initialize the voxel manipulator
    local manip = minetest.get_voxel_manip()
    local edge0, edge1 = manip:read_from_map(pos1, pos2)
    local area = VoxelArea:new{MinEdge = edge0, MaxEdge = edge1}
    local data = manip:get_data()

    -- Get block names mapping
    local blockNames = readBlockNames()

    -- Iterate through the CSV file to place blocks
    for line in io.lines(minetest.get_modpath("csv2terrain") .. "/blocks.csv") do
        local x, y, z, block = line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-),")
        if block ~= "min" and block ~= "max" and block ~= "player" then
            -- Adjust block coordinates relative to the player
            x = x + player_pos.x
            y = y + player_pos.y
            z = z + player_pos.z
            local test = {round(tonumber(x)), round(tonumber(y)), round(tonumber(z))}
            local j = area:index(round(tonumber(x)), round(tonumber(y)), round(tonumber(z)))
            if block == "air" then
                data[j] = minetest.get_content_id(block)
            else
                if blockNames[block] ~= nil then
                	minetest.log("xyz: " ..x .. ' ' ..y ..' '..z)
                    data[j] = minetest.get_content_id(blockNames[block])
                    --minetest.log(blockNames[block])
                else
                    data[j] = minetest.get_content_id("mcl_bamboo:bamboo")
                    minetest.log("Block name not found: " .. block)
                end
            end
        end
    end

    -- Apply the modified data to the voxel manipulator and update the map
    manip:set_data(data)
    manip:write_to_map()
    manip:update_map()

    -- Set player position just outside the bounding box
    local player_pos_x = x1 - 2 + player_pos.x
    local player_pos_y = y0 + 1 + player_pos.y
    local player_pos_z = z1 + 2 + player_pos.z

    -- Calculate the player's yaw to look towards the center of the bounding box
    local dx = (x0 + x1) / 2 - player_pos_x
    local dz = (z0 + z1) / 2 - player_pos_z
    local player_yaw = math.atan2(dz, dx)

    -- Set the player's position and look direction
    player:set_pos({x = player_pos_x, y = player_pos_y, z = player_pos_z})
    player:set_look_horizontal(player_yaw)
end




function csv2air ()

	for line in io.lines(minetest.get_modpath("csv2terrain").."/blocks.csv")  do
		local x, y, z, block = line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-),")
		if block=="min" then
			x0, y0, z0 = tonumber(x), tonumber(y), tonumber(z)
    	end
    	if block=="max" then
       		 x1, y1, z1 = tonumber(x), tonumber(y), tonumber(z)
   		end
  	end

	local pos1 = {x = x0, y = y0, z = z0}
	local pos2 = {x = x1, y = y1, z = z1}

	local manip = minetest.get_voxel_manip()
	local edge0, edge1 = manip:read_from_map(pos1, pos2)
 	local area = VoxelArea:new{MinEdge=edge0, MaxEdge=edge1}
  	local data = manip:get_data()

    for x = x0, x1 do
        for y = y0, y1+(y1-y0)/2 do
            for z = z0, z1 do
                local j = area:index(tonumber(x), tonumber(y), tonumber(z))
                data[j] = minetest.get_content_id ("air")
            end
        end
    end
  
 	manip:set_data(data)
 	manip:write_to_map()
	manip:update_map()
	
	local player = minetest.get_player_by_name("singleplayer")
	playername = player.get_player_name(player)
	local privs = minetest.get_player_privs(playername)
	privs.fly = true
	minetest.set_player_privs(playername, privs)
	for line in io.lines(minetest.get_modpath("csv2terrain").."/blocks.csv")  do
		local x, y, z, block = line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-),")
		z = z1 - z + z0
		if block=="player" then
			xp, yp, zp = tonumber(x), tonumber(y), tonumber(z)
			player:set_pos( {x=xp, y=yp, z=zp} )
		end
  	end     
  
end


minetest.register_chatcommand("ltbv", {
    func = csv2air,
    func = csv2terrain,
})

minetest.register_chatcommand("ltba", {
    func = csv2air,
})

minetest.register_chatcommand("ltbn", {
    func = get_node_names,
})

minetest.clear_registered_biomes() 
