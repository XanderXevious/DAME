

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(3)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"
tab4 = "\t\t\t\t"
tab5 = "\t\t\t\t\t"
tab6 = "\t\t\t\t\t\t"
tab7 = "\t\t\t\t\t\t\t"

-- slow to call as3.tolua many times so do as much as can in one go and store to a lua variable instead.
exportOnlyCSV = as3.tolua(VALUE_ExportOnlyCSV)
flashpunkPackage = as3.tolua(VALUE_FlashPunkPackage)
baseClassName = as3.tolua(VALUE_BaseClass)
as3Dir = as3.tolua(VALUE_AS3Dir)
tileMapClass = as3.tolua(VALUE_TileMapClass)
GamePackage = as3.tolua(VALUE_GamePackage)
csvDir = as3.tolua(VALUE_CSVDir)
importsText = as3.tolua(VALUE_Imports)

-- This is the file for the map base class
baseFileText = "";
fileText = "";

pathLayers = {}

containsBoxData = false
containsCircleData = false
containsTextData = false
containsPaths = false

------------------------
-- TILEMAP GENERATION
------------------------
function exportMapCSV( mapLayer, layerFileName )
	-- get the raw mapdata. To change format, modify the strings passed in (rowPrefix,rowSuffix,columnPrefix,columnSeparator,columnSuffix)
	mapText = as3.tolua(DAME.ConvertMapToText(mapLayer,"","\n","",",",""))
	DAME.WriteFile(csvDir.."/"..layerFileName, mapText );
end

------------------------
-- PATH GENERATION
------------------------

-- This will store the path along with a name so when we call a get it will output the value between the first : and the last %
-- Here it will be paths[i]. When we later call %getparent% on any attached avatar it will output paths[i].
pathText = "%store:paths[%counter:paths%]%"
pathText = pathText.."%counter++:paths%" -- This line will actually incremement the counter.

lineNodeText = "new Point(%nodex%, %nodey%)"
splineNodeText = "{ pos:new Point(%nodex%, %nodey%), tan1:new Point(%tan1x%, %tan1y%), tan2:new Point(-(%tan2x%), -(%tan2y%)) }"

propertiesString = "generateProperties( %%proploop%%"
	propertiesString = propertiesString.."{ name:\"%propname%\", value:%propvaluestring% }, "
propertiesString = propertiesString.."%%proploopend%%null )"

local groupPropTypes = as3.toobject({ String="String", Int="int", Float="Number", Boolean="Boolean" })

linkAssignText = "%%if link%%"
	linkAssignText = linkAssignText.."linkedObjectDictionary[%linkid%] = "
linkAssignText = linkAssignText.."%%endiflink%%"
needCallbackText = "%%if link%%, true %%endiflink%%"


function generatePaths( )
	for i,v in ipairs(pathLayers) do	
		containsPaths = true
		fileText = fileText..tab2.."public function addPathsForLayer"..pathLayers[i][3].."(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var pathobj:PathData;\n\n"
		
		linesText = pathText..tab3.."pathobj = new PathData( [ %nodelist% \n"..tab3.."], %isclosed%, false, "..pathLayers[i][3].."Group );\n"
		linesText = linesText..tab3.."paths.push(pathobj);\n"

		linesText = linesText..tab3..linkAssignText.."callbackNewData( pathobj, onAddCallback, "..pathLayers[i][3].."Group, "..propertiesString..needCallbackText.." );\n\n"
		
		fileText = fileText..as3.tolua(DAME.CreateTextForPaths(pathLayers[i][2], linesText, lineNodeText, linesText, splineNodeText, ",\n"..tab4))
		fileText = fileText..tab2.."}\n\n"
	end
end

-------------------------------------
-- SHAPE and TEXTBOX GENERATION
-------------------------------------

function generateShapes( )
	for i,v in ipairs(shapeLayers) do	
		groupname = shapeLayers[i][3].."Group"

		
		textboxText = tab3..linkAssignText.."callbackNewData(new TextData(%xpos%, %ypos%, %width%, %height%, %degrees%, \"%text%\",\"%font%\", %size%, 0x%color%, \"%align%\"), onAddCallback, "..groupname..", "..propertiesString..needCallbackText.." ) ;\n"
		
		fileText = fileText..tab2.."public function addShapesForLayer"..shapeLayers[i][3].."(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var obj:Object;\n\n"
		
		boxText = tab3.."obj = new BoxData(%xpos%, %ypos%, %degrees%, %width%, %height%, "..groupname.." );\n"
		boxText = boxText..tab3.."shapes.push(obj);\n"
		boxText = boxText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..needCallbackText.." );\n"

		circleText = tab3.."obj = new CircleData(%xpos%, %ypos%, %radius%, "..groupname.." );\n"
		circleText = circleText..tab3.."shapes.push(obj);\n"
		circleText = circleText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..needCallbackText..");\n"

		shapeText = as3.tolua(DAME.CreateTextForShapes(shapeLayers[i][2], circleText, boxText, textboxText ))
		fileText = fileText..shapeText
		fileText = fileText..tab2.."}\n\n"
		
		if string.find(shapeText, "BoxData") ~= nil then
			containsBoxData = true
		end
		if string.find(shapeText, "CircleData") ~= nil then
			containsCircleData = true
		end
		if containsTextData == false and string.find(shapeText, "TextData") ~= nil then
			containsTextData = true
		end
	end
end

------------------------
-- BASE CLASS
------------------------
if exportOnlyCSV == false then	
	baseFileText = "//Code generated with DAME. http://www.dambots.com\n\n"
	baseFileText = baseFileText.."package "..GamePackage.."\n"
	baseFileText = baseFileText.."{\n"
	baseFileText = baseFileText..tab1.."import "..flashpunkPackage..".graphics.Image;\n"
	baseFileText = baseFileText..tab1.."import "..flashpunkPackage..".FP;\n"
	baseFileText = baseFileText..tab1.."import flash.utils.Dictionary;\n"
	if # importsText > 0 then
		baseFileText = baseFileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	baseFileText = baseFileText..tab1.."public class "..baseClassName.."\n"
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."// The masterLayer contains every single object in this group making it easy to empty the level.\n"
	baseFileText = baseFileText..tab2.."public var masterLayer:Vector.<LayerGroup> = new Vector.<LayerGroup>;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMinX:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMinY:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMaxX:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMaxY:int;\n\n"
	baseFileText = baseFileText..tab2.."public var bgColor:uint = 0;\n"
	baseFileText = baseFileText..tab2.."public var paths:Array = [];\t// Array of PathData\n"
	baseFileText = baseFileText..tab2.."public var shapes:Array = [];\t//Array of ShapeData.\n"
	baseFileText = baseFileText..tab2.."public static var linkedObjectDictionary:Dictionary = new Dictionary;\n\n"
	baseFileText = baseFileText..tab2.."public function "..baseClassName.."() { }\n\n"
	baseFileText = baseFileText..tab2.."// Expects callback function to be callback(newobj:Object,layer:LayerGroup,level:BaseLevel,properties:Array)\n"
	baseFileText = baseFileText..tab2.."public function createObjects(onAddCallback:Function = null):void { }\n\n"
	
	baseFileText = baseFileText..tab2.."public function addTilemap( mapClass:Class, imageClass:Class, x:Number, y:Number, tileWidth:uint, tileHeight:uint, scrollX:Number, scrollY:Number, hits:Boolean, collideIdx:uint, drawIdx:uint, properties:Array, onAddCallback:Function = null ):"..tileMapClass.."\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var map:"..tileMapClass.." = new "..tileMapClass.."( mapClass, imageClass, x, y, tileWidth, tileHeight, hits, collideIdx );\n"
	baseFileText = baseFileText..tab3.."map.map.scrollX = scrollX;\n"
	baseFileText = baseFileText..tab3.."map.map.scrollY = scrollY;\n"
	baseFileText = baseFileText..tab3.."FP.world.add(map);\n"
	baseFileText = baseFileText..tab3.."if(onAddCallback != null)\n"
	baseFileText = baseFileText..tab4.."onAddCallback(map, null, this, properties);\n"
	baseFileText = baseFileText..tab3.."return map;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."public function addSpriteToLayer(obj:SpriteEntity, type:Class, layer:LayerGroup, x:Number, y:Number, angle:Number, flipped:Boolean = false, scaleX:Number = 1, scaleY:Number = 1, properties:Array = null, onAddCallback:Function = null):SpriteEntity\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."if( obj == null )\n"
	baseFileText = baseFileText..tab4.."obj = new type(x, y);\n"
	baseFileText = baseFileText..tab4.."FP.world.add(obj);\n"
	baseFileText = baseFileText..tab3.."obj.x += obj.originX;\n"
	baseFileText = baseFileText..tab3.."obj.y += obj.originY;\n"
	baseFileText = baseFileText..tab3.."var sprite:Image = obj.sprite;\n"
	baseFileText = baseFileText..tab3.."if ( sprite )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."sprite.angle = -angle;\n"
	baseFileText = baseFileText..tab4.."// Only override the flipped value if the class didn't change it from the default.\n"
	baseFileText = baseFileText..tab4.."if( !sprite.flipped )\n"
	baseFileText = baseFileText..tab5.."sprite.flipped = flipped;\n"
	baseFileText = baseFileText..tab4.."sprite.scaleX = scaleX;\n"
	baseFileText = baseFileText..tab4.."sprite.scaleY = scaleY;\n"
	baseFileText = baseFileText..tab3.."}\n\n"
	baseFileText = baseFileText..tab3.."if ( scaleX != 1 || scaleY != 1 )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."// Adjust the offset, in case it was already set.\n"
	baseFileText = baseFileText..tab4.."var newFrameWidth:Number = obj.width * scaleX;\n"
	baseFileText = baseFileText..tab4.."var newFrameHeight:Number = obj.height * scaleY;\n"
	baseFileText = baseFileText..tab4.."obj.originX -= (newFrameWidth- obj.width) / 2;\n"
	baseFileText = baseFileText..tab4.."obj.originY -= (newFrameHeight - obj.height) / 2;\n"
	baseFileText = baseFileText..tab4.."obj.setHitbox(newFrameWidth, newFrameHeight);\n"
	baseFileText = baseFileText..tab3.."}\n\n"
	baseFileText = baseFileText..tab3.."layer.AddSprite(obj);\n"
	baseFileText = baseFileText..tab3.."callbackNewData(obj, onAddCallback, layer, properties, false);\n"
	baseFileText = baseFileText..tab3.."return obj;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."public function addTextToLayer(textdata:TextData, layer:LayerGroup, embed:Boolean, properties:Array, onAddCallback:Function ):SpriteEntity\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var textobj:TextAdvanced = new TextAdvanced(textdata.text, textdata.fontName, textdata.size, textdata.alignment, 0, 0, textdata.width, textdata.height );\n"
	baseFileText = baseFileText..tab3.."textobj.color = textdata.color;\n"
	baseFileText = baseFileText..tab3.."var textEntity:SpriteEntity = new SpriteEntity(textdata.x, textdata.y);\n"
	baseFileText = baseFileText..tab3.."textEntity.text = textobj;\n"
	baseFileText = baseFileText..tab3.."addSpriteToLayer(textEntity, SpriteEntity, layer , 0, 0, textdata.angle, false, 1, 1, properties, onAddCallback );\n"
	baseFileText = baseFileText..tab3.."return textEntity;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."protected function callbackNewData(data:Object, onAddCallback:Function, layer:LayerGroup, properties:Array, needsReturnData:Boolean = false):Object\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."if(onAddCallback != null)\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."var newData:Object = onAddCallback(data, layer, this, properties);\n"
	baseFileText = baseFileText..tab4.."if( newData != null )\n"
	baseFileText = baseFileText..tab5.."data = newData;\n"
	baseFileText = baseFileText..tab4.."else if ( needsReturnData )\n"
	baseFileText = baseFileText..tab5.."trace(\"Error: callback needs to return either the object passed in or a new object to set up links correctly.\");\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."return data;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."protected function generateProperties( ... arguments ):Array\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var properties:Array = [];\n"
	baseFileText = baseFileText..tab3.."if ( arguments.length )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."for( var i:uint = 0; i < arguments.length - 1; i++ )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."properties.push( arguments[i] );\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."return properties;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."public function createLink( objectFrom:Object, target:Object, onAddCallback:Function, properties:Array ):void\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var link:ObjectLink = new ObjectLink( objectFrom, target );\n"
	baseFileText = baseFileText..tab3.."callbackNewData(link, onAddCallback, null, properties);\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab1.."}\n"	-- end class
	baseFileText = baseFileText.."}\n"		-- end package
	DAME.WriteFile(as3Dir.."/"..baseClassName..".as", baseFileText )
end

------------------------
-- GROUP CLASSES
------------------------
for groupIndex = 0,groupCount do

	maps = {}
	spriteLayers = {}
	shapeLayers = {}
	pathLayers = {}
	masterLayerAddText = ""
	stageAddText = ""
	
	DAME.ResetCounters()
	
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
	
	
	layerCount = as3.tolua(group.children.length) - 1
	
	-- This is the file for the map group class.
	fileText = "//Code generated with DAME. http://www.dambots.com\n\n"
	fileText = fileText.."package "..GamePackage.."\n"
	fileText = fileText.."{\n"
	fileText = fileText..tab1.."import flash.geom.Point;\n"
	fileText = fileText..tab1.."import "..flashpunkPackage..".Entity;\n"
	fileText = fileText..tab1.."import "..flashpunkPackage..".FP;\n"
	if # importsText > 0 then
		fileText = fileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	fileText = fileText..tab1.."public class Level_"..groupName.." extends "..baseClassName.."\n"
	fileText = fileText..tab1.."{\n"
	fileText = fileText..tab2.."//Embedded media...\n"
	
	-- Go through each layer and store some tables for the different layer types.
	for layerIndex = 0,layerCount do
		layer = group.children[layerIndex]
		isMap = as3.tolua(layer.map)~=nil
		layerName = as3.tolua(layer.name)
		layerName = string.gsub(layerName, " ", "_")
		if isMap == true then
			mapFileName = "mapCSV_"..groupName.."_"..layerName..".csv"
			-- Generate the map file.
			exportMapCSV( layer, mapFileName )
			
			-- This needs to be done here so it maintains the layer visibility ordering.
			if exportOnlyCSV == false then
				table.insert(maps,{layer,layerName})
				-- For maps just generate the Embeds needed at the top of the class.
				fileText = fileText..tab2.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(as3Dir, csvDir.."/"..mapFileName)).."\", mimeType=\"application/octet-stream\")] public var CSV_"..layerName..":Class;\n"
				fileText = fileText..tab2.."[Embed(source=\""..as3.tolua(DAME.GetRelativePath(as3Dir, layer.imageFile)).."\")] public var Img_"..layerName..":Class;\n"
			end

		elseif exportOnlyCSV == false then
			if as3.tolua(layer.IsSpriteLayer()) == true then
				table.insert( spriteLayers,{groupName,layer,layerName})
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.push("..layerName.."Group);\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollX = "..string.format("%.6f",as3.tolua(layer.xScroll))..";\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollY = "..string.format("%.6f",as3.tolua(layer.yScroll))..";\n"
				stageAddText = stageAddText..tab3.."addSpritesForLayer"..layerName.."(onAddCallback);\n"
				
			elseif as3.tolua(layer.IsShapeLayer()) == true then
				table.insert(shapeLayers,{groupName,layer,layerName})
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.push("..layerName.."Group);\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollX = "..string.format("%.6f",as3.tolua(layer.xScroll))..";\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollY = "..string.format("%.6f",as3.tolua(layer.yScroll))..";\n"
				
			elseif as3.tolua(layer.IsPathLayer()) == true then
				table.insert(pathLayers,{groupName,layer,layerName})
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.push("..layerName.."Group);\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollX = "..string.format("%.6f",as3.tolua(layer.xScroll))..";\n"
				masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollY = "..string.format("%.6f",as3.tolua(layer.yScroll))..";\n"
			end
		end
	end

	-- Generate the actual text for the derived class file.
	
	if exportOnlyCSV == false then

		------------------------------------
		-- VARIABLE DECLARATIONS
		-------------------------------------
		fileText = fileText.."\n"
		
		if # maps > 0 then
			fileText = fileText..tab2.."//Tilemaps\n"
			for i,v in ipairs(maps) do
				fileText = fileText..tab2.."public var layer"..maps[i][2]..":"..tileMapClass..";\n"
			end
			fileText = fileText.."\n"
		end
		
		if # spriteLayers > 0 then
			fileText = fileText..tab2.."//Sprites\n"
			for i,v in ipairs(spriteLayers) do
				fileText = fileText..tab2.."public var "..spriteLayers[i][3].."Group:LayerGroup = new LayerGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # shapeLayers > 0 then
			fileText = fileText..tab2.."//Shapes\n"
			for i,v in ipairs(shapeLayers) do
				fileText = fileText..tab2.."public var "..shapeLayers[i][3].."Group:LayerGroup = new LayerGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # pathLayers > 0 then
			fileText = fileText..tab2.."//Paths\n"
			for i,v in ipairs(pathLayers) do
				fileText = fileText..tab2.."public var "..pathLayers[i][3].."Group:LayerGroup = new LayerGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		groupPropertiesString = "%%proploop%%"..tab2.."public var %propnamefriendly%:%proptype% = %propvaluestring%;\n%%proploopend%%"
		
		fileText = fileText..tab2.."//Properties\n"
		fileText = fileText..as3.tolua(DAME.GetTextForProperties( groupPropertiesString, group.properties, groupPropTypes )).."\n"
		
		fileText = fileText.."\n"
		fileText = fileText..tab2.."public function Level_"..groupName.."(addToStage:Boolean = true, onAddCallback:Function = null)\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."// Generate maps.\n"
		
		fileText = fileText..tab3.."var properties:Array = [];\n\n"
		
		minx = 9999999
		miny = 9999999
		maxx = -9999999
		maxy = -9999999
		-- Create the tilemaps.
		for i,v in ipairs(maps) do
			layerName = maps[i][2]
			layer = maps[i][1]
			
			x = as3.tolua(layer.map.x)
			y = as3.tolua(layer.map.y)
			width = as3.tolua(layer.map.width)
			height = as3.tolua(layer.map.height)
			xscroll = as3.tolua(layer.xScroll)
			yscroll = as3.tolua(layer.yScroll)
			hasHitsString = ""
			if as3.tolua(layer.HasHits) == true then
				hasHitsString = "true"
			else
				hasHitsString = "false"
			end
			
			fileText = fileText..tab3.."properties = "..as3.tolua(DAME.GetTextForProperties( propertiesString, layer.properties ))..";\n"
			fileText = fileText..tab3.."layer"..layerName.." = addTilemap( CSV_"..layerName..", Img_"..layerName..", "..string.format("%.3f",x)..", "..string.format("%.3f",y)..", "..as3.tolua(layer.map.tileWidth)..", "..as3.tolua(layer.map.tileHeight)..", "..string.format("%.3f",xscroll)..", "..string.format("%.3f",yscroll)..", "..hasHitsString..", "..as3.tolua(layer.map.collideIndex)..", "..as3.tolua(layer.map.drawIndex)..", properties, onAddCallback );\n"

			-- Only set the bounds based on maps whose scroll factor is the same as the player's.
			if xscroll == 1 and yscroll == 1 then
				if x < minx then minx = x end
				if y < miny then miny = y end
				if x + width > maxx then maxx = x + width end
				if y + height > maxy then maxy = y + height end
			end
			
		end
		
		------------------
		-- MASTER GROUP.
		------------------
		
		fileText = fileText.."\n"..tab3.."//Add layers to the master group in correct order.\n"
		fileText = fileText..masterLayerAddText.."\n";
		
		fileText = fileText..tab3.."if ( addToStage )\n"
		fileText = fileText..tab4.."createObjects(onAddCallback);\n\n"
		
		fileText = fileText..tab3.."boundsMinX = "..minx..";\n"
		fileText = fileText..tab3.."boundsMinY = "..miny..";\n"
		fileText = fileText..tab3.."boundsMaxX = "..maxx..";\n"
		fileText = fileText..tab3.."boundsMaxY = "..maxy..";\n"
		fileText = fileText..tab3.."bgColor = "..as3.tolua(DAME.GetBackgroundColor())..";\n"
		
		fileText = fileText..tab2.."}\n\n"	-- end constructor
		
		---------------
		-- OBJECTS
		---------------
		-- One function for each layer.
		
		fileText = fileText..tab2.."override public function createObjects(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		-- Must add the paths before the sprites as the sprites index into the paths array.
		for i,v in ipairs(pathLayers) do
			fileText = fileText..tab3.."addPathsForLayer"..pathLayers[i][3].."(onAddCallback);\n"
		end
		for i,v in ipairs(shapeLayers) do
			fileText = fileText..tab3.."addShapesForLayer"..shapeLayers[i][3].."(onAddCallback);\n"
		end
		fileText = fileText..stageAddText
		fileText = fileText..tab3.."generateObjectLinks(onAddCallback);\n"
		fileText = fileText..tab2.."}\n\n"
		
		-- Create the paths first so that sprites can reference them if any are attached.
		
		generatePaths()
		generateShapes()
		
		-- create the sprites.
		
		for i,v in ipairs(spriteLayers) do
			
			creationText = tab3..linkAssignText
			creationText = creationText.."%%if parent%%"
				creationText = creationText.."%getparent%.childSprite = "
			creationText = creationText.."%%endifparent%%"
			creationText = creationText.."addSpriteToLayer(%constructor:null%, %class%, "..spriteLayers[i][3].."Group , %xpos%, %ypos%, %degrees%, %flipped%, %scalex%, %scaley%, "..propertiesString..", onAddCallback );//%name%\n" 
			creationText = creationText.."%%if parent%%"
				creationText = creationText..tab3.."%getparent%.childAttachNode = %attachedsegment%;\n"
				creationText = creationText..tab3.."%getparent%.childAttachT = %attachedsegment_t%;\n"
			creationText = creationText.."%%endifparent%%"
			
			fileText = fileText..tab2.."public function addSpritesForLayer"..spriteLayers[i][3].."(onAddCallback:Function = null):void\n"
			fileText = fileText..tab2.."{\n"
		
			fileText = fileText..as3.tolua(DAME.CreateTextForSprites(spriteLayers[i][2],creationText,"Avatar"))
			fileText = fileText..tab2.."}\n\n"
		end
		
		-- Create the links between objects.
		
		fileText = fileText..tab2.."public function generateObjectLinks(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		linkText = tab3.."createLink(linkedObjectDictionary[%linkfromid%], linkedObjectDictionary[%linktoid%], onAddCallback, "..propertiesString.." );\n"
		fileText = fileText..as3.tolua(DAME.GetTextForLinks(linkText, group))
		fileText = fileText..tab2.."}\n"
		
		fileText = fileText.."\n"
		fileText = fileText..tab1.."}\n"	-- end class
		fileText = fileText.."}\n"		-- end package
		
		
			
		-- Save the file!
		
		DAME.WriteFile(as3Dir.."/Level_"..groupName..".as", fileText )
		
	end
end

-- Create any extra required classes.
-- must be done last after the parser has gone through.

if exportOnlyCSV == false then

	--if containsTextData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."public class TextData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var x:Number;\n"
		textfile = textfile..tab2.."public var y:Number;\n"
		textfile = textfile..tab2.."public var width:uint;\n"
		textfile = textfile..tab2.."public var height:uint;\n"
		textfile = textfile..tab2.."public var angle:Number;\n"
		textfile = textfile..tab2.."public var text:String;\n"
		textfile = textfile..tab2.."public var fontName:String;\n"
		textfile = textfile..tab2.."public var size:uint;\n"
		textfile = textfile..tab2.."public var color:uint;\n"
		textfile = textfile..tab2.."public var alignment:String;\n\n"
		textfile = textfile..tab2.."public function TextData( X:Number, Y:Number, Width:uint, Height:uint, Angle:Number, Text:String, FontName:String, Size:uint, Color:uint, Alignment:String )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."x = X;\n"
		textfile = textfile..tab3.."y = Y;\n"
		textfile = textfile..tab3.."width = Width;\n"
		textfile = textfile..tab3.."height = Height;\n"
		textfile = textfile..tab3.."angle = Angle;\n"
		textfile = textfile..tab3.."text = Text;\n"
		textfile = textfile..tab3.."fontName = FontName;\n"
		textfile = textfile..tab3.."size = Size;\n"
		textfile = textfile..tab3.."color = Color;\n"
		textfile = textfile..tab3.."alignment = Alignment;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/TextData.as", textfile )
	--end
	
	if containsPaths == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."public class PathData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var nodes:Array;\n"
		textfile = textfile..tab2.."public var isClosed:Boolean;\n"
		textfile = textfile..tab2.."public var isSpline:Boolean;\n"
		textfile = textfile..tab2.."public var layer:LayerGroup;\n\n"
		textfile = textfile..tab2.."// These values are only set if there is an attachment.\n"
		textfile = textfile..tab2.."public var childSprite:SpriteEntity = null;\n"
		textfile = textfile..tab2.."public var childAttachNode:int = 0;\n"
		textfile = textfile..tab2.."public var childAttachT:Number = 0;\t// position of child between attachNode and next node.(0-1)\n\n"
		textfile = textfile..tab2.."public function PathData( Nodes:Array, Closed:Boolean, Spline:Boolean, Layer:LayerGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."nodes = Nodes;\n"
		textfile = textfile..tab3.."isClosed = Closed;\n"
		textfile = textfile..tab3.."isSpline = Spline;\n"
		textfile = textfile..tab3.."layer = Layer;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/PathData.as", textfile )
		
	end
	
	if containsBoxData == true or containsCircleData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."public class ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var x:Number;\n"
		textfile = textfile..tab2.."public var y:Number;\n"
		textfile = textfile..tab2.."public var group:LayerGroup;\n\n"
		textfile = textfile..tab2.."public function ShapeData(X:Number, Y:Number, Group:LayerGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."x = X;\n"
		textfile = textfile..tab3.."y = Y;\n"
		textfile = textfile..tab3.."group = Group;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/ShapeData.as", textfile )
	end
	
	if containsBoxData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."public class BoxData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var angle:Number;\n"
		textfile = textfile..tab2.."public var width:uint;\n"
		textfile = textfile..tab2.."public var height:uint;\n\n"
		textfile = textfile..tab2.."public function BoxData( X:Number, Y:Number, Angle:Number, Width:uint, Height:uint, Group:LayerGroup ) \n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."super(X, Y, Group);\n"
		textfile = textfile..tab3.."angle = Angle;\n"
		textfile = textfile..tab3.."width = Width;\n"
		textfile = textfile..tab3.."height = Height;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/BoxData.as", textfile )
	end
	
	if containsCircleData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."public class CircleData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var radius:Number;\n\n"
		textfile = textfile..tab2.."public function CircleData( X:Number, Y:Number, Radius:Number, Group:LayerGroup ) \n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."super(X, Y, Group);\n"
		textfile = textfile..tab3.."radius = Radius;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/CircleData.as", textfile )
	end
	
-----------------------------
-- Export tilemapEntity class.
-----------------------------

textfile = "package "..GamePackage.."\n"
textfile = textfile.."{\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".Entity;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".graphics.Tilemap;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".masks.Grid;\n"
textfile = textfile..tab1.."public class TileMapEntity extends Entity\n"
textfile = textfile..tab1.."{\n"
textfile = textfile..tab2.."public var map:Tilemap;\n"
textfile = textfile..tab2.."public var myGrid:Grid;\n"
textfile = textfile..tab2.."public var widthInTiles:uint;\n"
textfile = textfile..tab2.."public var heightInTiles:uint;\n\n"
textfile = textfile..tab2.."public function TileMapEntity( tilemapDataClass:Class, tilesetClass:Class, X:Number, Y:Number, tileWidth:uint, tileHeight:uint, hits:Boolean, collideIdx:uint = 1)\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."x = X;\n"
textfile = textfile..tab3.."y = Y;\n"
textfile = textfile..tab3.."var tilemapData:String = new tilemapDataClass;\n"
textfile = textfile..tab3.."getSizeFromString(tilemapData);\n"
textfile = textfile..tab3.."map = new Tilemap(tilesetClass, widthInTiles * tileWidth, heightInTiles * tileHeight, tileWidth, tileHeight);\n"
textfile = textfile..tab3.."map.loadFromString( tilemapData );\n"
textfile = textfile..tab3.."graphic = map;\n"
textfile = textfile..tab3.."if ( hits )\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."type = \"solid\";\n"
textfile = textfile..tab4.."myGrid = new Grid(map.width, map.height, tileWidth, tileHeight, 0, 0);\n"
textfile = textfile..tab4.."var wid:uint = map.width / map.tileWidth;\n"
textfile = textfile..tab4.."var ht:uint = map.height / map.tileHeight;\n"
textfile = textfile..tab4.."for ( var y:uint = 0; y < ht;  y++ )\n"
textfile = textfile..tab4.."{\n"
textfile = textfile..tab5.."for ( var x: uint = 0; x < wid; x++ )\n"
textfile = textfile..tab5.."{\n"
textfile = textfile..tab6.."if ( map.getTile(x, y) >= collideIdx )\n"
textfile = textfile..tab6.."{\n"
textfile = textfile..tab7.."myGrid.setTile(x, y, true);\n"
textfile = textfile..tab6.."}\n"
textfile = textfile..tab5.."}\n"
textfile = textfile..tab4.."}\n"
textfile = textfile..tab4.."mask  = myGrid;\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."private function getSizeFromString(str:String, columnSep:String = \",\", rowSep:String = \"\\n\"):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."var row:Array = str.split(rowSep);\n"
textfile = textfile..tab3.."heightInTiles = row.length;\n"
textfile = textfile..tab3.."for (var y:uint = 0; y < heightInTiles; y ++)\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."if (row[y] == '')\n"
textfile = textfile..tab5.."continue;\n"
textfile = textfile..tab4.."var col:Array = row[y].split(columnSep);\n"
textfile = textfile..tab4.."widthInTiles = Math.max(widthInTiles, col.length + 1);\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab2.."}\n"
textfile = textfile..tab1.."}\n"
textfile = textfile.."}\n"

DAME.WriteFile(as3Dir.."/TileMapEntity.as", textfile )


textfile = "package "..GamePackage.."\n"
textfile = textfile.."{\n"
textfile = textfile..tab1.."public class LayerGroup\n"
textfile = textfile..tab1.."{\n"
textfile = textfile..tab2.."public var sprites:Vector.<SpriteEntity> = new Vector.<SpriteEntity>;\n"
textfile = textfile..tab2.."public var scrollX:Number;\n"
textfile = textfile..tab2.."public var scrollY:Number;\n"
textfile = textfile..tab2.."public function LayerGroup( scrollx:Number = 1, scrolly:Number = 1 )\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."scrollX = scrollx;\n"
textfile = textfile..tab3.."scrollY = scrolly;\n"
textfile = textfile..tab2.."}\n"
textfile = textfile..tab2.."public function AddSprite( sprite:SpriteEntity, shareScroll:Boolean = true ):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."sprites.push(sprite);\n"
textfile = textfile..tab3.."if ( shareScroll && sprite.sprite)\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."sprite.sprite.scrollX = scrollX;\n"
textfile = textfile..tab4.."sprite.sprite.scrollY = scrollY;\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab2.."}\n"
textfile = textfile..tab1.."}\n"
textfile = textfile.."}\n"

DAME.WriteFile(as3Dir.."/LayerGroup.as", textfile )

-----------------------------
-- Export sprite entity class.
-----------------------------

textfile = "package "..GamePackage.."\n"
textfile = textfile.."{\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".Entity;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".graphics.Image;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".graphics.Spritemap;\n"
textfile = textfile..tab1.."public class SpriteEntity extends Entity\n"
textfile = textfile..tab1.."{\n"
textfile = textfile..tab2.."public var anim:Spritemap = null;\n"
textfile = textfile..tab2.."public var sprite:Image = null;\n"
textfile = textfile..tab2.."private var _text:TextAdvanced = null;\n\n"
textfile = textfile..tab2.."public function set text( newText:TextAdvanced):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."graphic = sprite = _text = newText;\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."public function get text():TextAdvanced\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."return _text;\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."public function SpriteEntity( X:Number, Y:Number )\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."x = X;\n"
textfile = textfile..tab3.."y = Y;\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."public function loadImage( imageClass:Class, Width:uint, Height:uint, animates:Boolean = true ):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."if ( animates )\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."sprite = anim = new Spritemap( imageClass, Width, Height);\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab3.."else\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."sprite = new Image( imageClass );\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab3.."graphic = sprite;\n"
textfile = textfile..tab2.."}\n"
textfile = textfile..tab1.."}\n"
textfile = textfile.."}\n"

DAME.WriteFile(as3Dir.."/SpriteEntity.as", textfile )

-----------------------------
-- Embed text
-----------------------------
textfile = "package "..GamePackage.."\n"
textfile = textfile.."{\n"
textfile = textfile..tab1.."import flash.display.BitmapData;\n"
textfile = textfile..tab1.."import flash.geom.Point;\n"
textfile = textfile..tab1.."import flash.geom.Rectangle;\n"
textfile = textfile..tab1.."import flash.text.TextField;\n"
textfile = textfile..tab1.."import flash.text.TextFormat;\n"
textfile = textfile..tab1.."import flash.text.TextLineMetrics;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".FP;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".Graphic;\n"
textfile = textfile..tab1.."import "..flashpunkPackage..".graphics.Image;\n"
textfile = textfile..tab1.."// This is a variation on flashpunk's Text class, allowing multiline and alignment.\n"
textfile = textfile..tab1.."public class TextAdvanced extends Image\n"
textfile = textfile..tab1.."{\n"
textfile = textfile..tab2.."// To use \"default\" the TTF needs to be included in the com directory. See bottom of file.\n"
textfile = textfile..tab2.."public function TextAdvanced(text:String, fontName:String = \"default\", sz:uint = 16, align:String = \"left\", x:Number = 0, y:Number = 0, width:uint = 0, height:uint = 0 )\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."_font = fontName;\n"
textfile = textfile..tab3.."_field.embedFonts = true;\n"
textfile = textfile..tab3.."_field.defaultTextFormat = _form = new TextFormat(fontName, sz, 0xFFFFFF);\n"
textfile = textfile..tab3.."_field.text = _text = text;\n"
textfile = textfile..tab3.."_form.align = align;\n"
textfile = textfile..tab3.."if (!width)\n"
textfile = textfile..tab4.."width = _field.textWidth + 4;\n"
textfile = textfile..tab3.."else\n"
textfile = textfile..tab4.."_width = width;\n"
textfile = textfile..tab3.."if (!height)\n"
textfile = textfile..tab4.."height = _field.textHeight + 4;\n"
textfile = textfile..tab3.."else\n"
textfile = textfile..tab4.."_field.height = _height = height;\n"
textfile = textfile..tab3.."if ( width < _field.textWidth )\n"
textfile = textfile..tab3.."{\n"
textfile = textfile..tab4.."_field.width = width;\n"
textfile = textfile..tab4.."_field.multiline = true;\n"
textfile = textfile..tab4.."_field.wordWrap = true;\n"
textfile = textfile..tab3.."}\n"
textfile = textfile..tab3.."_source = new BitmapData(width, height, true, 0);\n"
textfile = textfile..tab3.."super(_source);\n"
textfile = textfile..tab3.."updateBuffer();\n"
textfile = textfile..tab3.."this.x = x;\n"
textfile = textfile..tab3.."this.y = y;\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."// Updates the drawing buffer.\n"
textfile = textfile..tab2.."override public function updateBuffer(clearBefore:Boolean = false):void \n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."_field.setTextFormat(_form);\n"
textfile = textfile..tab3.."_source.fillRect(_sourceRect, 0);\n"
textfile = textfile..tab3.."_source.draw(_field);\n"
textfile = textfile..tab3.."super.updateBuffer(clearBefore);\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."//Centers the Text's originX/Y to its center.\n"
textfile = textfile..tab2.."override public function centerOrigin():void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."originX = _width / 2;\n"
textfile = textfile..tab3.."originY = _height / 2;\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."//Text string.\n"
textfile = textfile..tab2.."public function get text():String { return _text; }\n"
textfile = textfile..tab2.."public function set text(value:String):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."if (_text == value) return;\n"
textfile = textfile..tab3.."_field.text = _text = value;\n"
textfile = textfile..tab3.."updateBuffer();\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."//Font family.\n"
textfile = textfile..tab2.."public function get font():String { return _font; }\n"
textfile = textfile..tab2.."public function set font(value:String):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."if (_font == value) return;\n"
textfile = textfile..tab3.."_form.font = _font = value;\n"
textfile = textfile..tab3.."updateBuffer();\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."//Font size.\n"
textfile = textfile..tab2.."public function get size():uint { return _size; }\n"
textfile = textfile..tab2.."public function set size(value:uint):void\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."if (_size == value) return;\n"
textfile = textfile..tab3.."_form.size = _size = value;\n"
textfile = textfile..tab3.."updateBuffer();\n"
textfile = textfile..tab2.."}\n\n"
textfile = textfile..tab2.."//Width of the text image.\n"
textfile = textfile..tab2.."override public function get width():uint { return _width; }\n"
textfile = textfile..tab2.."//Height of the text image.\n"
textfile = textfile..tab2.."override public function get height():uint { return _height; }\n"
textfile = textfile..tab2.."// Text information.\n\n"
textfile = textfile..tab2.."protected var _field:TextField = new TextField;\n"
textfile = textfile..tab2.."protected var _width:uint;\n"
textfile = textfile..tab2.."protected var _height:uint;\n"
textfile = textfile..tab2.."protected var _form:TextFormat;\n"
textfile = textfile..tab2.."protected var _text:String;\n"
textfile = textfile..tab2.."protected var _font:String;\n"
textfile = textfile..tab2.."protected var _size:uint;\n\n"
textfile = textfile..tab2.."// Default font family.\n"
textfile = textfile.."// UNCOMMENT one of these and include the default font in your directory if you need access to this.\n"
textfile = textfile..tab2.."// Use this option when compiling with Flex SDK 4\n"
textfile = textfile..tab2.."// [Embed(source = '04B_03__.TTF', embedAsCFF=\"false\", fontFamily = 'default')]\n"
textfile = textfile..tab2.."// Use this option when compiling with Flex SDK <4\n"
textfile = textfile..tab2.."//[Embed(source='04B_03__.TTF', fontFamily = 'default')]\n"
textfile = textfile..tab2.."//protected static var _FONT_DEFAULT:Class;\n"
textfile = textfile..tab1.."}\n"
textfile = textfile.."}\n"

DAME.WriteFile(as3Dir.."/TextAdvanced.as", textfile )

--------------------------------------
-- Object Links
----------------------------------------

textfile = "package "..GamePackage.."\n"
textfile = textfile.."{\n"
textfile = textfile..tab1.."public class ObjectLink\n"
textfile = textfile..tab1.."{\n"
textfile = textfile..tab2.."public var fromObject:Object;\n"
textfile = textfile..tab2.."public var toObject:Object;\n"
textfile = textfile..tab2.."public function ObjectLink(from:Object, to:Object)\n"
textfile = textfile..tab2.."{\n"
textfile = textfile..tab3.."fromObject = from;\n"
textfile = textfile..tab3.."toObject = to;\n"
textfile = textfile..tab2.."}\n"
textfile = textfile..tab1.."}\n"
textfile = textfile.."}\n"
DAME.WriteFile(as3Dir.."/ObjectLink.as", textfile )
	
end


return 1
