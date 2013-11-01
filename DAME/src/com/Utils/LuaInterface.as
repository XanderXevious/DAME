package com.Utils 
{
	import com.Game.Avatar;
	import com.Game.AvatarLink;
	import com.Game.EditorAvatar;
	import com.Game.PathEvent;
	import com.Game.PathObject;
	import com.Game.ShapeObject;
	import com.Game.SpriteFrames.SpriteShapeData;
	import com.Game.SpriteFrames.SpriteShapeList;
	import com.Game.SpriteTrailObject;
	import com.Game.TextObject;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerImage;
	import com.Layers.LayerMap;
	import com.Layers.LayerPaths;
	import com.Layers.LayerShapes;
	import com.Layers.LayerSprites;
	import com.Properties.CustomPropertyType;
	import com.Tiles.FlxTilemapExt;
	import com.Properties.PropertyBase;
	import com.Properties.PropertyData;
	import com.Tiles.SpriteEntry;
	import com.Tiles.StackTileInfo;
	import com.Tiles.TileAnim;
	import com.UI.ExporterPopup;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import mx.collections.ArrayCollection;
	import mx.containers.HBox;
	import mx.controls.Button;
	import mx.controls.CheckBox;
	import com.UI.MyComboBox;
	import mx.controls.Label;
	import mx.controls.TextArea;
	import mx.controls.TextInput;
	import mx.controls.NumericStepper;
	import mx.utils.ObjectUtil;
	import org.flixel.FlxPoint;
	import org.flixel.FlxRect;
	import org.flixel.FlxState;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class LuaInterface
	{
		private static const IfClassStr:String = "%%if class=";
		private static const ElseStr:String = "%%elseifanyclass%%";
		private static const ElseIfClassStr:String = "%%elseif class=";
		private static const EndIfStr:String = "%%endifclass%%";
		private static const PropStr:String = "%prop:";
		private static const PropLoopStr:String = "%%proploop%%";
		private static const PropLoopEndStr:String = "%%proploopend%%";
		private static const IfPropLengthStr:String = "%%ifproplength%%";
		private static const IfNoPropLengthStr:String = "%%ifnoproplength%%";
		private static const EndIfPropLengthStr:String = "%%endifproplength%%";
		private static const IfPropStr:String = "%%if prop:";
		private static const EndIfPropStr:String = "%%endprop%%";
		private static const StoreStr:String = "%store:";
		private static const StorePathSourceStr:String = "%storepathsource:";
		private static const IfParentStr:String = "%%if parent%%";
		private static const EndIfParentStr:String = "%%endifparent%%";
		private static const IfChildStr:String = "%%if child%%"
		private static const EndIfChildStr:String = "%%endifchild%%";
		private static const IfPathInstanceStr:String = "%%ifpathinstance%%";
		private static const ElseIfNoPathInstanceStr:String = "%%elseifnopathinstance%%";
		private static const EndIfPathInstanceStr:String = "%%endifpathinstance%%";
		private static const DoPathSourceStr:String = "%%dopathsource%%";
		private static const EndPathSourceStr:String = "%%endpathsource%%";
		private static const IfLinkStr:String = "%%if link%%";
		private static const IfLinkToStr:String = "%%if linkto%%";
		private static const IfLinkFromStr:String = "%%if linkfrom%%";
		private static const EndIfLinkStr:String = "%%endiflink%%";
		private static const LinksFromLoopStr:String = "%%linksfromloop%%";
		private static const LinksToLoopStr:String = "%%linkstoloop%%";
		private static const LinksLoopEndStr:String = "%%linkloopend%%";
		private static const CounterStr:String = "%counter%";
		private static const CounterIncStr:String = "%counter++%";
		private static const CustomCounterStr:String = "%counter:";
		private static const CustomCounterIncStr:String = "%counter++:";
		private static const ConstructorStr:String = "%constructor:";
		private static const ConstructorStartStr:String = "%constructor%";
		private static const ConstructorEndStr:String = "%constructorend%";
		private static const IfTileAnimsStr:String = "%%if tileanims%%";
		private static const EndIfTileAnimsStr:String = "%%endif tileanims%%";
		private static const IfTileAnimStr:String = "%%if tileanim%%";
		private static const EndIfTileAnimStr:String = "%%endif tileanim%%";
		private static const IfSpritesheetStr:String = "%%if spritesheet%%";
		private static const EndIfSpritesheetStr:String = "%%endif spritesheet%%";
		private static const IfAnimSpriteStr:String = "%%if animsprite%%";
		private static const EndIfAnimSpriteStr:String = "%%endif animsprite%%";
		private static const SpriteFrameLoopStr:String = "%%spriteframeloop%%";
		private static const SpriteFrameLoopEndStr:String = "%%spriteframeloopend%%";
		private static const ShapeLoopStr:String = "%%shapeloop%%";
		private static const ShapeLoopEndStr:String = "%%shapeloopend%%";
		private static const IfCircleStr:String = "%%ifcircle%%";
		private static const EndIfCircleStr:String = "%%endcircle%%";
		private static const IfBoxStr:String = "%%ifbox%%";
		private static const EndIfBoxStr:String = "%%endbox%%";
		private static const IfPointStr:String = "%%ifpoint%%";
		private static const EndIfPointStr:String = "%%endpoint%%";
		private static const SpriteAnimLoopStr:String = "%%spriteanimloop%%";
		private static const SpriteAnimLoopEndStr:String = "%%spriteanimloopend%%";
		private static const AnimFrameLoopStr:String = "%%animframeloop%%"
		private static const AnimFrameLoopEndStr:String = "%%animframeloopend%%";
		private static const CustomSeparator:String = "%separator:"
		private static const IfSpriteAnimsStr:String = "%%if spriteanims%%";
		private static const EndIfSpriteAnimsStr:String = "%%endif spriteanims%%";
		private static const IfShapesStr:String = "%%if shapes%%";
		private static const EndIfShapesStr:String = "%%endif shapes%%";
		private static const IfAnimsOrShapesStr:String = "%%if spriteanimsorshapes%%";
		private static const EndIfAnimsOrShapesStr:String = "%%endif spriteanimsorshapes%%";
		private static const IfPathEventsStr:String = "%%if pathevents%%"
		private static const EndIfPathEventsStr:String = "%%endifpathevents%%";
		
		public static var avatarCounter:uint = 0;
		private static var storedString:String = "";
		private static var storedAvatarStrings:Dictionary;
		private static var storedPathSourceStrings:Dictionary;
		private static var customCounters:Dictionary;
		private static var pathInstances:Dictionary;
		private static var linkIds:Dictionary;
		private static var zero:FlxPoint = new FlxPoint(0, 0);
		private static var floatPrecision:Number = 6;
		private static var spriteCounter:int = 0;
		private static var stringWrapperStart:String = "\"";
		private static var stringWrapperEnd:String = "\"";
		private static var exportHiddenProperties:Boolean = false;
		
		private static var browseLocationControl:Object = null;
		
		
		public static const ExportSpritePosType_TopLeft:String = "Top Left";
		public static const ExportSpritePosType_Center:String = "Center";
		public static const ExportSpritePosType_Anchor:String = "Anchor";
		public static const ExportSpritePosType_BoundsTopLeft:String = "Bounds Top Left";
		
		private static var exportSpritePosType:String = ExportSpritePosType_TopLeft;
		
		private static var currentPropTypes:Object = null;
		
		public static function InitInterface():void
		{
			avatarCounter = 0;
			storedString = "";
			floatPrecision = 6;
			storedAvatarStrings = new Dictionary(true);
			storedPathSourceStrings = new Dictionary(true);
			customCounters = new Dictionary(true);
			pathInstances = new Dictionary(true);
			linkIds = new Dictionary(true);
			exportHiddenProperties = false;
			var links:Vector.<AvatarLink> = AvatarLink.GetLinks();
			var i:uint = 0;
			for each( var link:AvatarLink in links )
			{
				if ( linkIds[ link.fromAvatar ] == null )
				{
					linkIds[ link.fromAvatar ] = i++;
				}
				if ( linkIds[ link.toAvatar ] == null )
				{
					linkIds[ link.toAvatar ] = i++;
				}
			}
			stringWrapperStart = "\"";
			stringWrapperEnd = "\"";
			currentPropTypes = null;
		}
		
		public static function ResetCounters():void
		{
			avatarCounter = 0;
			for ( var counter:String in customCounters )
			{
				customCounters[counter] = 0;
			}
		}
		
		public static function ResetCounter(name:String):void
		{
			if ( customCounters[name])
			{
				customCounters[name] = 0;
			}
		}
		
		public static function SetFloatPrecision( precision:Number ):void
		{
			floatPrecision = precision;
		}
		
		public static function SetExportHiddenProperties( exportThem:Boolean ):void
		{
			exportHiddenProperties = exportThem;
		}
		
		public static function GetProjectFile():String
		{
			try
			{
				return Global.CurrentProjectFile.nativePath;
			}
			catch (error:Error)
			{
			}
			return "";
		}
		
		public static function GetProjectFileLocation():String
		{
			try
			{
				if ( Global.CurrentProjectFile.parent )
				{
					return Global.CurrentProjectFile.parent.nativePath;
				}
			}
			catch ( error:Error )
			{
			}
			return "";
		}
		
		public static function GetProjectName():String
		{
			try
			{
				var nameMinusExtension:String = Global.CurrentProjectFile.name.replace("." + Global.CurrentProjectFile.extension, "");
				return nameMinusExtension;
			}
			catch ( error:Error )
			{
			}
			return "";
		}
		
		public static function ExportSpritesFromTopLeft():void { exportSpritePosType = ExportSpritePosType_TopLeft; }
		public static function ExportSpritesFromCenter():void { exportSpritePosType = ExportSpritePosType_Center; }
		public static function ExportSpritesFromAnchor():void { exportSpritePosType = ExportSpritePosType_Anchor; }
		public static function ExportSpritesFromBoundsTopLeft():void { exportSpritePosType = ExportSpritePosType_BoundsTopLeft; }
		public static function SetExportSpritesPos( type:String):void { exportSpritePosType = type; }
		
		public static function SetStringWrapper( start:String, end:String ):void
		{
			stringWrapperStart = start;
			stringWrapperEnd = end;
		}
		
		public static function SetCurrentPropTypes( propTypes:Object ):void
		{
			currentPropTypes = propTypes;
		}
				
		public static function GetGroups():ArrayCollection
		{
			var layerGroups:ArrayCollection = App.getApp().layerGroups;
			var groups:ArrayCollection = new ArrayCollection;
			var groupIndex:int;
			var layerIndex:int;
			var oldGroup:LayerGroup;
			var group:LayerGroup;
			var layer:LayerEntry;
			var id:uint = 0;
			if ( Global.DisplayLayersFirstOnTop )
			{
				groupIndex = layerGroups.length;
				while (groupIndex--)
				{
					oldGroup = layerGroups[groupIndex];
					if ( oldGroup.Exports(false) )
					{
						group = new LayerGroup(oldGroup.name);
						group.SetScrollFactors(oldGroup.xScroll,oldGroup.yScroll);
						group.visible = oldGroup.visible;
						group.properties = oldGroup.properties;
						group.exportId = oldGroup.exportId = id;
						id++;
						
						layerIndex = oldGroup.children.length;
						while (layerIndex--)
						{
							layer = oldGroup.children[layerIndex];
							if ( layer.Exports(false) )
							{
								group.children.addItem( layer );
							}
						}
						groups.addItem( group );
					}
				}
				return groups;
			}
			else
			{
				for (groupIndex = 0; groupIndex < layerGroups.length; groupIndex++ )
				{
					oldGroup = layerGroups[groupIndex];
					if ( oldGroup.Exports(false) )
					{
						group = new LayerGroup(oldGroup.name);
						group.SetScrollFactors(oldGroup.xScroll,oldGroup.yScroll);
						group.visible = oldGroup.visible;
						group.properties = oldGroup.properties;
						group.exportId = oldGroup.exportId = id;
						id++;
						
						for (layerIndex = 0; layerIndex < oldGroup.children.length; layerIndex++ )
						{
							layer = oldGroup.children[layerIndex];
							if ( layer.Exports(false) )
							{
								group.children.addItem( layer );
							}
						}
						groups.addItem( group );
					}
				}
				return groups;
				//return layerGroups;
			}
		}
		
		public static function GetBackgroundColor():String
		{
			return Misc.uintToHexStr8Digits(FlxState.bgColor);
		}
		
		public static function GetSpriteClasses():ArrayCollection
		{			
			return App.getApp().spriteData;	
		}
		
		/*public static function ConvertLayerToBytes( layerObj:Object):ByteArray
		{
			var data:ByteArray = new ByteArray;
			var layer:LayerEntry = layerObj as LayerEntry;
			data.writeInt(69);
			data.writeInt(5);
			return data;
		}*/

		public static function CreateTileDataText( mapLayer:Object, keywords:String, tileframeKeywords:String, animFrameSeparator:String):String
		{
			var layerMap:LayerMap = mapLayer as LayerMap;
			if ( !layerMap )
			{
				return "";
			}
			var map:FlxTilemapExt = layerMap.map;
			if ( !map )
			{
				return "";
			}
			
			var text:String = "";
			
			var tileAnims:Vector.<TileAnim> = layerMap.GetTileAnims();
			var tileProps:Vector.<ArrayCollection> = layerMap.GetTileProperties();
			
			var hasTileAnims:Boolean = tileAnims && tileAnims.length;
			
			for ( var i:uint = 0; i < map.tileCount; i++ )
			{
				var inputText:String = keywords;
				
				// Tile properties
				if ( tileProps && i < tileProps.length )
				{
					inputText = GetTextForProperties(inputText, tileProps[i], currentPropTypes );
				}
				else
				{
					inputText = GetTextForProperties(inputText, null );
				}
				
				// Tile anims
				inputText = ParseIfBlock(inputText, IfTileAnimsStr, EndIfTileAnimsStr, hasTileAnims );
				inputText = ReplaceKeyword(inputText, "%tileid%", String(i));
				
				if ( hasTileAnims )
				{
					var animId:int = tileAnims.length;
					var tileAnim:TileAnim = null;
					while (animId--)
					{
						if ( tileAnims[animId].tiles[0] == i )
						{
							tileAnim = tileAnims[animId];
							break;
						}
					}
					inputText = ParseIfBlock(inputText, IfTileAnimStr, EndIfTileAnimStr, tileAnim != null );
					inputText = ReplaceKeyword(inputText, "%fps%", (tileAnim ? tileAnim.fps : 0).toFixed(floatPrecision) );
					inputText = ReplaceKeyword(inputText, "%name%", tileAnim ? tileAnim.name : "" );
					inputText = ReplaceKeyword(inputText, "%numframes%", String(tileAnim ? tileAnim.tiles.length : 0) );
					inputText = ReplaceKeyword(inputText, "%looped%", String(tileAnim ? tileAnim.looped : true) );
					var tileframeText:String = "";
					if ( tileAnim )
					{
						for ( var j:int = 0; j < tileAnim.tiles.length; j++ )
						{
							var tileInputText:String = tileframeKeywords;
							tileInputText = ReplaceKeyword(tileInputText, "%frame%", String(j) );
							tileInputText = ReplaceKeyword(tileInputText, "%frame1%", String(j+1) );
							tileInputText = ReplaceKeyword(tileInputText, "%tileid%", String(tileAnim.tiles[j]) );
							tileInputText = ReplaceKeyword(tileInputText, "%separator%", j + 1 < tileAnim.tiles.length ? animFrameSeparator : "");
							tileframeText += tileInputText;
						}
					}
					inputText = ReplaceKeyword(inputText, "%tileframes%", tileframeText );
				}
				text = text + inputText;
			}
			
			return text;
		}
		
		private static function TryAddingTileStackData( map:FlxTilemapExt, sourceText:String, tileIdx:uint, pypos:int, tilePos:FlxPoint, keywords:String, separator:String):String
		{
			var text:String = "";
			var tileInfo:StackTileInfo = map.stackedTiles[tileIdx];
			if ( tileInfo )
			{
				var numDone:int = 0;
				for( var tileKey:Object in tileInfo.tiles )
				{
					var tempText:String = keywords;
					var tileZ:int = int(tileKey);
					var id:uint = tileInfo.tiles[tileZ];
					var yDiff:int = tileZ * map.stackHeight;
					tempText = ReplaceKeyword(tempText, "%zpos%", String(tileZ) );
					tempText = ReplaceKeyword(tempText, "%pzpos%", String(yDiff) );
					tempText = ReplaceKeyword(tempText, "%pypos%", String(pypos - yDiff) );
					tempText = ReplaceKeyword(tempText, "%tileId%", String(id) );
					tempText = ReplaceKeyword(tempText, "%tilex%", String(tilePos.x));
					tempText = ReplaceKeyword(tempText, "%tiley%", String(tilePos.y - yDiff));
					tempText = ReplaceKeyword(tempText, "%tileendx%", String(tilePos.x + map.tileWidth));
					tempText = ReplaceKeyword(tempText, "%tileendy%", String(tilePos.y + map.tileHeight - yDiff));
					text = text + (numDone ? separator : "" ) + tempText;
					numDone++;
				}
			}
			sourceText = ReplaceKeyword(sourceText, "%stackText%", text);
			return sourceText;
		}
		
		public static function ConvertMapToText( mapLayer:Object, rowPrefix:String, rowSuffix:String, colPrefix:String, colSepar:String, colSuffix:String, keywords:String = null, ignoreHiddenTiles:Boolean = false, groupBlocks:Boolean = false, stackKeywords:String = null, stackSeparator:String = ","):String
		{
			var i:uint = 0;
			var text:String = "";
			
			if ( mapLayer is LayerMap )
			{
				var map:FlxTilemapExt = mapLayer.map;
				var pt:FlxPoint = new FlxPoint();
				var py:uint = 0;
				
				var doStacks:Boolean = keywords && stackKeywords && map.stackedTiles && map.numStackedTiles && keywords.indexOf("%stackText%") != -1;
				for ( var y:uint = 0; y < map.heightInTiles; y++ )
				{
					py = y * map.tileHeight;
					text += rowPrefix;
					
					var tileText:String;
					var tileIndex:uint;
					var sameTileCount:uint = 1;
					
					var addedTile:Boolean = false;
					if ( map.widthInTiles > 0 )
					{
						tileText = "";
						tileIndex = map.getTileByIndex(i);
						if ( keywords == null )
						{
							tileText = String(tileIndex);
							text += colPrefix + tileText; 
						}
						else if( !ignoreHiddenTiles || tileIndex >= map.drawIndex )
						{
							var addTile:Boolean = !groupBlocks;
							if ( groupBlocks )
							{
								if ( map.widthInTiles == 1 || map.getTileByIndex(i+1) != tileIndex )
								{
									addTile = true;
								}
								else
								{
									sameTileCount++;
								}
							}
							if ( addTile )
							{
								tileText = keywords;
								map.getTileBitmapCoords(tileIndex, pt);
								tileText = ReplaceKeyword(tileText, "%tilex%", String(pt.x));
								tileText = ReplaceKeyword(tileText, "%tiley%", String(pt.y));
								tileText = ReplaceKeyword(tileText, "%tilewid%", String(map.tileWidth));
								tileText = ReplaceKeyword(tileText, "%tileht%", String(map.tileHeight));
								tileText = ReplaceKeyword(tileText, "%tileendx%", String(pt.x + map.tileWidth));
								tileText = ReplaceKeyword(tileText, "%tileendy%", String(pt.y + map.tileHeight));
								tileText = ReplaceKeyword(tileText, "%xpos%", "0" );
								tileText = ReplaceKeyword(tileText, "%ypos%", String(y ));
								tileText = ReplaceKeyword(tileText, "%pxpos%", "0" );
								tileText = ReplaceKeyword(tileText, "%pypos%", String(py ));
								tileText = ReplaceKeyword(tileText, "%idx%", String(i));
								tileText = ReplaceKeyword(tileText, "%tileId%", String(tileIndex));
								tileText = ReplaceKeyword(tileText, "%blockCount%", String(sameTileCount));
								if ( doStacks )
								{
									tileText = TryAddingTileStackData( map, tileText, i, py, pt, stackKeywords, stackSeparator );
								}
								else
								{
									tileText = ReplaceKeyword(tileText, "%stackText%", "");
								}
								text += colPrefix + tileText;
								addedTile = true;
								sameTileCount = 1;
							}
						}
						
						i++;
					}
					var px:uint = 0;
					
					for ( var x:uint = 1; x < map.widthInTiles; x++ )
					{
						tileText = "";
						tileIndex = map.getTileByIndex(i);
						if ( keywords == null )
						{
							tileText = String(tileIndex);
							text += colSuffix + colSepar + colPrefix + tileText; 
						}
						else if( !ignoreHiddenTiles || tileIndex >= map.drawIndex )
						{
							addTile = !groupBlocks;
							if ( groupBlocks )
							{
								if ( map.widthInTiles == x + 1 || map.getTileByIndex(i+1) != tileIndex )
								{
									addTile = true;
								}
								else
								{
									sameTileCount++;
								}
							}
							if ( addTile )
							{
								tileText = keywords;
								px = x * map.tileWidth;
								map.getTileBitmapCoords(tileIndex, pt);
								tileText = ReplaceKeyword(tileText, "%tilex%", String(pt.x));
								tileText = ReplaceKeyword(tileText, "%tiley%", String(pt.y));
								tileText = ReplaceKeyword(tileText, "%tilewid%", String(map.tileWidth));
								tileText = ReplaceKeyword(tileText, "%tileht%", String(map.tileHeight));
								tileText = ReplaceKeyword(tileText, "%tileendx%", String(pt.x + map.tileWidth));
								tileText = ReplaceKeyword(tileText, "%tileendy%", String(pt.y + map.tileHeight));
								tileText = ReplaceKeyword(tileText, "%xpos%", String(x ));
								tileText = ReplaceKeyword(tileText, "%ypos%", String(y ));
								tileText = ReplaceKeyword(tileText, "%pxpos%", String(px ));
								tileText = ReplaceKeyword(tileText, "%pypos%", String(py ));
								tileText = ReplaceKeyword(tileText, "%idx%", String(i ));
								tileText = ReplaceKeyword(tileText, "%tileId%", String(tileIndex));
								tileText = ReplaceKeyword(tileText, "%blockCount%", String(sameTileCount));
								if ( doStacks )
								{
									tileText = TryAddingTileStackData( map, tileText, i, py, pt, stackKeywords, stackSeparator );
								}
								else
								{
									tileText = ReplaceKeyword(tileText, "%stackText%", "");
								}
								if ( addedTile )
								{
									text += colSuffix + colSepar;
								}
								text += colPrefix + tileText; 
								addedTile = true;
								sameTileCount = 1;
							}
						}
						
						i++;
					}
					if ( map.widthInTiles > 0 && addedTile )
					{
						text += colSuffix;
					}
					text += rowSuffix;
				}
			}
			return text;
		}
		
		private static function CreateTextForAvatar( avatar:EditorAvatar, defaultCreation:String, defaultClass:String ):String
		{
			var newText:String = defaultCreation;
			var classname:String = defaultClass;
			
			if ( !avatar.Exports() )
			{
				return "";
			}
			
			if ( avatar is SpriteTrailObject )
			{
				return "";
				// No need to export the children, as they're already added to the layer.
				/*var spriteTrail:SpriteTrailObject = avatar as SpriteTrailObject;
				for ( var i:int = 0; i < spriteTrail.children.length; i++ )
				{
					newText = newText + CreateTextForAvatar( spriteTrail.children[i], defaultCreation, defaultClass );
				}*/
			}
			else if ( !(avatar is PathObject) )
			{
				if ( avatar.spriteEntry )
				{
					if ( avatar.spriteEntry.className.length )
					{
						classname = avatar.spriteEntry.className;
					}
					if ( avatar.spriteEntry.creationText.length )
					{
						newText = avatar.spriteEntry.creationText;
					}
				}
			}
			
			var index:int;
			var classIndex:int;
			var endIndex:int;
			
			while ( ( index = newText.indexOf( IfClassStr ) ) != -1 )
			{
				// Found an "%%if class=" block
				endIndex = newText.indexOf(EndIfStr );
				if ( endIndex != -1 )
				{
					var sub:String = newText.substring(index, endIndex + EndIfStr.length);
					newText = newText.replace(sub, GetTextForIfLoop(sub, avatar, classname) );
				}
				else
				{
					newText = newText.replace(newText.substring(index, index + IfClassStr.length), "");
				}
			}
			
			// Replace the keywords after the conditional statements have been parsed,
			// as they will be correct for this avatar at this point.
			
			newText = ParseCommonKeywords( avatar, newText, classname);
			
			
			return newText;
		}
		
		public static function CreateTextForAllAvatars( layer:Object, defaultCreation:String, defaultClass:String ):String
		{
			var text:String = ""
			
			var avatarLayer:LayerAvatarBase = layer as LayerAvatarBase;
			
			if ( avatarLayer == null )
			{
				return text;
			}
		
			for ( var i:uint = 0; i < avatarLayer.sprites.members.length; i++ )
			{
				var avatar:EditorAvatar = avatarLayer.sprites.members[i];
				
				text = text + CreateTextForAvatar(avatar, defaultCreation, defaultClass );
			}
			
			return text;
		}
		
		private static function GetTextForIfLoop( inputText:String, avatar:EditorAvatar, classname:String ):String
		{
			// Find the class, which is wrapped up by another %%
			var classIndex:int = IfClassStr.length;
			var classEndIndex:int = inputText.indexOf( "%%", classIndex );
			var endIndex:int = classEndIndex;
			var noClass:Boolean = false;
			while ( endIndex != -1 )
			{
				if ( !noClass )
				{
					var classString:String = inputText.substring(classIndex, classEndIndex);
					classIndex = classEndIndex + 2;
				}
				
				// Find the end of this block.
				var elseIndex:int = -1;
				var elseIfIndex:int = inputText.indexOf( ElseIfClassStr, endIndex );
				var nextClassIndex:int = -1;
				
				if ( elseIfIndex != -1 )
				{
					nextClassIndex = elseIfIndex + ElseIfClassStr.length;
					endIndex = elseIfIndex;
					classEndIndex = inputText.indexOf( "%%", nextClassIndex );
				}
				else
				{
					elseIndex = inputText.indexOf( ElseStr, endIndex );
					if ( elseIndex != -1 )
					{
						nextClassIndex = elseIndex + ElseStr.length;
						classEndIndex = nextClassIndex + 2;
						endIndex = elseIndex;
					}
					else
					{
						endIndex = inputText.indexOf( EndIfStr, endIndex );
						classEndIndex = -1;
					}
				}
				
				if ( noClass || classname == classString ||
					( avatar is PathObject && classString == "/PATH") ||
					( avatar.spriteEntry && avatar.spriteEntry.IsTileSprite && classString == "/TILE" ) )
				{
					var sub:String = inputText.substring(classIndex, endIndex);
					//var output:String = GetTextForProperties(sub, avatar.properties );
					return sub;
				}
				else
				{
					classIndex = nextClassIndex;
					noClass = ( elseIndex != -1 );
					endIndex = classEndIndex;
				}
				
			}
			return "";
		}
		
		public static function GetTextForLinks( inputText:String, group:Object = null ):String
		{
			var output:String = "";
			var links:Vector.<AvatarLink> = AvatarLink.GetLinks();
			var layerGroup:LayerGroup = group as LayerGroup;
			
			for ( var i:uint = 0; i < links.length; i++ )
			{
				var link:AvatarLink = links[i];
				
				if ( layerGroup )
				{
					try
					{
						if ( !link.fromAvatar || !link.fromAvatar.layer || (link.fromAvatar.layer.parent as LayerGroup).exportId != layerGroup.exportId )
						{
							continue;
						}
						if ( !link.toAvatar || !link.toAvatar.layer || (link.toAvatar.layer.parent as LayerGroup).exportId != layerGroup.exportId )
						{
							continue;
						}
					}
					catch( error:Error){}
				}
				
				var block:String = inputText;
				
				block = ReplaceKeyword( block, "%linkidx%", String(i) );
				block = ReplaceKeyword( block, "%linkfromid%", String(linkIds[link.fromAvatar]) );
				block = ReplaceKeyword( block, "%linktoid%", String(linkIds[link.toAvatar]) );
				block = ReplaceKeyword( block, "%getlinkfromstr%", storedAvatarStrings[link.fromAvatar] );
				block = ReplaceKeyword( block, "%getlinktostr%", storedAvatarStrings[link.toAvatar] );
				
				block = GetTextForProperties(block, link.properties, currentPropTypes );
				output += block;
			}
			
			return output;
		}
		
		public static function GetTextForProperties( inputText:String, properties:ArrayCollection, propTypeStrings:Object = null ):String
		{
			/*if ( properties == null || properties.length == 0 )
			{
				return "";
			}*/
			var output:String = inputText;
			var index:int;
			var endIndex:int;
			var blockString:String;
			
			if ( !propTypeStrings )
			{
				propTypeStrings = currentPropTypes;
			}
			
			var propCount:uint = 0;
			
			if ( !exportHiddenProperties && properties )
			{
				var i:uint = properties.length;
				while ( i-- )
				{
					propData = properties[i] as PropertyBase;
					if ( !propData.Hidden )
					{
						propCount++;
					}
				}
			}
			else if ( properties )
			{
				propCount = properties.length;
			}
			output = ParseIfBlock(output, IfPropLengthStr, EndIfPropLengthStr, propCount > 0 );
			output = ParseIfBlock(output, IfNoPropLengthStr, EndIfPropLengthStr, !properties || propCount==0 );
			
			// Look for individual properties.
			while ( (index = output.indexOf(PropStr)) != -1 )
			{
				var propIndex:int = index + PropStr.length;
				var nameEndIndex:int = output.indexOf("%", propIndex );
				if ( nameEndIndex == -1 )
				{
					break;
				}

				endIndex = nameEndIndex + 1;
				var sub:String = output.substring(index, endIndex);
				var propName:String = output.substring(propIndex, nameEndIndex);
				var foundProp:Boolean = false;
				if ( propName && propName.length )
				{
					i = properties.length;
					while ( i-- )
					{
						var propData:PropertyBase = properties[i] as PropertyBase;
						if ( propData.Name == propName )
						{
							foundProp = true;
							output = output.replace(sub, propData.ExportedValue);
							break;
						}
					}
				}
				if ( !foundProp )
				{
					output = output.replace(sub, "");
				}
			}
			
			// Look for conditional properties
			
			while ( (index = output.indexOf(IfPropStr)) != -1 )
			{
				propIndex = index + IfPropStr.length;
				nameEndIndex = output.indexOf("%%", propIndex );
				endIndex = output.indexOf( EndIfPropStr, index );
				
				if ( endIndex == -1 || nameEndIndex == -1 )
				{
					break;
				}
				
				blockString = output.substring(index, endIndex + EndIfPropStr.length);
				
				propName = output.substring(propIndex, nameEndIndex);
				foundProp = false;
				for ( i = 0; i < properties.length; i++ )
				{
					propData = properties[i] as PropertyBase;
					if ( propData.Name == propName )
					{
						var isString:Boolean = propData.IsAStringType();
						sub = output.substring(nameEndIndex + 2, endIndex);
						
						var valueString:String = String(propData.ExportedValue);
						
						sub = ReplaceKeyword(sub, "%propvalue%", valueString );
						while (sub.indexOf("%propvaluestring%") != -1)
						{
							var text:String = valueString;
							if ( isString )
							{
								text = stringWrapperStart + text + stringWrapperEnd;
							}
							sub = sub.replace("%propvaluestring%", text );  
						}
						foundProp = true;
						output = output.replace( blockString , sub);
						break;
					}
				}
				if ( !foundProp )
				{
					output = output.replace( blockString , "");
				}
			}
			
			// Look for property loops.
			
			while ( (index = output.indexOf(PropLoopStr)) != -1 )
			{
				propIndex = index + PropLoopStr.length;
				endIndex = output.indexOf( PropLoopEndStr, index );
				
				if ( endIndex == -1 )
				{
					break;
				}
				blockString = output.substring(index, endIndex + PropLoopEndStr.length);

				sub = output.substring(propIndex, endIndex);
				var propList:String = "";
				if ( properties != null )
				{
					for ( i = 0; i < properties.length; i++ )
					{
						propData = properties[i] as PropertyBase;
						if ( exportHiddenProperties || !propData.Hidden )
						{
							var newProp:String = sub;
							valueString = String(propData.ExportedValue);
							newProp = ReplaceKeyword(newProp, "%propname%", propData.Name );
							newProp = ReplaceKeyword(newProp, "%propvalue%", valueString );
							if ( newProp.indexOf("%proptype%") != -1 )
							{
								if ( propTypeStrings )
								{
									if ( propData.Type == String )
									{
										newProp = ReplaceKeyword(newProp, "%proptype%", propTypeStrings.String );
									}
									else if ( propData.Type == Number )
									{
										newProp = ReplaceKeyword(newProp, "%proptype%", propTypeStrings.Float );
									}
									else if ( propData.Type == int )
									{
										newProp = ReplaceKeyword(newProp, "%proptype%", propTypeStrings.Int );
									}
									else if ( propData.Type == Boolean )
									{
										newProp = ReplaceKeyword(newProp, "%proptype%", propTypeStrings.Boolean );
									}
								}
								else
								{
									ExporterPopup.ExporterWindow.LogWriteLine("<font color=\"#FF0000\">GetTextForProperties missing proptype list. Either pass in the proptypes directly or call SetCurrentPropTypes.\n" +
															"Expects something like this:\npropTypes = as3.toobject({ String=\"String\", Int=\"int\", Float=\"Number\", Boolean=\"Boolean\" })</font>");
									throw new Error();
								}
								var customType:CustomPropertyType = propData.GetTypeObj() as CustomPropertyType;
								if ( customType )
								{
									newProp = ReplaceKeyword( newProp, "%proptype%", customType.ExportedType );
								}
							}
						
							if (newProp.indexOf("%propnamefriendly%") != -1)
							{
								// this regexp only allows letters, numbers and underscores
								var safe:RegExp = /[^a-zA-Z0-9_]+/g;
								var friendly:String = propData.Name.replace(safe, "_");
								newProp = ReplaceKeyword(newProp, "%propnamefriendly%", friendly );
							}
							isString = propData.IsAStringType();
							while (newProp.indexOf("%propvaluestring%") != -1)
							{
								text = valueString;
								if ( isString )
								{
									text = stringWrapperStart + text + stringWrapperEnd;
								}
								newProp = newProp.replace("%propvaluestring%", text );  
							}
							newProp = ParseSeparator(newProp, i+1 < properties.length);
							propList += newProp;
						}
					}
				}
				output = output.replace( blockString , propList);
			}
			
			return output;
		}
		
		public static function CreateTextForImageLayer( layer:Object, text:String, baseDirectory:String ):String
		{
			var imageLayer:LayerImage = layer as LayerImage;
			if ( imageLayer )
			{
				var newText:String = text;
				if ( imageLayer.imageFile && imageLayer.imageFile.exists )
				{
					newText = ReplaceKeyword(newText, "%imagefile%", imageLayer.imageFile.nativePath );
					/*if ( baseDirectory && baseDirectory.length )
					{
						try
						{
							var sourceFile:File = new File(baseDirectory);
							var path:String = sourceFile.getRelativePath( imageLayer.imageFile, true );
							if ( path )
							{
								newText = ReplaceKeyword(newText, "%imagefilerelative%", path );
							}
						}
						catch (error:Error){}
					}*/
					newText = GetRelativePathInternal(newText, baseDirectory, imageLayer.imageFile, "%imagefilerelative%" );
					newText = ReplaceKeyword(newText, "%imagefilename%", imageLayer.imageFile.name );
					newText = ReplaceKeyword(newText, "%alpha%", imageLayer.opacity.toFixed(floatPrecision) );
					newText = ReplaceKeyword(newText, "%xpos%", imageLayer.sprite.x.toString() );
					newText = ReplaceKeyword(newText, "%ypos%", imageLayer.sprite.y.toString() );
					newText = ReplaceKeyword(newText, "%scrollx%", imageLayer.xScroll.toFixed(floatPrecision) );
					newText = ReplaceKeyword(newText, "%scrolly%", imageLayer.yScroll.toFixed(floatPrecision) );
					newText = ReplaceKeyword(newText, "%width%", imageLayer.sprite.width.toString() );
					newText = ReplaceKeyword(newText, "%height%", imageLayer.sprite.height.toString() );
					return newText;
				}
			}
			return "";
		}
		
		public static function CreateTextForSprites( layer:Object, defaultCreation:String, defaultClass:String ):String
		{
			if ( layer is LayerSprites )
			{
				return CreateTextForAllAvatars( layer, defaultCreation, defaultClass );
			}
			return "";
		}
		
		private static function ReplaceSpecialChars( text:String ):String
		{
			var re1:RegExp = new RegExp("\"", "g"); 
			var replaceText:String = "\\\"";
			text = text.replace(re1, replaceText);
			re1 = new RegExp("\n", "g"); 
			replaceText = "\\n";
			text = text.replace(re1, replaceText);
			re1 = new RegExp("\r", "g"); 
			replaceText = "\\r";
			text = text.replace(re1, replaceText);
			return text;
		}
		
		public static function CreateTextForShapes( layer:Object, circleText:String, rectangleText:String, textText:String, bmpfontText:String = "", baseDirectory:String = null ):String
		{
			var text:String = "";
			
			var shapeLayer:LayerShapes = layer as LayerShapes;
			
			if ( shapeLayer == null )
			{
				return text;
			}
			
			for ( var i:uint = 0; i < shapeLayer.sprites.members.length; i++ )
			{
				var shapeobj:ShapeObject = shapeLayer.sprites.members[i];
				
				var newText:String;
				
				var textobj:TextObject = shapeobj as TextObject;
				if ( textobj )
				{
					if ( textobj.bmpText )
					{
						newText = bmpfontText;
						
						if ( newText.indexOf("%text%") != -1 )
						{
							var textstr:String = textobj.bmpText.text;
							textstr = ReplaceSpecialChars(textstr);
							newText = ReplaceKeyword(newText, "%text%", textstr);
						}
						if ( newText.indexOf("%lineSplitText%") != -1 )
						{
							textstr = textobj.bmpText.lineSplitText;
							textstr = ReplaceSpecialChars(textstr);
							newText = ReplaceKeyword(newText, "%lineSplitText%", textstr);
						}
						
						
						newText = ReplaceKeyword(newText, "%align%", textobj.bmpText.align );
						if ( newText.indexOf( "%characterSet%" ) )
						{
							textstr = ReplaceSpecialChars(textobj.bmpText.characterSet);
							newText = ReplaceKeyword(newText, "%characterSet%", textstr );
						}
						
						newText = ReplaceKeyword(newText, "%fontWidth%", String(textobj.bmpText.characterWidth) );
						newText = ReplaceKeyword(newText, "%fontHeight%", String(textobj.bmpText.characterHeight) );
						//newText = ReplaceKeyword(newText, "%autoTrim%", textobj.bmpText.autoTrim );
						newText = ReplaceKeyword(newText, "%xSpacing%", String(textobj.bmpText.customSpacingX) );
						newText = ReplaceKeyword(newText, "%ySpacing%", String(textobj.bmpText.customSpacingY) );
						newText = ReplaceKeyword(newText, "%scale%", textobj.bmpText.scaler.toFixed(floatPrecision) );
						newText = ReplaceKeyword(newText,"%imagefile%", textobj.bmpText.bmpFile.nativePath );
						newText = ReplaceKeyword(newText, "%imagefilename%", textobj.bmpText.bmpFile.name );
						newText = GetRelativePathInternal(newText, baseDirectory, textobj.bmpText.bmpFile, "%imagefilerelative%" );
					}
					else
					{
						newText = textText;
						
						if( newText.indexOf("%text%") != -1)
						{
							textstr = textobj.text.text;
							textstr = ReplaceSpecialChars(textstr);
							newText = ReplaceKeyword(newText, "%text%", textstr);
						}
						
						var textColorStr:String = Misc.uintToHexStr6Digits(textobj.text.color,"");
						newText = ReplaceKeyword(newText, "%color%", textColorStr);
						newText = ReplaceKeyword(newText, "%colour%", textColorStr);
						newText = ReplaceKeyword(newText, "%size%", String(textobj.text.size) );
						newText = ReplaceKeyword(newText, "%font%", textobj.text.font);
						newText = ReplaceKeyword(newText, "%align%", textobj.text.alignment);
					}
				}
				else
				{
					newText = shapeobj.isEllipse ? circleText : rectangleText;
				}
				
				newText = ReplaceKeyword(newText, "%radius%", (shapeobj.width * 0.5).toFixed(floatPrecision));
				newText = ReplaceKeyword(newText, "%diameter%", shapeobj.width.toFixed(floatPrecision));
				newText = ReplaceKeyword(newText, "%shapeColor%", Misc.uintToHexStr6Digits( (shapeobj.colourOverriden ? shapeobj.fillColour : Global.ShapeColour),"") );
				newText = ReplaceKeyword(newText, "%alpha%", (shapeobj.colourOverriden ? shapeobj.alphaValue : Global.ShapeAlpha ).toFixed(floatPrecision));
				
				text += ParseCommonKeywords(shapeobj, newText, "");
			}

			return text;
		}
		
		public static function CreateTextForPaths( layer:Object, polylineText:String, lineNodeText:String, curvesText:String, curveNodeText:String,nodeSepar:String, eventsText:String=null):String
		{
			var text:String = ""
			
			var pathLayer:LayerPaths = layer as LayerPaths;
			
			if ( pathLayer == null )
			{
				return text;
			}
		
			for ( var i:uint = 0; i < pathLayer.sprites.members.length; i++ )
			{
				var pathobj:PathObject = pathLayer.sprites.members[i];
				var newText:String = ( pathobj.IsCurved ) ? curvesText : polylineText;
				
				var index:int;
				
				// Look for conditionals that check for if the pathobj is instanced or not.
				while ( ( index = newText.indexOf( IfPathInstanceStr ) ) != -1 )
				{
					var elseIndex:int = newText.indexOf( ElseIfNoPathInstanceStr );
					var endIndex:int = newText.indexOf( EndIfPathInstanceStr );
					if ( endIndex == -1 )
					{
						break;
					}
					var sub:String;
					
					if ( pathobj.IsInstanced )
					{
						sub = newText.substring(index + IfPathInstanceStr.length, ( elseIndex != -1 ? elseIndex : endIndex ) );
					}
					else if ( elseIndex != -1 )
					{
						sub = newText.substring(elseIndex + ElseIfNoPathInstanceStr.length, endIndex );
					}
					else
					{
						newText = newText.replace( newText.substring( index, endIndex + EndIfPathInstanceStr.length ) );
						continue;
					}
					newText = newText.replace( newText.substring( index, endIndex + EndIfPathInstanceStr.length), sub );
				}
			
				// Look for code that will create a path source.
				while ( ( index = newText.indexOf( DoPathSourceStr ) ) != -1 )
				{
					endIndex = newText.indexOf( EndPathSourceStr );
					if ( endIndex == -1 )
					{
						break;
					}
					if ( pathobj.IsInstanced && pathInstances[ pathobj.instancedShapes ] != true )
					{
						pathInstances[ pathobj.instancedShapes ] = true;
						sub = newText.substring( index + DoPathSourceStr.length, endIndex );
						newText = newText.replace( newText.substring( index, endIndex + EndPathSourceStr.length), sub );
					}
					else
					{
						newText = newText.replace( newText.substring( index, endIndex + EndPathSourceStr.length), "" );
					}
				}
				
				// Path nodes.
				
				if ( newText.indexOf("%nodelist%") != -1 )
				{
					var nodeListText:String = "";
					
					for ( var j:uint = 0; j < pathobj.nodes.length; j++ )
					{
						nodeListText += ( pathobj.IsCurved ) ? curveNodeText : lineNodeText;
						if ( j + 1 < pathobj.nodes.length )
						{
							nodeListText += nodeSepar;
						}
						
						var pos:Number;
						
						nodeListText = ReplaceKeyword(nodeListText, "%nodex%", (pathobj.x + pathobj.nodes[j].x).toFixed(floatPrecision) );
						nodeListText = ReplaceKeyword(nodeListText, "%nodey%", (pathobj.y + pathobj.nodes[j].y).toFixed(floatPrecision) );  
						nodeListText = ReplaceKeyword(nodeListText, "%relativenodex%", pathobj.nodes[j].x.toFixed(floatPrecision) );  
						nodeListText = ReplaceKeyword(nodeListText, "%relativenodey%", pathobj.nodes[j].y.toFixed(floatPrecision) );  
						
						if ( pathobj.IsCurved )
						{
							nodeListText = ReplaceKeyword(nodeListText, "%tan1x%", pathobj.nodes[j].tangent1.x.toFixed(floatPrecision) );  
							nodeListText = ReplaceKeyword(nodeListText, "%tan1y%", pathobj.nodes[j].tangent1.y.toFixed(floatPrecision) );  
							nodeListText = ReplaceKeyword(nodeListText, "%tan2x%", pathobj.nodes[j].tangent2.x.toFixed(floatPrecision) );  
							nodeListText = ReplaceKeyword(nodeListText, "%tan2y%", pathobj.nodes[j].tangent2.y.toFixed(floatPrecision) );  
						}
					}
					
					newText = ReplaceKeyword(newText, "%nodelist%", nodeListText ); 
				}
				newText = ReplaceKeyword(newText, "%nodecount%", pathobj.nodes.length.toString() );  
				newText = ReplaceKeyword(newText, "%isclosed%", pathobj.IsClosedPoly.toString() );
				newText = ReplaceKeyword(newText, "%fillColor%", Misc.uintToHexStr6Digits( pathobj.ShapeFillColor,"") );
				newText = ReplaceKeyword(newText, "%fillAlpha%", pathobj.ShapeFillAlpha.toFixed(floatPrecision));
				
				
				// Path Events.
				newText = ParseIfBlock( newText, IfPathEventsStr, EndIfPathEventsStr, pathobj.pathEvents.length > 0 );
							
				if ( newText.indexOf("%eventlist%")!=-1)
				{
					var eventListText:String = "";
					
					for ( j = 0; j < pathobj.pathEvents.length; j++ )
					{
						var pathEvent:PathEvent = pathobj.pathEvents[j];
						eventListText += eventsText;
						eventListText = ReplaceKeyword(eventListText, "%xpos%", pathEvent.x.toFixed(floatPrecision) );
						eventListText = ReplaceKeyword(eventListText, "%ypos%", pathEvent.y.toFixed(floatPrecision) );
						eventListText = ReplaceKeyword(eventListText, "%segment%", pathEvent.segmentNumber.toString() );
						eventListText = ReplaceKeyword(eventListText, "%percent%", pathEvent.percentInSegment.toFixed(floatPrecision) );
						eventListText = ParseSeparator(eventListText, j + 1 < pathobj.pathEvents.length );
						eventListText = GetTextForProperties(eventListText, pathEvent.properties, currentPropTypes );
					}
					newText = ReplaceKeyword(newText, "%eventlist%", eventListText ); 
				}
				newText = ReplaceKeyword(newText, "%eventcount%", pathobj.pathEvents.length.toString() );  
				
				newText = ParseCommonKeywords( pathobj, newText, "");
				
				// Must do these last to avoid accounting for extra % symbols.
				newText = ParseSequentialKeywords(newText, StorePathSourceStr, storePathCb, "%getpathsource%", getPathCb);
				function storePathCb(input:String,storeIndex:int):String
				{
					// Store the avatar string.
					input = input.replace(StorePathSourceStr, "" );
					var endIndex:int = input.indexOf("%", storeIndex);
					if ( endIndex != -1 )
					{
						storedString = input.substring(storeIndex, endIndex);
						input = input.replace( storedString + "%", "" );
					}
					storedPathSourceStrings[ pathobj.instancedShapes ] = storedString;
					return input;
				}
				function getPathCb(input:String,getIndex:int):String
				{
					input = input.replace("%getpathsource%", storedPathSourceStrings[ pathobj.instancedShapes ] );  
					return input;
				}
				
				text = text + newText;
			}
			
			return text;
		}
		
		private static function ParseCommonKeywords( avatar:EditorAvatar, inputText:String, classname:String ):String
		{
			var anchor:FlxPoint = zero;
			
			if ( !( avatar is PathObject ) && avatar.spriteEntry )
			{
				anchor = avatar.spriteEntry.Anchor;
			}
			
			var index:int;
			var endIndex:int;
			
			var attachedAvatar:EditorAvatar = ( avatar.attachment != null ) ? avatar.attachment.Parent as EditorAvatar : null;
			var isTrue:Boolean = ( attachedAvatar != null && (!attachedAvatar.layer || attachedAvatar.layer.Exports()) );
			inputText = ParseIfBlock(inputText, IfParentStr, EndIfParentStr, isTrue );
			
			attachedAvatar = ( avatar.attachment != null ) ? avatar.attachment.Child as EditorAvatar : null;
			isTrue = ( attachedAvatar != null && (!attachedAvatar.layer || attachedAvatar.layer.Exports()) );
			inputText = ParseIfBlock(inputText, IfChildStr, EndIfChildStr, isTrue );
			
			// Handle the links...
			inputText = ParseIfBlock(inputText, IfLinkStr, EndIfLinkStr, avatar.linksFrom.length > 0 || avatar.linksTo.length > 0 );
			inputText = ParseIfBlock(inputText, IfLinkToStr, EndIfLinkStr, avatar.linksTo.length > 0 );
			inputText = ParseIfBlock(inputText, IfLinkFromStr, EndIfLinkStr, avatar.linksFrom.length > 0 );
			
			inputText = ParseIfBlock(inputText, IfSpritesheetStr, EndIfSpritesheetStr, avatar.isTileSprite );
			inputText = ParseIfBlock(inputText, IfAnimSpriteStr, EndIfAnimSpriteStr, !avatar.isTileSprite && avatar.spriteEntry );
			
			// Conditional block constructor text. allows keywords.
			if ( avatar.spriteEntry )
			{
				while ( (index = inputText.indexOf(ConstructorStartStr)) != -1 )
				{
					endIndex = inputText.indexOf( ConstructorEndStr, index );
					
					if ( endIndex == -1 )
					{
						break;
					}
					var blockString:String = inputText.substring(index, endIndex + ConstructorEndStr.length);

					if ( avatar.spriteEntry && avatar.spriteEntry.constructorText.length )
					{
						var constructor:String = inputText.substring(index, endIndex);
						inputText = inputText.replace( blockString, avatar.spriteEntry.constructorText );
					}
					else
					{
						var replaceString:String = inputText.substring(index + ConstructorStartStr.length, endIndex );
						inputText = inputText.replace( blockString, replaceString );
					}
				}
			}
			
			// Links coming from other objects...
			while ( (index = inputText.indexOf(LinksFromLoopStr)) != -1 )
			{
				var linkIndex:int = index + LinksFromLoopStr.length;
				endIndex = inputText.indexOf( LinksLoopEndStr, index );
				
				if ( endIndex == -1 )
				{
					break;
				}
				blockString = inputText.substring(index, endIndex + LinksLoopEndStr.length);

				var sub:String = inputText.substring(linkIndex, endIndex);
				var linkList:String = "";
				for each( var link:AvatarLink in avatar.linksFrom )
				{
					var newLinkText:String = sub;
					newLinkText = ReplaceKeyword(newLinkText, "%linkfromid%", linkIds[link.fromAvatar]);
					newLinkText = ReplaceKeyword(newLinkText, "%linktoid%", linkIds[link.toAvatar]);
					// This is not guaranteed to exist at the time of parsing.
					newLinkText = ReplaceKeyword(newLinkText, "%getlinkfromstr%", storedAvatarStrings[link.fromAvatar] );
					newLinkText = ReplaceKeyword(newLinkText, "%getlinktostr%", storedAvatarStrings[link.toAvatar] );
					linkList += newLinkText;
				}
				inputText = inputText.replace( blockString, linkList);
			}
			// Links going to other objects...
			while ( (index = inputText.indexOf(LinksToLoopStr)) != -1 )
			{
				linkIndex = index + LinksToLoopStr.length;
				endIndex = inputText.indexOf( LinksLoopEndStr, index );
				
				if ( endIndex == -1 )
				{
					break;
				}
				blockString = inputText.substring(index, endIndex + LinksLoopEndStr.length);

				sub = inputText.substring(linkIndex, endIndex);
				linkList = "";
				for each( link in avatar.linksTo )
				{
					newLinkText = sub;
					newLinkText = ReplaceKeyword(newLinkText, "%linkfromid%", linkIds[link.fromAvatar]);
					newLinkText = ReplaceKeyword(newLinkText, "%linktoid%", linkIds[link.toAvatar]);
					// This is not guaranteed to exist at the time of parsing.
					newLinkText = ReplaceKeyword(newLinkText, "%getlinkfromstr%", storedAvatarStrings[link.fromAvatar] );
					newLinkText = ReplaceKeyword(newLinkText, "%getlinktostr%", storedAvatarStrings[link.toAvatar] );
					linkList += newLinkText;
				}
				inputText = inputText.replace( blockString, linkList);
			}
			inputText = ReplaceKeyword(inputText, "%linkid%", linkIds[avatar]);
			
			// Handle the common counter...
			inputText = ParseSequentialKeywords(inputText, CounterStr, counterCb, CounterIncStr, counterIncCb);
			function counterCb(input:String, counterIndex:int):String
			{
				return input.replace(CounterStr, avatarCounter );  
			}
			function counterIncCb(input:String, counterIndex:int):String
			{
				avatarCounter++;
				return input.replace(CounterIncStr, "" );  
			}
			
			// Handle the custom counters...
			inputText = ParseSequentialKeywords(inputText, CustomCounterStr, customCounterCb, CustomCounterIncStr, customCounterIncCb);
			function customCounterCb(input:String, counterIndex:int):String
			{
				input = input.replace(CustomCounterStr, "" );
				var endIndex:int = input.indexOf("%", counterIndex);
				if ( endIndex != -1 )
				{
					var countername:String = input.substring(counterIndex, endIndex);
					if ( !( countername in customCounters ) )
					{
						customCounters[ countername ] = 0;
					}
					input = input.replace( countername + "%", customCounters[countername] );
				}
				return input;
			}
			function customCounterIncCb(input:String, counterIndex:int):String
			{
				input = input.replace(CustomCounterIncStr, "" );
				var endIndex:int = input.indexOf("%", counterIndex);
				if ( endIndex != -1 )
				{
					var countername:String = input.substring(counterIndex, endIndex);
					if ( countername in customCounters )
					{
						customCounters[ countername ]++;
					}
					else
					{
						customCounters[ countername ] = 0;
					}
					input = input.replace( countername + "%", "" );
				}
				return input;
			}
			
			while ( ( index = inputText.indexOf(ConstructorStr) ) != -1 )
			{
				inputText = inputText.replace(ConstructorStr, "");
				endIndex = inputText.indexOf("%", index );
				if ( endIndex != -1 )
				{
					if ( avatar.spriteEntry && avatar.spriteEntry.constructorText.length )
					{
						constructor = inputText.substring(index, endIndex);
						inputText = inputText.replace( constructor + "%", avatar.spriteEntry.constructorText );
					}
					else
					{
						// Remove the final %
						inputText = inputText.slice(0, endIndex) + inputText.slice(endIndex + 1, inputText.length);
					}
				}
			}

			var xpos:Number = 0;
			var ypos:Number = 0;
			if ( !(avatar is PathObject) )
			{
				if ( exportSpritePosType == ExportSpritePosType_Center )
				{
					xpos = avatar.width * 0.5;
					ypos = avatar.height * 0.5;
				}
				else if ( exportSpritePosType == ExportSpritePosType_Anchor )
				{
					xpos = avatar.GetAnchor().x * avatar.scale.x;
					ypos = avatar.GetAnchor().y * avatar.scale.y;
				}
				else if ( exportSpritePosType == ExportSpritePosType_BoundsTopLeft && avatar.spriteEntry )
				{
					xpos = avatar.spriteEntry.Bounds.x * avatar.scale.x;
					ypos = avatar.spriteEntry.Bounds.y * avatar.scale.x;
				}
			}
			// ExportSpritePosType_TopLeft is the default, which equates to offsets of 0 on both axes.
			xpos += avatar.x;
			ypos += avatar.y;
			
			var angle:Number = Misc.ModulateAngle(avatar.angle);
			
			if ( ExporterData.exportRotatedSpritePos && angle != 0 )
			{
				var mat:Matrix = avatar.GetTransformMatrixForRealPosToDrawnPos( avatar, angle );
				var pt:Point = new Point(xpos, ypos);
				pt = mat.transformPoint(pt);
				xpos = pt.x;
				ypos = pt.y;
			}			
			
			inputText = ReplaceKeyword(inputText,"%xpos%", xpos.toFixed(floatPrecision) )
			inputText = ReplaceKeyword(inputText,"%ypos%", ypos.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%zpos%", (-avatar.z).toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%degrees%", angle.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%radians%", ((angle * Math.PI )/180).toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%scalex%", avatar.scale.x.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%scaley%", avatar.scale.y.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%width%", avatar.width.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%height%", avatar.height.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText,"%class%", classname );
			inputText = ReplaceKeyword(inputText,"%anchorx%", anchor.x.toString() );
			inputText = ReplaceKeyword(inputText,"%anchory%", anchor.y.toString() );
			inputText = ReplaceKeyword(inputText,"%guid%", avatar.GetGUID() );
			inputText = ReplaceKeyword(inputText,"%flipped%", String(avatar.Flipped) );
			inputText = ReplaceKeyword(inputText,"%boundsx%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.x) : 0) );
			inputText = ReplaceKeyword(inputText,"%boundsy%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.y) : 0) );
			inputText = ReplaceKeyword(inputText,"%boundswidth%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.width) : 0) );
			inputText = ReplaceKeyword(inputText,"%boundsheight%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.height) : 0) );
			inputText = ReplaceKeyword(inputText,"%boundsright%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.right) : 0) );
			inputText = ReplaceKeyword(inputText,"%boundsbottom%", String(avatar.spriteEntry ? (int)(avatar.spriteEntry.Bounds.bottom) : 0) );
			
			if ( avatar.spriteEntry && avatar.isTileSprite && avatar.TileDims || avatar.TileOrigin)
			{
				inputText = ReplaceKeyword(inputText,"%tilex%", String(avatar.TileOrigin ? avatar.TileOrigin.x : avatar.spriteEntry.TileOrigin.x ) );
				inputText = ReplaceKeyword(inputText,"%tiley%", String(avatar.TileOrigin ? avatar.TileOrigin.y : avatar.spriteEntry.TileOrigin.y ) );
				inputText = ReplaceKeyword(inputText,"%tilewid%", String(avatar.TileDims ? avatar.TileDims.x : avatar.width ) );
				inputText = ReplaceKeyword(inputText,"%tileht%", String(avatar.TileDims ? avatar.TileDims.y : avatar.height ) );
			}
			else
			{
				inputText = ReplaceKeyword(inputText,"%tilex%", String(0) );
				inputText = ReplaceKeyword(inputText, "%tiley%", String(0) );
				inputText = ReplaceKeyword(inputText,"%tilewid%", String(avatar.width ) );
				inputText = ReplaceKeyword(inputText,"%tileht%", String(avatar.height ) );
			}
			if ( inputText.indexOf("%realx%") || inputText.indexOf("%realy%") )
			{
				var masterLayer:LayerMap = null;
				if ( avatar.layer.AlignedWithMasterLayer
					&& ( masterLayer = avatar.layer.parent.FindMasterLayer() ) )
				{
					var basePos:FlxPoint = new FlxPoint;
					avatar.GetIsoBasePos(basePos);
					masterLayer.map.GetTileInfo(basePos.x - masterLayer.map.x, basePos.y - masterLayer.map.y, basePos, null, true);
					// Want to be in the center of the tile so shift it back by half a tile.
					if ( !masterLayer.map.xStagger )
					{
						basePos.x -= 0.5;
						basePos.y -= 0.5;
					}
					inputText = ReplaceKeyword(inputText,"%realx%", String(basePos.x.toFixed(floatPrecision) ) );
					inputText = ReplaceKeyword(inputText,"%realy%", String(basePos.y.toFixed(floatPrecision) ) );
				}
				else
				{
					inputText = ReplaceKeyword(inputText,"%realx%", String(xpos.toFixed(floatPrecision) ) );
					inputText = ReplaceKeyword(inputText,"%realy%", String(ypos.toFixed(floatPrecision) ) );
				}
			}
			
			inputText = ReplaceKeyword(inputText, "%name%", "\"" + ( avatar.spriteEntry ? avatar.spriteEntry.name : "" ) + "\"" );
			inputText = ReplaceKeyword(inputText,"%spritename%", ( avatar.spriteEntry ? avatar.spriteEntry.name : "" ) );
			inputText = ReplaceKeyword(inputText,"%scrollx%", avatar.scrollFactor.x.toFixed(floatPrecision) );
			inputText = ReplaceKeyword(inputText, "%scrolly%", avatar.scrollFactor.y.toFixed(floatPrecision) );
			var frameNum:int = avatar.spriteEntry ? avatar.spriteEntry.previewIndex : 0;
			if ( avatar.animIndex != -1 )
				frameNum = avatar.animIndex;
			inputText = ReplaceKeyword(inputText,"%frame%", frameNum.toString() );
			
			
			inputText = GetTextForProperties(inputText, avatar.properties, currentPropTypes );
			
			storedString = "";
			
			// Must do these last to avoid accounting for extra % symbols.
			inputText = ParseSequentialKeywords(inputText, StoreStr, storeCb, "%get%", getCb);
			function storeCb(input:String,storeIndex:int):String
			{
				// Store the avatar string.
				input = input.replace(StoreStr, "" );
				var endIndex:int = input.indexOf("%", storeIndex);
				if ( endIndex != -1 )
				{
					storedString = input.substring(storeIndex, endIndex);
					input = input.replace( storedString + "%", "" );
				}
				storedAvatarStrings[ avatar ] = storedString;
				return input;
			}
			function getCb(input:String,getIndex:int):String
			{
				input = input.replace("%get%", storedString );  
				return input;
			}
			
			inputText = ReplaceKeyword(inputText,"%getchild%", ( avatar.attachment ) ? storedAvatarStrings[ avatar.attachment.Child ] : "" );  
			inputText = ReplaceKeyword(inputText,"%getparent%", ( avatar.attachment ) ? storedAvatarStrings[ avatar.attachment.Parent ] : "" );  
			inputText = ReplaceKeyword(inputText,"%attachedsegment%", String(( avatar.attachment ) ? avatar.attachment.segmentNumber.toFixed(floatPrecision) : 0) );  
			inputText = ReplaceKeyword(inputText,"%attachedsegment_t%", String(( avatar.attachment ) ? avatar.attachment.percentInSegment.toFixed(floatPrecision) : 0) );
			return inputText;
		}
		
		private static function ParseSeparator( inputText:String, isSeparatorValid:Boolean ):String
		{
			var index:int;
			
			while ( ( index = inputText.indexOf(CustomSeparator) ) != -1 )
			{
				inputText = inputText.replace(CustomSeparator, "");
				var endIndex:int = inputText.indexOf("%", index );
				if ( endIndex != -1 )
				{
					if ( isSeparatorValid )
					{
						// Remove the final %
						inputText = inputText.slice(0, endIndex) + inputText.slice(endIndex + 1, inputText.length);
					}
					else
					{
						var keyword:String = inputText.substring(index, endIndex);
						inputText = inputText.replace( keyword + "%", "" );
					}
				}
			}
			return inputText;
		}
		
		// Parse an if block.
		private static function ParseIfBlock( inputText:String, ifKeyword:String, endifKeyword:String, isTrue:Boolean ):String
		{
			var index:int;
			var endIndex:int;
			while ( (index = inputText.indexOf(ifKeyword) ) != -1 )
			{
				endIndex = inputText.indexOf(endifKeyword);
				if ( endIndex == -1 )
				{
					break;
				}
				
				if ( isTrue )
				{
					inputText = inputText.replace( inputText.substring( endIndex, endIndex + endifKeyword.length ), "" );
					inputText = inputText.replace( inputText.substring( index, index + ifKeyword.length ), "" );
				}
				else
				{
					inputText = inputText.replace( inputText.substring(index, endIndex + endifKeyword.length ), "");
				}
			}
			return inputText;
		}
		
		// Parse a loop
		// Functions must be callback(inputText,data):String
		private static function ParseLoopBlock( inputText:String, loopKeyword:String, endLoopKeyword:String, loopCb:Function, loopCbData:Object ):String
		{
			var output:String = inputText;
			var index:int;
			var endIndex:int;
			var blockString:String;
			
			while ( (index = output.indexOf(loopKeyword)) != -1 )
			{
				var frameIndex:int = index + loopKeyword.length;
				endIndex = output.indexOf( endLoopKeyword, index );
				
				if ( endIndex == -1 )
				{
					break;
				}
				blockString = output.substring(index, endIndex + endLoopKeyword.length);

				var sub:String = output.substring(frameIndex, endIndex);
				var newText:String = loopCb(sub, loopCbData );
				
				output = output.replace( blockString, newText);
			}
			
			return output;
		}
		
		// Parses 2 keywords that require ordered replacement.
		// Functions must be callback(inputText,index):String
		private static function ParseSequentialKeywords( inputText:String, keyword1:String, function1:Function, keyword2:String, function2:Function):String
		{
			var index1:int = inputText.indexOf(keyword1);
			var index2:int = inputText.indexOf(keyword2);
			while ( index1 != -1 || index2 != -1 )
			{
				if( index1 != -1 && ( index1 < index2 || index2 == -1 ) )
				{
					inputText = function1( inputText, index1 );
					index1 = inputText.indexOf(keyword1);
					index2 = inputText.indexOf(keyword2);	// Must recalc because newText has changed.
				}
				if( index2 != -1 && ( index2 < index1 || index1 == -1 ) )
				{  
					inputText = function2( inputText, index2 );
					index2 = inputText.indexOf(keyword2);
					index1 = inputText.indexOf(keyword1);	// Must recalc because newText has changed.
				}
			}
			return inputText;
		}
		
		public static function CreateTextForSpriteClasses( spriteText:String, tileSpriteText:String, groupText:String, separ:String, groupEndText:String, indentText:String, sprite:SpriteEntry = null, baseDirectory:String = "" ):String
		{
			if ( sprite == null )
			{
				sprite = App.getApp().spriteData[0];
			}
			
			spriteCounter = 0;
			
			return CreateTextForSpriteClassesInternal( spriteText, tileSpriteText, groupText, separ, groupEndText, indentText, "", sprite, baseDirectory );
		}
		
		private static function CreateTextForSpriteClassesInternal( spriteText:String, tileSpriteText:String, groupText:String, separ:String, groupEndText:String, indentText:String, currentIndent:String, sprite:SpriteEntry, baseDirectory:String):String
		{
			var oldExportHiddenProperties:Boolean = exportHiddenProperties;
			exportHiddenProperties = true;
			var output:String = "";
			
			var newText:String = "";
			if ( spriteCounter > 0 )
			{
				output += separ;
			}
			if ( !sprite.children || sprite.children.length == 0 )
			{
				newText = sprite.IsTileSprite ? tileSpriteText : spriteText;
			}
			else
			{
				newText = groupText;
			}
			newText = ParseSprite( newText, currentIndent, sprite, baseDirectory );
			output += newText;
			spriteCounter++;
			
			if( sprite.children )
			{
				var newIndent:String = currentIndent + indentText;
				for ( var i:uint = 0; i < sprite.children.length; i++ )
				{
					var entry:SpriteEntry = sprite.children[i];
					
					output += CreateTextForSpriteClassesInternal( spriteText, tileSpriteText, groupText, separ, groupEndText, indentText, newIndent, entry, baseDirectory );
				}
				
				newText = groupEndText;
				newText = ParseSprite(newText, currentIndent, sprite, baseDirectory );
				output += newText;
			}
			
			exportHiddenProperties = oldExportHiddenProperties;
			
			return output;
		}
		
		public static function ParseSprite( spriteText:String, indentText:String, sprite:SpriteEntry, baseDirectory:String = ""):String
		{
			spriteText = ReplaceKeyword(spriteText,"%indent%", indentText ); 
			spriteText = ReplaceKeyword(spriteText,"%class%", sprite.className );  
			spriteText = ReplaceKeyword(spriteText, "%name%", sprite.name );
			if ( sprite.imageFile && sprite.imageFile.exists )
			{
				spriteText = ReplaceKeyword(spriteText,"%imagefile%", sprite.imageFile.nativePath );
				spriteText = ReplaceKeyword(spriteText, "%imagefilename%", sprite.imageFile.name );
				if ( baseDirectory && baseDirectory.length )
				{
					try
					{
						var sourceFile:File = new File(baseDirectory);
						var path:String = sourceFile.getRelativePath( sprite.imageFile, true );
						if ( path )
						{
							spriteText = ReplaceKeyword(spriteText, "%imagefilerelative%", path );
						}
					}
					catch (error:Error){}
				}
			}
			spriteText = ReplaceKeyword(spriteText,"%frame%", (int)(sprite.previewIndex) );
			
			spriteText = ReplaceKeyword(spriteText,"%width%", String(sprite.previewBitmap ? sprite.previewBitmap.width : 0));
			spriteText = ReplaceKeyword(spriteText,"%height%", String(sprite.previewBitmap ? sprite.previewBitmap.height : 0) );
			spriteText = ReplaceKeyword(spriteText,"%anchorx%", sprite.Anchor.x.toString() );
			spriteText = ReplaceKeyword(spriteText,"%anchory%", sprite.Anchor.y.toString() );
			spriteText = ReplaceKeyword(spriteText,"%boundsx%", (int)(sprite.Bounds.x) );
			spriteText = ReplaceKeyword(spriteText,"%boundsy%", (int)(sprite.Bounds.y) );
			spriteText = ReplaceKeyword(spriteText,"%boundswidth%", (int)(sprite.Bounds.width) );
			spriteText = ReplaceKeyword(spriteText,"%boundsheight%", (int)(sprite.Bounds.height)  );
			spriteText = ReplaceKeyword(spriteText,"%boundsright%", (int)(sprite.Bounds.right) );
			spriteText = ReplaceKeyword(spriteText,"%boundsbottom%", (int)(sprite.Bounds.bottom) );
			spriteText = ReplaceKeyword(spriteText,"%istile%", String(sprite.IsTileSprite) );  
			spriteText = ReplaceKeyword(spriteText,"%tilex%", (int)(sprite.TileOrigin.x) );  
			spriteText = ReplaceKeyword(spriteText,"%tiley%", (int)(sprite.TileOrigin.y) );  
			
			// Do constructor text last so we don't replace any keywords in that!
			spriteText = ReplaceKeyword(spriteText, "%constructortext%", sprite.constructorText );
			spriteText = ReplaceKeyword(spriteText,"%creationtext%", sprite.creationText );
			
			spriteText = GetTextForProperties(spriteText, sprite.properties, currentPropTypes); 
			
			spriteText = GetTextForAnimShapes(spriteText, sprite);
			
			return spriteText;
		}
		
		public static function GetTextForAnimShapes( inputText:String, sprite:SpriteEntry ):String
		{
			var output:String = inputText;
			var index:int;
			var endIndex:int;
			var blockString:String;
			var frameList:String;
			
			// Look for shape frame loops.
			
			output = ParseIfBlock( output, IfAnimsOrShapesStr, EndIfAnimsOrShapesStr, ( sprite.shapes.numFrames > 0 || sprite.anims.length > 0 ) );
			output = ParseIfBlock( output, IfShapesStr, EndIfShapesStr, ( sprite.shapes.numFrames > 0 ) );
			output = ParseLoopBlock(output, SpriteFrameLoopStr, SpriteFrameLoopEndStr, frameLoop, null );
			
			function frameLoop(loopText:String, data:Object):String
			{
				var frameOutput:String = "";
				for (var key:Object in sprite.shapes.frames )
				{
					var shapeList:SpriteShapeList = sprite.shapes.frames[key];
					if ( shapeList.shapes.length )
					{
						var newFrameText:String = loopText;
						var frameNum:int = key as int;
						newFrameText = ReplaceKeyword(newFrameText, "%frame%", String(frameNum) );
						newFrameText = ReplaceKeyword(newFrameText, "%frame1%", String(frameNum + 1) );
						
						newFrameText = ParseLoopBlock(newFrameText, ShapeLoopStr, ShapeLoopEndStr, shapeLoop, null );
						
						function shapeLoop(shapeLoopText:String, data:Object):String
						{
							var shapeOutput:String = "";
							for ( var i:int = 0; i < shapeList.shapes.length; i++ )
							{
								var newShapeText:String = shapeLoopText;
								var shape:SpriteShapeData = shapeList.shapes[i];
								var type:String;
								if ( shape.type == SpriteShapeData.SHAPE_BOX )
									type = "box";
								else if ( shape.type == SpriteShapeData.SHAPE_CIRCLE )
									type = "circle";
								else if ( shape.type == SpriteShapeData.SHAPE_POINT )
									type = "point";
								newShapeText = ReplaceKeyword(newShapeText, "%type%", type );
								newShapeText = ReplaceKeyword(newShapeText, "%TYPE%", type.toUpperCase() );
								newShapeText = ParseIfBlock(newShapeText, IfCircleStr, EndIfCircleStr, shape.type == SpriteShapeData.SHAPE_CIRCLE );
								newShapeText = ParseIfBlock(newShapeText, IfBoxStr, EndIfBoxStr, shape.type == SpriteShapeData.SHAPE_BOX );
								newShapeText = ParseIfBlock(newShapeText, IfPointStr, EndIfPointStr, shape.type == SpriteShapeData.SHAPE_POINT );
								newShapeText = ReplaceKeyword(newShapeText, "%shapenum%", String(i) );
								newShapeText = ReplaceKeyword(newShapeText, "%xpos%", String(shape.x) );
								newShapeText = ReplaceKeyword(newShapeText, "%ypos%", String(shape.y) );
								newShapeText = ReplaceKeyword(newShapeText, "%radius%", String(shape.radius) );
								newShapeText = ReplaceKeyword(newShapeText, "%wid%", String(shape.width) );
								newShapeText = ReplaceKeyword(newShapeText, "%ht%", String(shape.height) );
								newShapeText = ReplaceKeyword(newShapeText, "%shapename%", shape.name );
								newShapeText = ParseSeparator(newShapeText, i + 1 < shapeList.shapes.length );
								shapeOutput += newShapeText;
							}
							return shapeOutput;
						}
						
						frameOutput += newFrameText;
					}
				}
				
				return frameOutput;
			}
			
			// Look for anim loops
			output = ParseIfBlock( output, IfSpriteAnimsStr, EndIfSpriteAnimsStr,( sprite.anims.length > 0 ) );
			output = ParseLoopBlock(output, SpriteAnimLoopStr, SpriteAnimLoopEndStr, animLoop, null );
			
			function animLoop(loopText:String, data:Object):String
			{
				var animOutput:String = "";
				var animNum:int = 0;
				for each (var anim:TileAnim in sprite.anims)
				{
					var newAnimText:String = loopText;
					newAnimText = ReplaceKeyword(newAnimText, "%animnum%", String(animNum) );
					newAnimText = ReplaceKeyword(newAnimText, "%fps%", anim.fps.toFixed(floatPrecision) );
					newAnimText = ReplaceKeyword(newAnimText, "%animname%", anim.name );
					newAnimText = ReplaceKeyword(newAnimText, "%numframes%", String(anim.tiles.length) );
					newAnimText = ReplaceKeyword(newAnimText, "%looped%", String(anim.looped) );
					
					newAnimText = ParseLoopBlock(newAnimText, AnimFrameLoopStr, AnimFrameLoopEndStr, animFrameLoop, null );
					
					function animFrameLoop(animFrameLoopText:String, data:Object):String
					{
						var animFrameOutput:String = "";
						for ( var j:int = 0; j < anim.tiles.length; j++ )
						{
							var newFrameText:String = animFrameLoopText;
							newFrameText = ReplaceKeyword(newFrameText, "%frame%", String(j) );
							newFrameText = ReplaceKeyword(newFrameText, "%frame1%", String(j+1) );
							newFrameText = ReplaceKeyword(newFrameText, "%tileid%", String(anim.tiles[j]) );
							newFrameText = ParseSeparator(newFrameText, j + 1 < anim.tiles.length );
							animFrameOutput += newFrameText;
						}
						return animFrameOutput;
					}
					
					animNum++;
					animOutput += newAnimText;
				}
				
				return animOutput;
			}
			
			return output;
		}
		
		private static function ReplaceKeyword( source:String, keyword:String, replaceText:String):String
		{
			while (source.indexOf(keyword) != -1)
			{  
				source = source.replace(keyword, replaceText );  
			}
			return source;
		}
		
		public static function WriteFile( filepath:String, data:String ):void
		{
			try
			{
				var stream:FileStream = new FileStream();
				var file:File = new File(filepath);
				var didExist:Boolean = file.exists;
				var oldDate:Date = null;
				if ( didExist )
				{
					oldDate = file.modificationDate;
				}
				stream.open(file, FileMode.WRITE);
				stream.addEventListener(IOErrorEvent.IO_ERROR, FileWriteError); 
				stream.writeUTFBytes(data);
				stream.close();
				if ( file.exists && (!didExist || ObjectUtil.dateCompare(file.modificationDate, oldDate)!=0 ) )
				{
					ExporterPopup.ExporterWindow.LogWriteLine("Wrote to file:" + filepath);
				}
				else
				{
					ExporterPopup.ExporterWindow.LogWriteLine("<font color=\"#FF0000\">Failed to write to file:" + filepath + "</font>");
				}
				
				function FileWriteError(event:IOErrorEvent):void
				{
					ExporterPopup.ExporterWindow.LogWriteLine("<font color=\"#FF0000\">Error when writing to file:" + filepath + ": " + event.text + "</font>");
					ExporterPopup.ExporterWindow.fileErrors.push(event.text);
				}
			}
			catch (error:Error)
			{
				ExporterPopup.ExporterWindow.LogWriteLine("<font color=\"#FF0000\">Error when writing to file:" + filepath + ":" + error.message + "</font>");
				ExporterPopup.ExporterWindow.fileErrors.push(filepath);
			}
			
		}
		
		private static function GetRelativePathInternal( inputText:String, baseDirectory:String, file:File, keyword:String):String
		{
			if ( baseDirectory && baseDirectory.length )
			{
				try
				{
					var sourceFile:File = new File(baseDirectory);
					var path:String = sourceFile.getRelativePath( file, true );
					if ( path )
					{
						inputText = ReplaceKeyword(inputText, keyword, path );
					}
				}
				catch (error:Error){}
			}
			return inputText;
		}
		
		public static function GetRelativePath(basePath:String, dest:String, throwError:Boolean = true):String
		{
			var res:String = "";
			try
			{
				var sourceFile:File = new File(basePath);
				var destFile:File = new File(dest);
				res = sourceFile.getRelativePath( destFile, true );
				if ( !res )
				{
					throw new Error();
				}
			}
			catch (error:Error)
			{
				res = throwError ? ("***GetRelativePath - invalid arguments : source:String = " + basePath + ", dest:String = " + dest + "***" ) : "";
			}
			return res;
		}
		
		public static function CreateTextForFontsInGroup(group:Object, fontText:String ):String
		{
			var text:String = "";
			
			var groupLayer:LayerGroup = group as LayerGroup;
			
			if ( groupLayer == null )
			{
				return text;
			}
			
			// Build a list of all unique fonts within this group
			var fontlist:Array = [];
			for ( var layernum:uint = 0; layernum < groupLayer.children.length; layernum++ )
			{
				var shapeLayer:LayerShapes = groupLayer.children[layernum] as LayerShapes;
				if ( shapeLayer != null )
				{
					for ( var i:uint = 0; i < shapeLayer.sprites.members.length; i++ )
					{
						var textobj:TextObject = shapeLayer.sprites.members[i] as TextObject;
						if ( textobj )
						{
							if ( fontlist.indexOf(textobj.text.font)==-1 )
							{
								fontlist.push(textobj.text.font);
							}
						}
					}
				}
			}
			
			for ( i = 0; i < fontlist.length; i++ )
			{
				text = text + ReplaceKeyword(fontText, "%font%", fontlist[i] );
			}
			
			return text;
		}
		
		//{ region Interface
		
		public static function AddHtmlTextLabel( text:String):void
		{
			var textobj:TextArea = new TextArea();
			textobj.htmlText = text;
			textobj.percentWidth = 100;
			textobj.editable = false;
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(textobj);
		}
		
		public static function AddDropDown( labelText:String, id:String, values:Array, defaultValue:String, tooltip:String ):void
		{
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			var combo:MyComboBox = new MyComboBox();
			label.text = labelText;
			
			combo.id = id;
			combo.dataProvider = values;
			combo.selectedValue = defaultValue;
			
			hbox.addChild(label);
			hbox.addChild(combo);
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(hbox);
			ExporterPopup.customControls.push(combo);
			if ( tooltip && tooltip.length )
			{
				combo.toolTip = tooltip;
			}
		}
		
		public static function AddCheckbox( text:String, id:String, tickedByDefault:Boolean, tooltip:String = null ):void
		{
			var checkbox:CheckBox = new CheckBox();
			checkbox.id = id;
			checkbox.label = text;
			checkbox.selected = tickedByDefault;
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(checkbox);
			ExporterPopup.customControls.push(checkbox);
			if ( tooltip && tooltip.length )
			{
				checkbox.toolTip = tooltip;
			}
		}
		
		public static function AddNumberInput( labelText:String, defaultValue:Number, id:String, minValue:Number, maxValue:Number, stepValue:Number, tooltip:String = null):void
		{
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			var input:NumericStepper = new NumericStepper();
			label.text = labelText;
			input.id = id;
			input.value = defaultValue;
			input.minimum = minValue;
			input.maximum = maxValue;
			input.stepSize = stepValue;
			hbox.addChild(label);
			hbox.addChild(input);
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(hbox);
			ExporterPopup.customControls.push(input);
			if ( tooltip && tooltip.length )
			{
				input.toolTip = tooltip;
			}
		}
		
		public static function AddTextInput( labelText:String, defaultText:String, id:String, enabled:Boolean, tooltip:String = null ):void
		{
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			var input:TextInput = new TextInput();
			label.text = labelText;
			input.id = id;
			input.text = defaultText;
			input.enabled = enabled;
			hbox.addChild(label);
			hbox.addChild(input);
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(hbox);
			ExporterPopup.customControls.push(input);
			if ( tooltip && tooltip.length )
			{
				input.toolTip = tooltip;
			}
		}
		
		public static function AddMultiLineTextInput( labelText:String, defaultText:String, id:String, height:uint, enabled:Boolean, tooltip:String = null ):void
		{
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			var input:TextArea = new TextArea();
			label.text = labelText;
			input.id = id;
			input.text = defaultText;
			input.enabled = enabled;
			input.percentWidth = 100;
			input.height = height;
			hbox.addChild(label);
			hbox.addChild(input);
			hbox.percentWidth = 100;
			ExporterPopup.ExporterWindow.ExporterSettings.addChild(hbox);
			ExporterPopup.customControls.push(input);
			if ( tooltip && tooltip.length )
			{
				input.toolTip = tooltip;
			}
		}
		
		public static function AddBrowsePath( text:String, id:String, enabled:Boolean, tooltip:String = null ):void
		{
			var hbox:HBox = new HBox();
			var label:Label = new Label();
			var input:TextInput = new TextInput();
			var button:Button = new Button();

			label.text = text;
			button.label = "...";
			input.id = id;
			input.enabled = enabled;

			ExporterPopup.customControls.push(input);
			ExporterPopup.browsers.push(input);

			button.data = input;
			button.addEventListener("click", browserFolderEvent, false, 0, true);
			

			ExporterPopup.ExporterWindow.ExporterSettings.addChild(hbox);
			hbox.addChild(label);
			hbox.addChild(input);
			hbox.addChild(button);
			
			if ( tooltip && tooltip.length )
			{
				input.toolTip = tooltip;
			}
		}
		
		private static function browserFolderEvent(event:Event):void
		{
			var path:String = event.target.data.text;
			try
			{
				if ( ExporterPopup.UsingRelativePaths )
				{
					var projectDir:File = App.getApp().GetCurrentFile().parent;
					var file:File = projectDir.resolvePath( path );
					path = file.nativePath;
				}
			}
			catch ( error:Error)
			{
			}
			BrowseLocation(event.target.data, path);
		}
			
		public static function BrowseLocation( control:Object, defaultPath:String ):File
		{
			var fileChooser:File = null;
			
			try
			{
				fileChooser = new File(defaultPath);
			}
			catch( error:Error )
			{
			}
			if ( !fileChooser || !fileChooser.exists )
			{
				fileChooser = new File(Global.CurrentProjectFile.url);
			}

			browseLocationControl = control;
			if ( !browseLocationControl )
			{
				return null;
			}

			fileChooser.browseForDirectory("Select Path" );
			fileChooser.addEventListener(Event.SELECT, selectBrowseLocation, false, 0, true);

			fileChooser.addEventListener(Event.ACTIVATE, ExporterPopup.ExporterWindow.browserOpen,false,0,true);
			fileChooser.addEventListener(Event.CANCEL, ExporterPopup.ExporterWindow.fileChooserClosed,false,0,true);

			return fileChooser;
		}
		
		private static function selectBrowseLocation(event:Event):void
		{
			var file:File = event.target as File;
			
			var pathText:String = file.nativePath;
			if ( ExporterPopup.UsingRelativePaths )
			{
				try
				{
					var projectDir:File = App.getApp().GetCurrentFile().parent;
					pathText = projectDir.getRelativePath(file, true);
				}
				catch (error:Error)
				{
				}
			}
			try
			{
				browseLocationControl.value = pathText;
			}
			catch(error:Error)
			{
				browseLocationControl.text = pathText;
			}
			
			browseLocationControl = null;
			ExporterPopup.ExporterWindow.fileChooserClosed(event);
		}
		
		//} endregion Interface
		
	}

}
