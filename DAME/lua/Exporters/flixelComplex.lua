

groups = DAME.GetGroups()
groupCount = as3.tolua(groups.length) -1

DAME.SetFloatPrecision(3)

tab1 = "\t"
tab2 = "\t\t"
tab3 = "\t\t\t"
tab4 = "\t\t\t\t"
tab5 = "\t\t\t\t\t"

-- slow to call as3.tolua many times so do as much as can in one go and store to a lua variable instead.
exportOnlyCSV = as3.tolua(VALUE_ExportOnlyCSV)
flixelPackage = as3.tolua(VALUE_FlixelPackage)
baseClassName = as3.tolua(VALUE_BaseClass)
baseExtends = as3.tolua(VALUE_BaseClassExtends)
IntermediateClass = as3.tolua(VALUE_IntermediateClass)
as3Dir = as3.tolua(VALUE_AS3Dir)
tileMapClass = as3.tolua(VALUE_TileMapClass)
GamePackage = as3.tolua(VALUE_GamePackage)
csvDir = as3.tolua(VALUE_CSVDir)
importsText = as3.tolua(VALUE_Imports)
-- Version can be "2.43" or "2.5"
flixelVersion = as3.tolua(VALUE_FlixelVersion)

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

lineNodeText = "new FlxPoint(%nodex%, %nodey%)"
splineNodeText = "{ pos:new FlxPoint(%nodex%, %nodey%), tan1:new FlxPoint(%tan1x%, %tan1y%), tan2:new FlxPoint(-(%tan2x%), -(%tan2y%)) }"

propertiesString = "generateProperties( %%proploop%%"
	propertiesString = propertiesString.."{ name:\"%propname%\", value:%propvaluestring% }, "
propertiesString = propertiesString.."%%proploopend%%null )"

tilePropertiesString = "%%ifproplength%%"..tab3.."tileProperties[%tileid%]="..propertiesString..";\n%%endifproplength%%"

local groupPropTypes = as3.toobject({ String="String", Int="int", Float="Number", Boolean="Boolean" })

DAME.SetCurrentPropTypes( groupPropTypes )

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

		layer = pathLayers[i][2]
		if flixelVersion == "2.5" then
			linesText = linesText..tab3..linkAssignText.."callbackNewData( pathobj, onAddCallback, "..pathLayers[i][3].."Group, "..propertiesString..", "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.xScroll)..needCallbackText.." );\n\n"
		else
			linesText = linesText..tab3..linkAssignText.."callbackNewData( pathobj, onAddCallback, "..pathLayers[i][3].."Group, "..propertiesString..needCallbackText.." );\n\n"
		end
		
		-- An example of how to parse path events. Add eventsText as an extra param to the end of CreateTextForPaths.
		--linesText = linesText.."%%if pathevents%%"..tab3.."events = new Array(%eventcount%)[%eventlist%]\n%%endifpathevents%%"
		--eventsText = "new PathEvent(x=%xpos%, y=%ypos%, percent=%percent%, seg=%segment%, "..propertiesString..")%separator:\n"..tab5.."%"
		
		fileText = fileText..as3.tolua(DAME.CreateTextForPaths(layer, linesText, lineNodeText, linesText, splineNodeText, ",\n"..tab4))
		fileText = fileText..tab2.."}\n\n"
	end
end

-------------------------------------
-- SHAPE and TEXTBOX GENERATION
-------------------------------------

function generateShapes( )
	for i,v in ipairs(shapeLayers) do	
		groupname = shapeLayers[i][3].."Group"

		if flixelVersion == "2.5" then
			scrollText = ", "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.yScroll)
		else
			scrollText = ""
		end
		
		textboxText = tab3..linkAssignText.."callbackNewData(new TextData(%xpos%, %ypos%, %width%, %height%, %degrees%, \"%text%\",\"%font%\", %size%, 0x%color%, \"%align%\"), onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText.." ) ;\n"
		
		fileText = fileText..tab2.."public function addShapesForLayer"..shapeLayers[i][3].."(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var obj:Object;\n\n"
		
		boxText = tab3.."obj = new BoxData(%xpos%, %ypos%, %degrees%, %width%, %height%, "..groupname.." );\n"
		boxText = boxText..tab3.."shapes.push(obj);\n"
		boxText = boxText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText.." );\n"

		circleText = tab3.."obj = new CircleData(%xpos%, %ypos%, %radius%, "..groupname.." );\n"
		circleText = circleText..tab3.."shapes.push(obj);\n"
		circleText = circleText..tab3..linkAssignText.."callbackNewData( obj, onAddCallback, "..groupname..", "..propertiesString..scrollText..needCallbackText..");\n"

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
	baseFileText = baseFileText..tab1.."import "..flixelPackage..".*;\n"
	baseFileText = baseFileText..tab1.."import flash.utils.Dictionary;\n"
	if # importsText > 0 then
		baseFileText = baseFileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	
	baseFileText = baseFileText..tab1.."public class "..baseClassName
	if # baseExtends > 0 then
		baseFileText = baseFileText.." extends "..baseExtends
	end
	baseFileText = baseFileText.."\n"
	
	baseFileText = baseFileText..tab1.."{\n"
	baseFileText = baseFileText..tab2.."// The masterLayer contains every single object in this group making it easy to empty the level.\n"
	baseFileText = baseFileText..tab2.."public var masterLayer:FlxGroup = new FlxGroup;\n\n"
	baseFileText = baseFileText..tab2.."// This group contains all the tilemaps specified to use collisions.\n"
	baseFileText = baseFileText..tab2.."public var hitTilemaps:FlxGroup = new FlxGroup;\n"
	baseFileText = baseFileText..tab2.."// This group contains all the tilemaps.\n"
	baseFileText = baseFileText..tab2.."public var tilemaps:FlxGroup = new FlxGroup;\n\n"
	baseFileText = baseFileText..tab2.."public static var boundsMinX:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMinY:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMaxX:int;\n"
	baseFileText = baseFileText..tab2.."public static var boundsMaxY:int;\n\n"
	baseFileText = baseFileText..tab2.."public var boundsMin:FlxPoint;\n"
	baseFileText = baseFileText..tab2.."public var boundsMax:FlxPoint;\n"
	baseFileText = baseFileText..tab2.."public var bgColor:uint = 0;\n"
	baseFileText = baseFileText..tab2.."public var paths:Array = [];\t// Array of PathData\n"
	baseFileText = baseFileText..tab2.."public var shapes:Array = [];\t//Array of ShapeData.\n"
	baseFileText = baseFileText..tab2.."public static var linkedObjectDictionary:Dictionary = new Dictionary;\n\n"
	baseFileText = baseFileText..tab2.."public function "..baseClassName.."() { }\n\n"
	baseFileText = baseFileText..tab2.."// Expects callback function to be callback(newobj:Object,layer:FlxGroup,level:BaseLevel,properties:Array)\n"
	baseFileText = baseFileText..tab2.."public function createObjects(onAddCallback:Function = null, parentObject:Object = null):void { }\n\n"
	
	baseFileText = baseFileText..tab2.."public function addTilemap( mapClass:Class, imageClass:Class, xpos:Number, ypos:Number, tileWidth:uint, tileHeight:uint, scrollX:Number, scrollY:Number, hits:Boolean, collideIdx:uint, drawIdx:uint, properties:Array, onAddCallback:Function = null ):"..tileMapClass.."\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var map:"..tileMapClass.." = new "..tileMapClass..";\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab3.."map.loadMap( new mapClass, imageClass, tileWidth, tileHeight, FlxTilemap.OFF, 0, drawIdx, collideIdx);\n"
	else
		baseFileText = baseFileText..tab3.."map.collideIndex = collideIdx;\n"
		baseFileText = baseFileText..tab3.."map.drawIndex = drawIdx;\n"
		baseFileText = baseFileText..tab3.."map.loadMap( new mapClass, imageClass, tileWidth, tileHeight );\n"
	end
	baseFileText = baseFileText..tab3.."map.x = xpos;\n"
	baseFileText = baseFileText..tab3.."map.y = ypos;\n"
	baseFileText = baseFileText..tab3.."map.scrollFactor.x = scrollX;\n"
	baseFileText = baseFileText..tab3.."map.scrollFactor.y = scrollY;\n"
	baseFileText = baseFileText..tab3.."if ( hits )\n"
	baseFileText = baseFileText..tab4.."hitTilemaps.add(map);\n"
	baseFileText = baseFileText..tab3.."tilemaps.add(map);\n"
	baseFileText = baseFileText..tab3.."if(onAddCallback != null)\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab4.."onAddCallback(map, null, this, scrollX, scrollY, properties);\n"
	else
		baseFileText = baseFileText..tab4.."onAddCallback(map, null, this, properties);\n"
	end
	baseFileText = baseFileText..tab3.."return map;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab2.."public function addSpriteToLayer(obj:FlxSprite, type:Class, layer:FlxGroup, xpos:Number, ypos:Number, angle:Number, scrollX:Number, scrollY:Number, flipped:Boolean = false, scaleX:Number = 1, scaleY:Number = 1, properties:Array = null, onAddCallback:Function = null):FlxSprite\n"
	else
		baseFileText = baseFileText..tab2.."public function addSpriteToLayer(obj:FlxSprite, type:Class, layer:FlxGroup, xpos:Number, ypos:Number, angle:Number, flipped:Boolean = false, scaleX:Number = 1, scaleY:Number = 1, properties:Array = null, onAddCallback:Function = null):FlxSprite\n"
	end
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."if( obj == null )\n"
	baseFileText = baseFileText..tab4.."obj = new type(xpos, ypos);\n"
	baseFileText = baseFileText..tab3.."obj.x += obj.offset.x;\n"
	baseFileText = baseFileText..tab3.."obj.y += obj.offset.y;\n"
	baseFileText = baseFileText..tab3.."obj.angle = angle;\n"
	baseFileText = baseFileText..tab3.."if ( scaleX != 1 || scaleY != 1 )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."obj.scale.x = scaleX;\n"
	baseFileText = baseFileText..tab4.."obj.scale.y = scaleY;\n"
	baseFileText = baseFileText..tab4.."obj.width *= scaleX;\n"
	baseFileText = baseFileText..tab4.."obj.height *= scaleY;\n"
	baseFileText = baseFileText..tab4.."// Adjust the offset, in case it was already set.\n"
	baseFileText = baseFileText..tab4.."var newFrameWidth:Number = obj.frameWidth * scaleX;\n"
	baseFileText = baseFileText..tab4.."var newFrameHeight:Number = obj.frameHeight * scaleY;\n"
	baseFileText = baseFileText..tab4.."var hullOffsetX:Number = obj.offset.x * scaleX;\n"
	baseFileText = baseFileText..tab4.."var hullOffsetY:Number = obj.offset.y * scaleY;\n"
	baseFileText = baseFileText..tab4.."obj.offset.x -= (newFrameWidth- obj.frameWidth) / 2;\n"
	baseFileText = baseFileText..tab4.."obj.offset.y -= (newFrameHeight - obj.frameHeight) / 2;\n"
	if flixelVersion ~= "2.5" then
		baseFileText = baseFileText..tab4.."// Refresh the collision hulls. If your object moves and you have an offset you should override refreshHulls so that hullOffset is always added.\n"
		baseFileText = baseFileText..tab4.."obj.colHullX.x = obj.colHullY.x = obj.x + hullOffsetX;\n"
		baseFileText = baseFileText..tab4.."obj.colHullX.y = obj.colHullY.y = obj.y + hullOffsetY;\n"
		baseFileText = baseFileText..tab4.."obj.colHullX.width = obj.colHullY.width = obj.width;\n"
		baseFileText = baseFileText..tab4.."obj.colHullX.height = obj.colHullY.height = obj.height;\n"
	end
	baseFileText = baseFileText..tab3.."}\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab3.."if( obj.facing == FlxObject.RIGHT )\n"
		baseFileText = baseFileText..tab4.."obj.facing = flipped ? FlxObject.LEFT : FlxObject.RIGHT;\n"
		baseFileText = baseFileText..tab3.."obj.scrollFactor.x = scrollX;\n"
		baseFileText = baseFileText..tab3.."obj.scrollFactor.y = scrollY;\n"
		baseFileText = baseFileText..tab3.."layer.add(obj);\n"
		baseFileText = baseFileText..tab3.."callbackNewData(obj, onAddCallback, layer, properties, scrollX, scrollY, false);\n"
	else
		baseFileText = baseFileText..tab3.."if( obj.facing == FlxSprite.RIGHT )\n"
		baseFileText = baseFileText..tab4.."obj.facing = flipped ? FlxSprite.LEFT : FlxSprite.RIGHT;\n"
		baseFileText = baseFileText..tab3.."layer.add(obj,true);\n"
		baseFileText = baseFileText..tab3.."callbackNewData(obj, onAddCallback, layer, properties, false);\n"
	end
	baseFileText = baseFileText..tab3.."return obj;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab2.."public function addTextToLayer(textdata:TextData, layer:FlxGroup, scrollX:Number, scrollY:Number, embed:Boolean, properties:Array, onAddCallback:Function ):FlxText\n"
	else
		baseFileText = baseFileText..tab2.."public function addTextToLayer(textdata:TextData, layer:FlxGroup, embed:Boolean, properties:Array, onAddCallback:Function ):FlxText\n"
	end
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var textobj:FlxText = new FlxText(textdata.x, textdata.y, textdata.width, textdata.text, embed);\n"
	baseFileText = baseFileText..tab3.."textobj.setFormat(textdata.fontName, textdata.size, textdata.color, textdata.alignment);\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab3.."addSpriteToLayer(textobj, FlxText, layer , 0, 0, textdata.angle, scrollX, scrollY, false, 1, 1, properties, onAddCallback );\n"
	else
		baseFileText = baseFileText..tab3.."addSpriteToLayer(textobj, FlxText, layer , 0, 0, textdata.angle, false, 1, 1, properties, onAddCallback );\n"
	end
	baseFileText = baseFileText..tab3.."textobj.height = textdata.height;\n"
	baseFileText = baseFileText..tab3.."textobj.origin.x = textobj.width * 0.5;\n"
	baseFileText = baseFileText..tab3.."textobj.origin.y = textobj.height * 0.5;\n"
	baseFileText = baseFileText..tab3.."return textobj;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab2.."protected function callbackNewData(data:Object, onAddCallback:Function, layer:FlxGroup, properties:Array, scrollX:Number, scrollY:Number, needsReturnData:Boolean = false):Object\n"
	else
		baseFileText = baseFileText..tab2.."protected function callbackNewData(data:Object, onAddCallback:Function, layer:FlxGroup, properties:Array, needsReturnData:Boolean = false):Object\n"
	end
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."if(onAddCallback != null)\n"
	baseFileText = baseFileText..tab3.."{\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab4.."var newData:Object = onAddCallback(data, layer, this, scrollX, scrollY, properties);\n"
	else
		baseFileText = baseFileText..tab4.."var newData:Object = onAddCallback(data, layer, this, properties);\n"
	end
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
	baseFileText = baseFileText..tab4.."for( var i:uint = 0; i < arguments.length-1; i++ )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."properties.push( arguments[i] );\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."return properties;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."public function createLink( objectFrom:Object, target:Object, onAddCallback:Function, properties:Array ):void\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."var link:ObjectLink = new ObjectLink( objectFrom, target );\n"
	if flixelVersion == "2.5" then
		baseFileText = baseFileText..tab3.."callbackNewData(link, onAddCallback, null, properties, objectFrom.scrollFactor.x, objectFrom.scrollFactor.y);\n"
	else
		baseFileText = baseFileText..tab3.."callbackNewData(link, onAddCallback, null, properties);\n"
	end
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2
	if baseExtends == "FlxGroup" then
		baseFileText = baseFileText.."override "
	end
	baseFileText = baseFileText.."public function destroy():void\n"
	baseFileText = baseFileText..tab2.."{\n"
	baseFileText = baseFileText..tab3.."masterLayer.destroy();\n"
	baseFileText = baseFileText..tab3.."masterLayer = null;\n"
	baseFileText = baseFileText..tab3.."tilemaps = null;\n"
	baseFileText = baseFileText..tab3.."hitTilemaps = null;\n\n"
			
	baseFileText = baseFileText..tab3.."var i:uint;\n"
	baseFileText = baseFileText..tab3.."for ( i = 0; i < paths.length; i++ )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."var pathobj:Object = paths[i];\n"
	baseFileText = baseFileText..tab4.."if ( pathobj )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."pathobj.destroy();\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."paths = null;\n\n"
			
	baseFileText = baseFileText..tab3.."for ( i = 0; i < shapes.length; i++ )\n"
	baseFileText = baseFileText..tab3.."{\n"
	baseFileText = baseFileText..tab4.."var shape:Object = shapes[i];\n"
	baseFileText = baseFileText..tab4.."if ( shape )\n"
	baseFileText = baseFileText..tab4.."{\n"
	baseFileText = baseFileText..tab5.."shape.destroy();\n"
	baseFileText = baseFileText..tab4.."}\n"
	baseFileText = baseFileText..tab3.."}\n"
	baseFileText = baseFileText..tab3.."shapes = null;\n"
	baseFileText = baseFileText..tab2.."}\n\n"
	
	baseFileText = baseFileText..tab2.."// List of null classes allows you to spawn levels dynamically from code using ClassReference.\n"
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
	
	group = groups[groupIndex]
	groupName = as3.tolua(group.name)
	groupName = string.gsub(groupName, " ", "_")
	
	DAME.ResetCounters()
	
	baseFileText = baseFileText..tab2.."private static var level_"..groupName..":Level_"..groupName..";\n"
	
	
	layerCount = as3.tolua(group.children.length) - 1
	
	-- This is the file for the map group class.
	fileText = "//Code generated with DAME. http://www.dambots.com\n\n"
	fileText = fileText.."package "..GamePackage.."\n"
	fileText = fileText.."{\n"
	fileText = fileText..tab1.."import "..flixelPackage..".*;\n"
	fileText = fileText..tab1.."import flash.utils.Dictionary;\n"
	if # importsText > 0 then
		fileText = fileText..tab1.."// Custom imports:\n"..importsText.."\n"
	end
	fileText = fileText..tab1.."public class Level_"..groupName.." extends "
	if # IntermediateClass > 0 then
		fileText = fileText..IntermediateClass.."\n"
	else
		fileText = fileText..baseClassName.."\n"
	end
	
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
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.add(layer"..layerName..");\n"
			end

		elseif exportOnlyCSV == false then
			addGroup = false;
			if as3.tolua(layer.IsSpriteLayer()) == true then
				table.insert( spriteLayers,{groupName,layer,layerName})
				addGroup = true;
				stageAddText = stageAddText..tab3.."addSpritesForLayer"..layerName.."(onAddCallback);\n"
			elseif as3.tolua(layer.IsShapeLayer()) == true then
				table.insert(shapeLayers,{groupName,layer,layerName})
				addGroup = true
			elseif as3.tolua(layer.IsPathLayer()) == true then
				table.insert(pathLayers,{groupName,layer,layerName})
				addGroup = true
			end
			
			if addGroup == true then
				masterLayerAddText = masterLayerAddText..tab3.."masterLayer.add("..layerName.."Group);\n"
				if flixelVersion ~= "2.5" then
					masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollFactor.x = "..string.format("%.4f",as3.tolua(layer.xScroll))..";\n"
					masterLayerAddText = masterLayerAddText..tab3..layerName.."Group.scrollFactor.y = "..string.format("%.4f",as3.tolua(layer.yScroll))..";\n"
				end
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
				fileText = fileText..tab2.."public var "..spriteLayers[i][3].."Group:FlxGroup = new FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # shapeLayers > 0 then
			fileText = fileText..tab2.."//Shapes\n"
			for i,v in ipairs(shapeLayers) do
				fileText = fileText..tab2.."public var "..shapeLayers[i][3].."Group:FlxGroup = new FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		if # pathLayers > 0 then
			fileText = fileText..tab2.."//Paths\n"
			for i,v in ipairs(pathLayers) do
				fileText = fileText..tab2.."public var "..pathLayers[i][3].."Group:FlxGroup = new FlxGroup;\n"
			end
			fileText = fileText.."\n"
		end
		
		groupPropertiesString = "%%proploop%%"..tab2.."public var %propnamefriendly%:%proptype% = %propvaluestring%;\n%%proploopend%%"
		
		fileText = fileText..tab2.."//Properties\n"
		fileText = fileText..as3.tolua(DAME.GetTextForProperties( groupPropertiesString, group.properties, groupPropTypes )).."\n"
		
		fileText = fileText.."\n"
		fileText = fileText..tab2.."public function Level_"..groupName.."(addToStage:Boolean = true, onAddCallback:Function = null, parentObject:Object = null)\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."// Generate maps.\n"
		
		fileText = fileText..tab3.."var properties:Array = [];\n"
		fileText = fileText..tab3.."var tileProperties:Dictionary = new Dictionary;\n\n"
		
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
			tileData = as3.tolua(DAME.CreateTileDataText( layer, tilePropertiesString, "", ""))
			if # tileData > 0 then
				fileText = fileText..tileData
				fileText = fileText..tab3.."properties.push( { name:\"%DAME_tiledata%\", value:tileProperties } );\n"
			end
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
		fileText = fileText..tab4.."createObjects(onAddCallback, parentObject);\n\n"
		
		fileText = fileText..tab3.."boundsMinX = "..minx..";\n"
		fileText = fileText..tab3.."boundsMinY = "..miny..";\n"
		fileText = fileText..tab3.."boundsMaxX = "..maxx..";\n"
		fileText = fileText..tab3.."boundsMaxY = "..maxy..";\n"
		
		fileText = fileText..tab3.."boundsMin = new FlxPoint("..minx..", "..miny..");\n"
		fileText = fileText..tab3.."boundsMax = new FlxPoint("..maxx..", "..maxy..");\n"
		
		fileText = fileText..tab3.."bgColor = "..as3.tolua(DAME.GetBackgroundColor())..";\n"
		
		fileText = fileText..tab2.."}\n\n"	-- end constructor
		
		---------------
		-- OBJECTS
		---------------
		-- One function for each layer.
		
		fileText = fileText..tab2.."override public function createObjects(onAddCallback:Function = null, parentObject:Object = null):void\n"
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
		fileText = fileText..tab3.."if ( parentObject != null )\n"
		fileText = fileText..tab4.."parentObject.add(masterLayer);\n"
		fileText = fileText..tab3.."else\n"
		fileText = fileText..tab4.."FlxG.state.add(masterLayer);\n"
		fileText = fileText..tab2.."}\n\n"
		
		-- Create the paths first so that sprites can reference them if any are attached.
		
		generatePaths()
		generateShapes()
		
		-- create the sprites.
		
		for i,v in ipairs(spriteLayers) do
			layer = spriteLayers[i][2]
			creationText = tab3..linkAssignText
			creationText = creationText.."%%if parent%%"
				creationText = creationText.."%getparent%.childSprite = "
			creationText = creationText.."%%endifparent%%"
			if flixelVersion == "2.5" then
				creationText = creationText.."addSpriteToLayer(%constructor:null%, %class%, "..spriteLayers[i][3].."Group , %xpos%, %ypos%, %degrees%, "..as3.tolua(layer.xScroll)..", "..as3.tolua(layer.xScroll)..", %flipped%, %scalex%, %scaley%, "..propertiesString..", onAddCallback );//%name%\n" 
			else
				creationText = creationText.."addSpriteToLayer(%constructor:null%, %class%, "..spriteLayers[i][3].."Group , %xpos%, %ypos%, %degrees%, %flipped%, %scalex%, %scaley%, "..propertiesString..", onAddCallback );//%name%\n" 
			end
			creationText = creationText.."%%if parent%%"
				creationText = creationText..tab3.."%getparent%.childAttachNode = %attachedsegment%;\n"
				creationText = creationText..tab3.."%getparent%.childAttachT = %attachedsegment_t%;\n"
			creationText = creationText.."%%endifparent%%"
			
			fileText = fileText..tab2.."public function addSpritesForLayer"..spriteLayers[i][3].."(onAddCallback:Function = null):void\n"
			fileText = fileText..tab2.."{\n"
		
			fileText = fileText..as3.tolua(DAME.CreateTextForSprites(layer,creationText,"Avatar"))
			fileText = fileText..tab2.."}\n\n"
		end
		
		-- Create the links between objects.
		
		fileText = fileText..tab2.."public function generateObjectLinks(onAddCallback:Function = null):void\n"
		fileText = fileText..tab2.."{\n"
		linkText = tab3.."createLink(linkedObjectDictionary[%linkfromid%], linkedObjectDictionary[%linktoid%], onAddCallback, "..propertiesString.." );\n"
		fileText = fileText..as3.tolua(DAME.GetTextForLinks(linkText,group))
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


	baseFileText = baseFileText..tab1.."}\n"	-- end class
	baseFileText = baseFileText.."}\n"		-- end package
	DAME.WriteFile(as3Dir.."/"..baseClassName..".as", baseFileText )

	spriteAnimString = "%%spriteanimloop%%"..tab3.."spriteData.animData.push( new AnimData( \"%animname%\",[%%animframeloop%%%tileid%%separator:,%%%animframeloopend%%], %fps%, %looped% ) );\n%%spriteanimloopend%%"
	spriteShapeString = "%%spriteframeloop%%"..tab3.."spriteData.shapeList[%frame%] = ( [%%shapeloop%%new AnimFrameShapeData(\"%shapename%\", AnimFrameShapeData.SHAPE_%TYPE%, %xpos%, %ypos%, %radius%, %wid%, %ht%)%separator:,\n"..tab5..tab5.."%%%shapeloopend%% ]);\n%%spriteframeloopend%%"
	spriteText = "%%if spriteanimsorshapes%%"..tab3.."spriteData = new SpriteData(\"%class%\", \"%name%\");\n"..spriteShapeString..spriteAnimString..tab3.."spriteList.push( spriteData );\n\n%%endif spriteanimsorshapes%%";

	spriteText = as3.tolua( DAME.CreateTextForSpriteClasses( spriteText, "", "", "", "", "" ) )

	if # spriteText > 0 then
		headerText = "//Code generated with DAME. http://www.dambots.com\n\n"
		headerText = headerText.."package "..GamePackage..".DAME_Export\n"
		headerText = headerText.."{\n"
		
		fileText = headerText
		fileText = fileText..tab1.."public class SpriteInfo\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."var spriteList:Array = [];\n"
		fileText = fileText..tab2.."public function SpriteInfo():void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."var spriteData:SpriteData;\n\n"
		fileText = fileText..spriteText
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(as3Dir.."\\DAME_Export\\SpriteInfo.as", fileText )
		
		--SpriteData class
		fileText = headerText
		fileText = fileText..tab1.."import flash.utils.Dictionary;\n"
		fileText = fileText..tab1.."public class SpriteData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."var animData:Array = [];	// AnimData\n"
		fileText = fileText..tab2.."var shapeList:Dictionary = new Dictionary;	// frame index => array of AnimFrameShapeList\n"
		fileText = fileText..tab2.."var className:String;\n"
		fileText = fileText..tab2.."var name:String;\n"
		fileText = fileText..tab2.."public function SpriteData( ClassName:String, Name:String ):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."className = ClassName;\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(as3Dir.."\\DAME_Export\\SpriteData.as", fileText )
		
		fileText = headerText
		fileText = fileText..tab1.."public class AnimFrameShapeData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."public var name:String;\n"
		fileText = fileText..tab2.."public var x:int;\n"
		fileText = fileText..tab2.."public var y:int;\n"
		fileText = fileText..tab2.."public var type:int;\n"
		fileText = fileText..tab2.."public var width:int = 0;\n"
		fileText = fileText..tab2.."public var height:int = 0;\n"
		fileText = fileText..tab2.."public var radius:int = 0;\n"
		fileText = fileText..tab2.."public static const SHAPE_POINT:uint = 0;\n"
		fileText = fileText..tab2.."public static const SHAPE_BOX:uint = 1;\n"
		fileText = fileText..tab2.."public static const SHAPE_CIRCLE:uint = 2;\n"
		fileText = fileText..tab2.."public function AnimFrameShapeData( Name:String, Type:int, X:int, Y:int, Radius:int, Wid:int, Ht:int ):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab3.."type = Type;\n"
		fileText = fileText..tab3.."x = X;\n"
		fileText = fileText..tab3.."y = Y;\n"
		fileText = fileText..tab3.."radius = Radius;\n"
		fileText = fileText..tab3.."width = Wid;\n"
		fileText = fileText..tab3.."Ht = Ht;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(as3Dir.."\\DAME_Export\\AnimFrameShapeData.as", fileText )
		
		fileText = headerText
		fileText = fileText..tab1.."public class AnimData\n"
		fileText = fileText..tab1.."{\n"
		fileText = fileText..tab2.."public var name:String;\n"
		fileText = fileText..tab2.."public var frames:Array;\n"
		fileText = fileText..tab2.."public var fps:Number;\n"
		fileText = fileText..tab2.."public var looped:Boolean;\n"
		fileText = fileText..tab2.."public function AnimData( Name:String, Frames:Array, Fps:Number, Looped:Boolean):void\n"
		fileText = fileText..tab2.."{\n"
		fileText = fileText..tab3.."name = Name;\n"
		fileText = fileText..tab3.."frames = Frames;\n"
		fileText = fileText..tab3.."fps = Fps;\n"
		fileText = fileText..tab3.."looped = Looped;\n"
		fileText = fileText..tab2.."}\n"
		fileText = fileText..tab1.."}\n"
		fileText = fileText.."}\n"
		DAME.WriteFile(as3Dir.."\\DAME_Export\\AnimData.as", fileText )
	end


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
		textfile = textfile..tab1.."import "..flixelPackage..".FlxGroup;\n"
		textfile = textfile..tab1.."import "..flixelPackage..".FlxSprite;\n\n"
		textfile = textfile..tab1.."public class PathData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var nodes:Array;\n"
		textfile = textfile..tab2.."public var isClosed:Boolean;\n"
		textfile = textfile..tab2.."public var isSpline:Boolean;\n"
		textfile = textfile..tab2.."public var layer:FlxGroup;\n\n"
		textfile = textfile..tab2.."// These values are only set if there is an attachment.\n"
		textfile = textfile..tab2.."public var childSprite:FlxSprite = null;\n"
		textfile = textfile..tab2.."public var childAttachNode:int = 0;\n"
		textfile = textfile..tab2.."public var childAttachT:Number = 0;\t// position of child between attachNode and next node.(0-1)\n\n"
		textfile = textfile..tab2.."public function PathData( Nodes:Array, Closed:Boolean, Spline:Boolean, Layer:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."nodes = Nodes;\n"
		textfile = textfile..tab3.."isClosed = Closed;\n"
		textfile = textfile..tab3.."isSpline = Spline;\n"
		textfile = textfile..tab3.."layer = Layer;\n"
		textfile = textfile..tab2.."}\n\n"
		textfile = textfile..tab2.."public function destroy():void\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."layer = null;\n"
		textfile = textfile..tab3.."childSprite = null;\n"
		textfile = textfile..tab3.."nodes = null;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/PathData.as", textfile )
		
	end
	
	if containsBoxData == true or containsCircleData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."import "..flixelPackage..".FlxGroup;\n\n"
		textfile = textfile..tab1.."public class ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var x:Number;\n"
		textfile = textfile..tab2.."public var y:Number;\n"
		textfile = textfile..tab2.."public var group:FlxGroup;\n\n"
		textfile = textfile..tab2.."public function ShapeData(X:Number, Y:Number, Group:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."x = X;\n"
		textfile = textfile..tab3.."y = Y;\n"
		textfile = textfile..tab3.."group = Group;\n"
		textfile = textfile..tab2.."}\n\n"
		textfile = textfile..tab2.."public function destroy():void\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."group = null;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/ShapeData.as", textfile )
	end
	
	if containsBoxData == true then
		textfile = "package "..GamePackage.."\n"
		textfile = textfile.."{\n"
		textfile = textfile..tab1.."import "..flixelPackage..".FlxGroup;\n\n"
		textfile = textfile..tab1.."public class BoxData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var angle:Number;\n"
		textfile = textfile..tab2.."public var width:uint;\n"
		textfile = textfile..tab2.."public var height:uint;\n\n"
		textfile = textfile..tab2.."public function BoxData( X:Number, Y:Number, Angle:Number, Width:uint, Height:uint, Group:FlxGroup ) \n"
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
		textfile = textfile..tab1.."import "..flixelPackage..".FlxGroup;\n\n"
		textfile = textfile..tab1.."public class CircleData extends ShapeData\n"
		textfile = textfile..tab1.."{\n"
		textfile = textfile..tab2.."public var radius:Number;\n\n"
		textfile = textfile..tab2.."public function CircleData( X:Number, Y:Number, Radius:Number, Group:FlxGroup )\n"
		textfile = textfile..tab2.."{\n"
		textfile = textfile..tab3.."super(X, Y, Group);\n"
		textfile = textfile..tab3.."radius = Radius;\n"
		textfile = textfile..tab2.."}\n"
		textfile = textfile..tab1.."}\n"
		textfile = textfile.."}\n"
		
		DAME.WriteFile(as3Dir.."/CircleData.as", textfile )
	end
	
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
	textfile = textfile..tab2.."}\n\n"
	textfile = textfile..tab2.."public function destroy():void\n"
	textfile = textfile..tab2.."{\n"
	textfile = textfile..tab3.."fromObject = null;\n"
	textfile = textfile..tab3.."toObject = null;\n"
	textfile = textfile..tab2.."}\n"
	textfile = textfile..tab1.."}\n"
	textfile = textfile.."}\n"
	DAME.WriteFile(as3Dir.."/ObjectLink.as", textfile )
end


return 1
