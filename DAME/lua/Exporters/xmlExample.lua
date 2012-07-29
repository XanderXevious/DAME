

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(0)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"
tab4 = "\t\t\t\t"

dataDir = as3.tolua(VALUE_DataDir)
levelName = as3.tolua(VALUE_LevelName)

-- Output tilemap data
-- slow to call as3.tolua many times.

function exportMapCSV( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix,keywords)
	mapText = tab1.."<tilesAbove set=\""..layerFileName.."\">\n"..as3.tolua(DAME.ConvertMapToText(mapLayer,"","",tab2.."<tile ","","","tx=\"%tilex%\" ty=\"%tiley%\" x=\"%pxpos%\" y=\"%pypos%\"/>\n", true))
	mapText = mapText..tab1.."</tilesAbove>\n"
	return mapText
end

-- This is the file for the map level class.
fileText = ""

maps = {}
spriteLayers = {}

masterLayerAddText = ""
stageAddText = tab3.."if ( addToStage )\n"
stageAddText = stageAddText..tab3.."{\n"

for groupIndex = 0,groupCount do
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
	
	
	layerCount = as3.tolua(group.children.length) - 1
	
	fileText = "<level>\n"
	
	
	-- Go through each layer and store some tables for the different layer types.
	for layerIndex = 0,layerCount do
		layer = group.children[layerIndex]
		isMap = as3.tolua(layer.map)~=nil
		layerSimpleName = as3.tolua(layer.name)
		layerSimpleName = string.gsub(layerSimpleName, " ", "_")
		layerName = groupName..layerSimpleName
		if isMap == true then
			
			-- This needs to be done here so it maintains the layer visibility ordering.
			table.insert(maps,{layer,layerName})
	
		elseif as3.tolua(layer.IsSpriteLayer()) == true then
			table.insert( spriteLayers,{groupName,layer,layerName})
			stageAddText = stageAddText..tab4.."addSpritesForLayer"..layerName.."(onAddSpritesCallback);\n"
		end
	end
end

for i,v in ipairs(maps) do
	fileText = fileText..exportMapCSV( maps[i][1], maps[i][2] )
end


-- create the sprites.

fileText = fileText..tab1.."<objects>\n"
for i,v in ipairs(spriteLayers) do
	creationText = tab2.."<%class% x=\"%xpos%\" y=\"%ypos%\"/>\n" 

	fileText = fileText..as3.tolua(DAME.CreateTextForSprites(spriteLayers[i][2],creationText,"Avatar"))
end

fileText = fileText..tab1.."</objects>\n"
fileText = fileText.."</level>\n"
	
-- Save the file!

DAME.WriteFile(dataDir.."/Level_"..levelName..".xml", fileText )




return 1
