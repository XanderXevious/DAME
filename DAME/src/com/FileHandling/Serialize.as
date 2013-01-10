package com.FileHandling 
{
	import com.Editor.Bookmark;
	import com.Editor.EditorTypeTileMatrix;
	import com.Editor.TileEditorLayerEntry;
	import com.Editor.TileEditorRowEntry;
	import com.Editor.TileEditorTileEntry;
	import com.EditorState;
	import com.Game.AvatarLink;
	import com.Game.EditorAvatar;
	import com.Game.PathEvent;
	import com.Game.PathNode;
	import com.Game.PathObject;
	import com.Game.ShapeObject;
	import com.Game.SpriteTrailObject;
	import com.Game.TextObject;
	import com.Layers.LayerAvatarBase;
	import com.Layers.LayerEntry;
	import com.Layers.LayerGroup;
	import com.Layers.LayerImage;
	import com.Layers.LayerMap;
	import com.Layers.LayerPaths;
	import com.Layers.LayerSprites;
	import com.Layers.LayerShapes;
	import com.Operations.HistoryStack;
	import com.photonstorm.flixel.FlxBitmapFont;
	import com.Properties.CustomPropertyFilterType;
	import com.Properties.CustomPropertyType;
	import com.Properties.CustomPropertyValue;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.ImageBank;
	import com.Properties.PropertyBase;
	import com.Properties.PropertyData;
	import com.Properties.PropertyType;
	import com.Tiles.SpecialTileRowData;
	import com.Tiles.SpriteEntry;
	import com.Tiles.StackTileInfo;
	import com.Tiles.TileAnim;
	import com.Tiles.TileConnectionList;
	import com.Tiles.TileConnections;
	import com.Tiles.TileMatrixData;
	import com.UI.TileConnectionGrid;
	import com.UI.TileBrushesWindow;
	import com.Utils.Global;
	import com.Utils.Misc;
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.utils.clearInterval;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setInterval;
	import mx.collections.ArrayCollection;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import org.flixel.FlxState;
	import XML;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	import flash.xml.XMLDocument;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import com.UI.AlertBox;
	import com.UI.advancedColorPicker;
	import com.UI.SpecialTilesRow;
	
	import com.UI.LogWindow;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Serialize
	{
		static private var numLoadingSprites:uint = 0;
		static private var finishedLoadingSprites:Boolean = true;
		//{ region Saving
		
		static public function SaveProject( file:File, settingsFile:File = null ):void
		{
			var date:Date = new Date;
			//LogWindow.LogWriteLine("");
			//LogWindow.LogWriteLine("Save file at " + date.toString() + " : " + file.url);
			if ( file.exists )
			{
				//LogWindow.LogWriteLine("File already exists. Was last modified at: " + file.modificationDate + " Size = " + file.size + " bytes." );
				try
				{
					var backupFile:File = new File( file.url + ".bak" );
					//LogWindow.LogWriteLine("Begin backup copy to " + backupFile.url);
					file.copyTo( backupFile, true);
					//LogWindow.LogWriteLine("Backup file last modified at: " + backupFile.modificationDate);
				}
				catch(error:Error)
				{
					//LogWindow.LogWriteLine("<font color=\"#FF0000\">Error when writing to file:" + error.message + "</font>");
				}
			}
			if ( settingsFile && settingsFile.exists )
			{
				try
				{
					backupFile = new File( settingsFile.url + ".bak" );
					settingsFile.copyTo( backupFile, true);
				}
				catch(error:Error)
				{
				}
			}
			
			Global.CurrentProjectFile = file;
			Global.RememberFile( file.nativePath );
			
			var newXML:XMLDocument = new XMLDocument();
			var xml:XML = 
				<project>
				</project>;

			XML.prettyIndent = 2;
			
			var app:App = App.getApp();
			 
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			// Define the Namespace (there is only one by default in the application descriptor file)
			var air:Namespace = appXML.namespaceDeclarations()[0];
			var version:String = appXML.air::version;
			xml.appendChild( <version>{ version }</version> );
			xml.appendChild( <bgColor>{ Misc.uintToHexStr6Digits(FlxState.bgColor)} </bgColor> );
			xml.appendChild( <viewPos x={FlxG.scroll.x} y={FlxG.scroll.y}/> );
			xml.appendChild( < firstLayersTop > { Global.DisplayLayersFirstOnTop } </firstLayersTop > );
			
			var spritesXml:XML = < spriteEntries />;
			var settingsXmlData:XML = <project></project>;
			if ( settingsFile )
			{
				var settingsFileName:String = ResolvePath( Global.CurrentProjectFile.parent, settingsFile );
				xml.appendChild( < settingsFile >{ settingsFileName }</settingsFile> );
			}
			
			if ( settingsFile && Global.SaveSpritesSeparately )
			{
				Global.CurrentSettingsFile = settingsFile;
				settingsXmlData.appendChild( spritesXml );
				Global.CurrentProjectFile = settingsFile;
			}
			else
			{
				//Global.SaveSpritesSeparetely = false;
				xml.appendChild( spritesXml );
			}
			OutputSpriteEntries( spritesXml, app.spriteData[0], true );
			Global.CurrentProjectFile = file;
			
			var instances:Vector.<PathInstanceData> = new Vector.<PathInstanceData>();
			
			OutputLinks( xml );
			
			OutputGroups( xml, app, instances );
			
			if ( settingsFile && Global.SaveLayerTemplatesSeparately )
			{
				Global.CurrentProjectFile = settingsFile;
				OutputLayerTemplates(settingsXmlData, app, instances);
				Global.CurrentProjectFile = file;
			}
			else
			{
				OutputLayerTemplates(xml, app, instances );
			}
			
			OutputInstances( xml, instances );
			
			if ( settingsFile && Global.SaveTileMatrixSeparately )
			{
				Global.CurrentProjectFile = settingsFile;
				OutputTileMatrix( settingsXmlData, app );
				Global.CurrentProjectFile = file;
			}
			else
			{
				OutputTileMatrix( xml, app );
			}
			
			if ( settingsFile && Global.SaveTileBrushesSeparately )
			{
				Global.CurrentProjectFile = settingsFile;
				OutputTileBrushes( settingsXmlData );
				Global.CurrentProjectFile = file;
			}
			else
			{
				OutputTileBrushes( xml );
			}
			
			var swatchesXml:XML = < colorSwatches />
			
			for each( var swatch:uint in advancedColorPicker.swatchColors )
			{
				swatchesXml.appendChild( < colour > { swatch } </colour> );
			}
			xml.appendChild( swatchesXml );
			
			OutputBookmarks( xml, app );
			
			Global.SaveColorGrid( xml );
			Global.SaveOptions( xml );
			
			OutputExporterSettings( xml );
			
			if ( settingsFile && Global.SavePropertyTypesSeparately )
			{
				Global.CurrentProjectFile = settingsFile;
				CustomPropertyType.SaveAll( settingsXmlData );
				Global.CurrentProjectFile = file;
			}
			else
			{
				CustomPropertyType.SaveAll( xml );
			}
			
			if ( settingsFile && Global.SaveGuidesSeparately )
			{
				Global.CurrentProjectFile = settingsFile;
				Global.SaveGridSettings( settingsXmlData );
				Global.CurrentProjectFile = file;
			}
			else
			{
				Global.SaveGridSettings( xml );
			}
			
			var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
			outputString += xml.toString();
			outputString = outputString.replace(/\n/g, File.lineEnding);
			
			//LogWindow.LogWriteLine("Xml generated. Now saving.");
			
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);	// Not async as that could cause issues.
			stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
			
			stream.writeUTFBytes(outputString);
			stream.close();
			
			if ( settingsFile )
			{
				outputString = '<?xml version="1.0" encoding="utf-8"?>\n';
				outputString += settingsXmlData.toString();
				outputString = outputString.replace(/\n/g, File.lineEnding);
			
				stream = new FileStream();
				stream.open(settingsFile, FileMode.WRITE);	// Not async as that could cause issues.
				stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
				
				stream.writeUTFBytes(outputString);
				stream.close();
			}
			
			//date = new Date;
			//LogWindow.LogWriteLine("DAME file saved at : " + date.toString() );
			//LogWindow.LogWriteLine("DAME file modification date = " + file.modificationDate );
			//LogWindow.LogWriteLine("DAME file size = " + file.size + " bytes." );
			
			ImageBank.SaveChangedImages();
			
			HistoryStack.RecordSave();
			EditorState.recordSave();
			Global.windowedApp.title = file.name + " - DAME";
			
			//LogWindow.LogWriteLine("Save successful!" );
		}
		
		static private function writeIOErrorHandler(event:IOErrorEvent):void
		{
			//LogWindow.LogWriteLine("File write error: " + event.text );
			AlertBox.Show("Failed to save file: " + event.type, "Error");
		}
		
		static private function OutputExporterSettings( xml:XML ):void
		{
			if ( Global.SaveExporterWithProject )
			{
				Global.ExporterSettings.Save(xml, "exporter");
			}
			if ( Global.ProjectExporterSettings.settings.length )
			{
				Global.ProjectExporterSettings.Save(xml, "projectExporter");
			}
		}
		
		static private function OutputSpriteEntries( xml:XML, data:SpriteEntry, first:Boolean ):void
		{
			var entryXml:XML = null;
			
			if ( data.children )
			{
				if ( !first )
				{
					entryXml = < group name = { data.name } 
								idx = { data.id }
								open = { App.getApp().spriteList.isItemOpen( data ) }
								/> ;
					
					xml.appendChild( entryXml );
				}
				else
				{
					entryXml = xml;
					entryXml[ "@currentId" ] = SpriteEntry.GetEntryCount();
				}
				
				for each( var entry:SpriteEntry in data.children )
				{
					OutputSpriteEntries( entryXml, entry, false );
				}
			}
			else
			{
				var fileref:File = data.imageFile;// new File(data.imageFile);
				var imageFileName:String = ResolvePath( Global.CurrentProjectFile.parent, fileref );
				if ( data.IsTileSprite )
				{
					entryXml = < tileEntry name = { data.name } 
								idx = { data.id }
								className = { data.className }
								image = { imageFileName }
								offsetX = { data.TileOrigin.x }
								offsetY = { data.TileOrigin.y }
								width = { data.previewBitmap ? data.previewBitmap.width : 30 }
								height = { data.previewBitmap ? data.previewBitmap.height : 30 }
								anchorX = { data.Anchor.x }
								anchorY = { data.Anchor.y }
								centerAnchor = { data.CenterAnchor }
								boundsX = { data.Bounds.x }
								boundsY = { data.Bounds.y }
								boundsWidth = { data.Bounds.width }
								boundsHeight = { data.Bounds.height }
								constructor = { data.constructorText }
								creation = { data.creationText }
								exports = { data.Exports }
								canScale = { data.CanScale }
								canRotate = { data.CanRotate }
								surfaceObject = { data.IsSurfaceObject }
								lockRotation = { data.LockRotationTo90Degrees }
								/> ;
				}
				else
				{
					entryXml = < sprite name = { data.name } 
								idx = { data.id }
								className = { data.className }
								image = { imageFileName }
								width = { data.previewBitmap ? data.previewBitmap.width : 30 }
								height = { data.previewBitmap ? data.previewBitmap.height : 30 }
								preview = { data.previewIndex }
								anchorX = { data.Anchor.x }
								anchorY = { data.Anchor.y }
								centerAnchor = { data.CenterAnchor }
								boundsX = { data.Bounds.x }
								boundsY = { data.Bounds.y }
								boundsWidth = { data.Bounds.width }
								boundsHeight = { data.Bounds.height }
								constructor = { data.constructorText }
								creation = { data.creationText }
								exports = { data.Exports }
								canScale = { data.CanScale }
								canRotate = { data.CanRotate }
								surfaceObject = { data.IsSurfaceObject }
								tileIndex = { data.tilePreviewIndex }
								canEditFrames = { data.CanEditFrames }
								lockRotation = { data.LockRotationTo90Degrees }
								/> ;
								
					var tileAnims:Vector.<TileAnim> = data.anims;
					if ( tileAnims && tileAnims.length )
					{
						var tileAnimsXml:XML = < anims />
						entryXml.appendChild( tileAnimsXml );
						for each( var anim:TileAnim in tileAnims )
						{
							anim.Save(tileAnimsXml);
						}
					}
					data.shapes.Save(entryXml);
				}
				xml.appendChild( entryXml );
				OutputProperties(entryXml, data.properties );
				
			}
			if ( App.getApp().spriteList.isItemSelected( data ) )
			{
				entryXml[ "@selected" ] = true;
			}
		}
		
		static private function OutputLayerTemplates( xml:XML, app:App, instances:Vector.<PathInstanceData> ):void
		{
			var templatesXml:XML = < layerTemplates/>;
			xml.appendChild( templatesXml );
			OutputLayers(templatesXml, app.layerTemplates, instances );
		}
		
		static private function OutputGroups( xml:XML, app:App, instances:Vector.<PathInstanceData> ):void
		{
			var layersXml:XML = < layers/>;
			xml.appendChild( layersXml );
			
			for ( var i:uint = 0; i < app.layerGroups.length; i++ )
			{
				var group:LayerGroup = app.layerGroups[i];
				var groupXml:XML = < group name = { group.name } 
									id = { group.id }
									xScroll = { group.xScroll }
									yScroll = { group.yScroll }
									visible = { group.visible }
									open = { app.layerTree.isItemOpen( group ) }
									locked = { group.Locked( false ) }
									exports = { group.Exports( false ) }
									/>
				if ( app.layerTree.selectedItem == group )
				{
					groupXml[ "@selected" ] = true;
				}
				layersXml.appendChild( groupXml );
				OutputProperties(groupXml, group.properties );
				OutputLayers(groupXml, group.children, instances );
			}
		}
		
		static private function OutputLayers( xml:XML, layerCollection:ArrayCollection, instances:Vector.<PathInstanceData> ):void
		{
			for ( var i:uint = 0; i < layerCollection.length; i++ )
			{
				var layer:LayerEntry = layerCollection[i] as LayerEntry;
				var mapLayer:LayerMap = layer as LayerMap;
				var spriteLayer:LayerSprites = layer as LayerSprites;
				var pathLayer:LayerPaths = layer as LayerPaths;
				var shapeLayer:LayerShapes = layer as LayerShapes;
				var imageLayer:LayerImage = layer as LayerImage;
				var layerXml:XML;
				if ( mapLayer )
				{
					var fileref:File = mapLayer.imageFileObj;// new File(mapLayer.imageFile);
					var f:File = Global.CurrentProjectFile;
					
					var imageFileName:String = ResolvePath( f.parent, fileref );
					layerXml = < maplayer name = { layer.name } 
								id = { layer.id }
								xScroll = { layer.xScroll }
								yScroll = { layer.yScroll }
								x = { mapLayer.map.x }
								y = { mapLayer.map.y }
								width = { mapLayer.map.widthInTiles}
								height = { mapLayer.map.heightInTiles }
								tileset = { imageFileName }
								tileWidth = { mapLayer.map.tileWidth }
								tileHeight = { mapLayer.map.tileHeight }
								visible = { layer.visible }
								hasHits = { mapLayer.HasHits }
								drawIdx = { mapLayer.map.drawIndex }
								collideIdx = { mapLayer.map.collideIndex }
								eraseIdx = { mapLayer.EraseTileIdx }
								locked = { mapLayer.Locked( false ) }
								exports = { mapLayer.Exports( false ) }
								tileSpacingX = { mapLayer.map.tileSpacingX }
								tileSpacingY = { mapLayer.map.tileSpacingY }
								xStagger = { mapLayer.map.xStagger }
								tileOffsetX = { mapLayer.map.tileOffsetX }
								tileOffsetY = { mapLayer.map.tileOffsetY } 
								isMaster = { mapLayer.IsMasterLayer() }
								mapType = { mapLayer.tilemapType }
								hasHeight = { mapLayer.hasHeight }
								repeatX = { mapLayer.map.repeatingX }
								repeatY = { mapLayer.map.repeatingY }
							/> ;
					xml.appendChild( layerXml );
					
					OutputProperties(layerXml, mapLayer.properties );
					
					var tiles:Array = mapLayer.map.GetTileIdDataArray();
					var wid:uint = mapLayer.map.widthInTiles;
					var ht:uint = mapLayer.map.heightInTiles;
					for ( var y:uint = 0; y < ht; y++ )
					{
						var rowIndex:uint = y * wid;
						var row:String = "";
						row += tiles[rowIndex];
						var tileIndex:uint = rowIndex+1;
						for ( var x:uint = 1; x < wid; x++ )
						{
							row += "," + tiles[tileIndex];
							tileIndex++;
						}
						layerXml.appendChild( <row>{row}</row> );
					}
					
					if ( mapLayer.SharesTileProperties() )
					{
						layerXml[ "@sharesTileProps" ] = true;
					}
					var propList:Vector.<ArrayCollection> = mapLayer.GetTileProperties();
					if ( propList.length )
					{
						var tilePropsXml:XML = <tileProperties/>;
						layerXml.appendChild( tilePropsXml );
						for each( var prop:ArrayCollection in propList )
						{
							OutputProperties(tilePropsXml, prop, true );
						}
					}
					
					if ( mapLayer.SharesTileAnims() )
					{
						layerXml[ "@sharesTileAnims" ] = true;
					}
					
					var tileAnims:Vector.<TileAnim> = mapLayer.GetTileAnims();
					if ( tileAnims && tileAnims.length )
					{
						var tileAnimsXml:XML = < anims />
						layerXml.appendChild( tileAnimsXml );
						for each( var anim:TileAnim in tileAnims )
						{
							anim.Save(tileAnimsXml);
						}
					}
					
					if ( mapLayer.map.stackedTiles && mapLayer.map.stackHeight )
					{
						var stacksXml:XML = <stacks height={mapLayer.map.stackHeight}/>;
						for (var key:Object in mapLayer.map.stackedTiles)
						{
							var tileInfo:StackTileInfo = mapLayer.map.stackedTiles[key];
							var tileString:String = "";
							for ( var key2:Object in tileInfo.tiles )
							{
								tileString += "," + key2 + ":" + tileInfo.tiles[key2];
							}
							if ( tileString.charAt(0) == ",")
							{
								tileString = tileString.slice(1, tileString.length);
							}
							
							stacksXml.appendChild( <stack id = { key }>{tileString}</stack> );
						}
						layerXml.appendChild( stacksXml );
					}
				}
				else if ( imageLayer )
				{
					fileref = imageLayer.imageFile;
					imageFileName = ResolvePath( Global.CurrentProjectFile.parent, fileref );
					layerXml = < imagelayer name = { layer.name } 
								id = { layer.id }
								file = { imageFileName }
								xScroll = { layer.xScroll }
								yScroll = { layer.yScroll }
								x = { imageLayer.sprite.x }
								y = { imageLayer.sprite.y }
								visible = { layer.visible }
								opacity = { imageLayer.opacity }
								locked = { false }
								exports = { imageLayer.Exports( false ) }
							/> ;
					xml.appendChild( layerXml );
					OutputProperties(layerXml, imageLayer.properties );
				}
				else
				{
					var avatarLayer:LayerAvatarBase = layer as LayerAvatarBase;
					
					if ( spriteLayer )
					{
						layerXml = < spritelayer name = { layer.name } 
									id = { layer.id }
									xScroll = { layer.xScroll }
									yScroll = { layer.yScroll }
									visible = { layer.visible }
									locked = { layer.Locked( false ) }
									exports = { layer.Exports( false ) }
									aligned = { avatarLayer.AlignedWithMasterLayer }
									sort = { avatarLayer.AutoDepthSort }
								/>;
					}
					else if ( pathLayer )
					{
						layerXml = < pathlayer name = { layer.name } 
									id = { layer.id }
									xScroll = { layer.xScroll }
									yScroll = { layer.yScroll }
									visible = { layer.visible }
									locked = { layer.Locked( false ) }
									exports = { layer.Exports( false ) }
									aligned = { avatarLayer.AlignedWithMasterLayer }
									sort = { avatarLayer.AutoDepthSort }
								/>;
					}
					else if ( shapeLayer )
					{
						layerXml = < shapelayer name = { layer.name } 
									id = { layer.id }
									xScroll = { layer.xScroll }
									yScroll = { layer.yScroll }
									visible = { layer.visible }
									locked = { layer.Locked( false ) }
									exports = { layer.Exports( false ) }
									aligned = { avatarLayer.AlignedWithMasterLayer }
									sort = { avatarLayer.AutoDepthSort }
								/>;
					}
					
					xml.appendChild( layerXml );
					
					OutputProperties(layerXml, layer.properties );
					
					for ( var spriteIndex:uint = 0; spriteIndex < avatarLayer.sprites.members.length; spriteIndex++ )
					{
						OutputAvatar( layerXml, avatarLayer.sprites.members[spriteIndex], instances );
					}
				}
				if ( App.getApp().layerTree.selectedItem == layer )
				{
					layerXml[ "@selected" ] = true;
				}
			}
		}
		
		static private function OutputAvatar( xml:XML, avatar:EditorAvatar, instances:Vector.<PathInstanceData> ):void
		{
			if ( !avatar.CanSave() )
			{
				return;
			}
			
			if ( OutputPathAvatar(xml, avatar as PathObject, instances ) == true )
			{
				return;
			}
			
			if ( OutputShapeAvatar(xml, avatar as ShapeObject, instances ) == true )
			{
				return;
			}
			
			var spriteTrail:SpriteTrailObject = avatar as SpriteTrailObject;
			
			if ( avatar.spriteEntry == null && !spriteTrail )
			{
				return;
			}
			
			var parentAvatar:EditorAvatar = avatar.attachment ? avatar.attachment.Parent as EditorAvatar : null;
			
			// Note that Z is capatalized due to the fact that a lower case z was incorrectly included in earlier versions!
			var newXml:XML = < sprite guid = { avatar.GetGUID() }
							x = { Misc.RoundNumberToDecimalPlaces( avatar.x, 100 ) }
							y = { Misc.RoundNumberToDecimalPlaces( avatar.y, 100 ) }
							Z = { Misc.RoundNumberToDecimalPlaces( -avatar.z, 100 ) }
							angle = { Misc.RoundNumberToDecimalPlaces(avatar.angle, 100 ) }
							scaleX = { Misc.RoundNumberToDecimalPlaces(avatar.scale.x, 100 ) }
							scaleY = { Misc.RoundNumberToDecimalPlaces(avatar.scale.y, 100 ) }
							flipped = { avatar.Flipped }
							/> ;
							
							
			if ( avatar.spriteEntry )
			{
				newXml[ "@idx" ] = avatar.spriteEntry.id;
				if ( !avatar.spriteEntry.IsTileSprite )
				{
					if( avatar.animIndex != -1 )
						newXml[ "@frame" ] = avatar.animIndex;
				}
				else
				{
					if ( avatar.TileOrigin )
					{
						newXml[ "@sheetX"] = Misc.RoundNumberToDecimalPlaces(avatar.TileOrigin.x, 100 );
						newXml[ "@sheetY"] = Misc.RoundNumberToDecimalPlaces(avatar.TileOrigin.y, 100 );
					}
					if ( avatar.TileDims )
					{
						newXml[ "@sheetWid"] = Misc.RoundNumberToDecimalPlaces(avatar.TileDims.x, 100 );
						newXml[ "@sheetHt"] = Misc.RoundNumberToDecimalPlaces(avatar.TileDims.y, 100 );
						// Need to save other values as well to reconstruct the avatar.
						newXml[ "@width"] = Misc.RoundNumberToDecimalPlaces(avatar.width, 100 );
						newXml[ "@height"] = Misc.RoundNumberToDecimalPlaces(avatar.height, 100 );
					}
				}
			}
			if ( parentAvatar )
			{
				newXml[ "@attachedTo" ] = parentAvatar.GetGUID();
			}
			
			
			if ( spriteTrail )
			{
				newXml.appendChild( spriteTrail.trailData.Save( ) );
			}
							
			xml.appendChild( newXml );
			
			OutputProperties( newXml, avatar.properties );
		}
		
		static private function OutputShapeAvatar( xml:XML, avatar:ShapeObject, instances:Vector.<PathInstanceData> ):Boolean
		{
			if ( avatar == null )
			{
				return false;
			}
			
			var textObject:TextObject = avatar as TextObject;
			
			var newXml:XML;
			
			if ( textObject )
			{
				newXml = < shape guid = { avatar.GetGUID() }
						x = { Misc.RoundNumberToDecimalPlaces( avatar.x, 100 ) }
						y = { Misc.RoundNumberToDecimalPlaces( avatar.y, 100 ) }
						Z = { Misc.RoundNumberToDecimalPlaces( -avatar.z, 100 ) }
						angle = { Misc.RoundNumberToDecimalPlaces(avatar.angle, 100 ) }
						width = { avatar.width.toFixed(2) }
						height = { avatar.height.toFixed(2) }
						/> ;
				if ( textObject.bmpText )
				{
					try
					{
						var fileref:File = textObject.bmpText.bmpFile;
						var bmpFileName:String = ResolvePath( Global.CurrentProjectFile.parent, fileref );
					}
					catch ( error:Error )
					{
						bmpFileName = "";
					}
					newXml[ "@text"] = textObject.bmpText.text;
					newXml[ "@bmpFile"] = bmpFileName;
					newXml[ "@charSetType"] = textObject.bmpText.characterSetType;
					newXml[ "@charSet"] = textObject.bmpText.characterSetType == "Other" ? textObject.bmpText.characterSet : "";
					newXml[ "@charWid"] = textObject.bmpText.characterWidth;
					newXml[ "@charHt"] = textObject.bmpText.characterHeight;
					newXml[ "@autoTrim"] = textObject.bmpText.autoTrim;
					newXml[ "@xSpace"] = textObject.bmpText.customSpacingX;
					newXml[ "@ySpace"] = textObject.bmpText.customSpacingY; 
					newXml[ "@align"] = textObject.bmpText.align;
					newXml[ "@scale"] = textObject.bmpText.scaler;
				}
				else
				{
					newXml[ "@text"] = textObject.text.text;
					newXml[ "@family"] = textObject.text.font;
					newXml[ "@fontsize"] = textObject.text.size;
					newXml[ "@align"] = textObject.text.alignment;
					newXml[ "@color"] = textObject.text.color;
				}
				
			}
			else
			{
				newXml = < shape guid = { avatar.GetGUID() }
						type = { avatar.isEllipse ? "circle" : "square" }
						x = { Misc.RoundNumberToDecimalPlaces( avatar.x, 100 ) }
						y = { Misc.RoundNumberToDecimalPlaces( avatar.y, 100 ) }
						Z = { Misc.RoundNumberToDecimalPlaces( -avatar.z, 100 ) }
						angle = { Misc.RoundNumberToDecimalPlaces(avatar.angle, 100 ) }
						width = { avatar.width.toFixed(2) }
						height = { avatar.height.toFixed(2) }
						scaleX = { avatar.scale.x.toFixed(3) }
						scaleY = { avatar.scale.y.toFixed(3) }
						/> ;
			}
			
			if ( avatar.colourOverriden )
			{
				newXml[ "@fillColor" ] = Misc.uintToHexStr6Digits(avatar.fillColour);
				newXml[ "@alpha" ] = avatar.alphaValue.toFixed(2);
			}
			xml.appendChild( newXml );
			
			OutputProperties( newXml, avatar.properties );
			
			return true;
		}
		
		static private function OutputPathAvatar( xml:XML, avatar:PathObject, instances:Vector.<PathInstanceData> ):Boolean
		{
			if ( avatar == null )
			{
				return false;
			}
			
			var childAvatar:EditorAvatar = avatar.attachment ? avatar.attachment.Child as EditorAvatar : null;
			
			var guid:String = avatar.GetGUID();
			var newXml:XML = < path guid = { guid }
							x = { Misc.RoundNumberToDecimalPlaces( avatar.x, 100 ) }
							y = { Misc.RoundNumberToDecimalPlaces( avatar.y, 100 ) }
							closed = { avatar.IsClosedPoly }
							curved = { avatar.IsCurved }
							instanced = { avatar.IsInstanced }
							/> ;
							
			if ( childAvatar )
			{
				newXml[ "@attachedChild" ] = childAvatar.GetGUID();
			}
			
			if ( avatar.pathEvents.length )
			{
				var eventsXml:XML = < events />
				for each( var event:PathEvent in avatar.pathEvents )
				{
					var eventXml:XML = < event x = { event.x } 
												y = { event.y }
												segment = { event.segmentNumber }
												percent = { event.percentInSegment }
										/> ;
												
					OutputProperties( eventXml, event.properties );
												
					eventsXml.appendChild( eventXml );
				}
				newXml.appendChild( eventsXml );
			}
			
			var outputNodes:Boolean = true;
			if ( avatar.IsInstanced )
			{
				// Ensure we only output each instance list once.
				var instanceId:int = -1;
				for ( var j:uint = 0; j < instances.length; j++ )
				{
					if ( instances[j].avatars == avatar.instancedShapes )
					{
						// If the entry is already in there 
						instanceId = j;
						break;
					}
				}
				if ( instanceId == -1 )
				{
					instanceId = instances.length;
					instances.push( new PathInstanceData( avatar.instancedShapes ) ); 
				}
				newXml[ "@instanceId" ] = instanceId;
			}
			else
			{
				OutputPathNodes(newXml, avatar );
			}
			
			xml.appendChild( newXml );
			
			OutputProperties( newXml, avatar.properties );
			
			return true;
		}
		
		static private function OutputPathNodes(xml:XML, pathAvatar:PathObject ):void
		{
			for ( var i:uint = 0; i < pathAvatar.nodes.length; i++ )
			{
				var pathNode:PathNode = pathAvatar.nodes[i] as PathNode;
				if ( pathAvatar.IsCurved )
				{
					xml.appendChild( < node x = { Misc.RoundNumberToDecimalPlaces( pathNode.x, 100 ) }
									y = { Misc.RoundNumberToDecimalPlaces( pathNode.y, 100 ) }
									tan1x = { Misc.RoundNumberToDecimalPlaces( pathNode.tangent1.x, 100 ) }
									tan1y = { Misc.RoundNumberToDecimalPlaces( pathNode.tangent1.y, 100 ) }
									tan2x = { Misc.RoundNumberToDecimalPlaces( pathNode.tangent2.x, 100 ) }
									tan2y = { Misc.RoundNumberToDecimalPlaces( pathNode.tangent2.y, 100 ) }
									/> );
				}
				else
				{
					xml.appendChild( < node x = { Misc.RoundNumberToDecimalPlaces( pathNode.x, 100 ) }
									y = { Misc.RoundNumberToDecimalPlaces( pathNode.y, 100 ) }
									/> );
				}
			}
		}
		
		static private function OutputLinks(xml:XML ):void
		{
			var links:Vector.<AvatarLink> = AvatarLink.GetLinks();
			if ( links.length == 0 )
			{
				return;
			}
			
			var linksXml:XML = <links/>;
			for each( var link:AvatarLink in links )
			{
				var linkXml:XML = <link from={ link.fromAvatar.GetGUID() } to={ link.toAvatar.GetGUID() }/>;
				linksXml.appendChild(linkXml);
				OutputProperties(linkXml, link.properties);
			}
			xml.appendChild(linksXml);
		}
		
		static private function OutputProperties(xml:XML, properties:ArrayCollection, alwaysOutput:Boolean = false ):void
		{
			if ( properties != null && properties.length > 0 )
			{
				var propsXml:XML = <properties/>;
				xml.appendChild(propsXml);
				for ( var i:uint = 0; i < properties.length; i++ )
				{
					var typeClass:Class = properties[i].Type;
					var type:String;
					
					if ( typeClass == String )
					{
						type = "String";
					}
					else if ( typeClass == Number )
					{
						type = "Float";
					}
					else if ( typeClass == int )
					{
						type = "Int";
					}
					else if ( typeClass == Boolean )
					{
						type = "Boolean";
					}
					else if ( typeClass == CustomPropertyFilterType )
					{
						type = "Filter";
					}
					else if ( typeClass == CustomPropertyType )
					{
						type = "Custom";
					}
					else
					{
						throw new Error("Unknown property type: " + type.toString);
						//AlertBox.Show(outputText, "Unknown property type");
					}
					var propData:PropertyData = properties[i] as PropertyData;
					if ( propData )
					{
						if ( !propData.UsingDefaultValue )
						{
							// Need to store the idx as names are not necessarily unique.
							var typeXml:XML = < dataOverride name = { propData.Name }
											typeof = { type }
											value = { propData.TextValue } 
											idx = { i } />;
											
							var typeData:CustomPropertyType = propData.GetTypeObj() as CustomPropertyType;
							
							if ( typeData != null )
							{
								//typeXml[ "@typeName" ] = typeData.name;
								//typeXml[ "@customTypeIdx" ] = CustomPropertyType.TypesProvider.getItemIndex(typeData);
								if ( typeData is CustomPropertyFilterType )
								{
									var filterType:CustomPropertyFilterType = typeData as CustomPropertyFilterType;
									var typeLayer:LayerEntry = (propData.Value as CustomPropertyValue).data as LayerEntry;
									if ( typeLayer )
									{
										typeXml[ "@dataId" ] = typeLayer.id;
									}
								}
							}
							propsXml.appendChild( typeXml );
						}
					}
					else
					{
						var propType:PropertyType = properties[i] as PropertyType;
						typeXml = < type typeof = { type } name = { propType.Name } value = { propType.TextValue } hidden = { propType.Hidden } />;
						
						typeData = propType.GetTypeObj() as CustomPropertyType;
						if ( typeData != null )
						{
							typeXml[ "@typeName" ] = typeData.name;
							typeXml[ "@customTypeIdx" ] = CustomPropertyType.TypesProvider.getItemIndex(typeData);
							if ( typeData is CustomPropertyFilterType )
							{
								filterType = typeData as CustomPropertyFilterType;
								typeLayer = (propType.Value as CustomPropertyValue).data as LayerEntry;
								if ( typeLayer )
								{
									typeXml[ "@dataId" ] = typeLayer.id;
								}
							}
							
						}
						propsXml.appendChild( typeXml );
					}
					
				}
			}
			else if ( alwaysOutput )
			{
				propsXml = <properties/>;
				xml.appendChild(propsXml);
			}
		}
		
		static private function OutputInstances( xml:XML, instances:Vector.<PathInstanceData> ):void
		{
			if ( instances.length == 0 )
			{
				return;
			}
			var instanceListsXml:XML = <instanceLists/>;
			xml.appendChild(instanceListsXml);
			for ( var i:uint = 0; i < instances.length; i++ )
			{
				var instancesXml:XML = <path/>
				instanceListsXml.appendChild( instancesXml );
				OutputPathNodes( instancesXml, instances[i].avatars[0] );
			}
		}
		
		static private function OutputTileMatrix( xml:XML, app:App ):void
		{
			if ( !app.tileMatrix )
			{
				return;
			}
			
			try
			{
				var fileref:File = app.tileMatrix.tilesetImageFile;// new File(app.tileMatrix.tilesetImageFile);
				var imageFileName:String = ResolvePath( Global.CurrentProjectFile.parent, fileref );
			}
			catch ( error:Error )
			{
				imageFileName = "";
			}
			
			var matData2:TileMatrixData = Global.windowedApp.tileMatrix.currentMatrixData;
			var currentMatrixIdx:int = app.tileMatrices.getItemIndex(Global.windowedApp.tileMatrix.currentMatrixData);
			var matrix:XML = < tileMatrix currentMatrix = { currentMatrixIdx }
										rows = { app.tileMatrix.RowCount }
										cols = { app.tileMatrix.ColumnCount }
										randomizeMiddle = { EditorTypeTileMatrix.RandomizeMiddleTiles }
										ignoreClear = { EditorTypeTileMatrix.IgnoreClearTiles }
										ignoreMapEdges = { EditorTypeTileMatrix.IgnoreMapEdges }
										allowSpecialTiles = { EditorTypeTileMatrix.AllowSpecialTiles }
										tileset = { imageFileName }/>;
			xml.appendChild(matrix);
			
			var i:uint = 0;
			
			for ( var y:uint = 0; y < app.tileMatrix.RowCount; y++ )
			{
				var row:XML = <row/>;
				matrix.appendChild(row);
				for ( var x:uint = 0; x < app.tileMatrix.ColumnCount; x++ )
				{
					row.appendChild(<tile>{ app.tileMatrix.GetMetaDataAtIndex(i) }</tile>);
					i++;
				}
			}
			
			OutputTileMatrixConnections(matrix);
			
			// Output the list of tile matrices (the current matrix may not necessarily be in the list)
			for each( var matData:TileMatrixData in app.tileMatrices.source )
			{
				if (matData )
				{
					try
					{
						fileref = matData.tilesetImageFile;// new File(matData.tilesetImageFile);
						imageFileName = ResolvePath( Global.CurrentProjectFile.parent, fileref );
					}
					catch ( error:Error )
					{
						imageFileName = "";
					}
					matrix = < tileMatrixData name = { matData.name }
											rows = { matData.numRows }
											cols = { matData.numColumns }
											randomizeMiddle = { matData.RandomizeMiddleTiles }
											ignoreClear = { matData.IgnoreClearTiles }
											ignoreMapEdges = { matData.IgnoreMapEdges }
											allowSpecialTiles = { matData.AllowSpecialTiles }
											tileset = { imageFileName }/>;
					
					var str:String = "";
					for ( i = 0; i < matData.tileIds.length; i++ )
					{
						str += matData.tileIds[i];
						if ( i + 1 < matData.tileIds.length )
						{
							str += ",";
						}
					}
					matrix.appendChild(<tiles>{ str }</tiles>);
					
					for ( i = 0; i < matData.SpecialTileRows.length; i++ )
					{
						var rowData:SpecialTileRowData = matData.SpecialTileRows[i];
						var setIndex:int = TileConnectionList.tileConnectionLists.getItemIndex(rowData.set);
						
						// For now, don't add it if the set no longer exists.
						if ( setIndex != -1 )
						{
							var connections:XML = <connections set={setIndex}/>;
							matrix.appendChild(connections);
							
							str = "";
							for ( var j:uint = 0; j < rowData.tiles.length; j++ )
							{
								str += rowData.tiles[j];
								if ( j + 1 < rowData.tiles.length )
								{
									str += ",";
								}
							}
							connections.appendChild(<tiles>{ str }</tiles>);
						}
					}
					
					xml.appendChild(matrix);
				}
			}
			
		}
		
		static private function OutputTileMatrixConnections( xml:XML ):void
		{
			var SpecialConnections:XML = <specialConnections/>;
			
			// Output the connection sets.
			var sets:XML = <sets/>;
			for ( var n:uint = 0; n < TileConnectionList.tileConnectionLists.length; n++ )
			{
				var list:TileConnectionList = TileConnectionList.tileConnectionLists[n];
				var connections:XML = <connections name={list.label}/>
				for ( var i:uint = 0; i < list.tiles.length; i++ )
				{
					connections.appendChild(<entry green={"0x" + list.tiles[i].GreenTiles.toString(16)} red={"0x" + list.tiles[i].RedTiles.toString(16)}/>);
				}
				sets.appendChild(connections);
			}
			SpecialConnections.appendChild(sets);
			
			// Output the rows being used.
			var rows:XML = <rows/>;
			var specialRows:Array = Global.windowedApp.tileMatrix.SpecialTilesRows.getChildren();
			for ( n = 0; n < specialRows.length; n++ )
			{
				var grid:TileConnectionGrid = specialRows[n].tiles;
				var row:XML = < row set = { TileConnectionList.tileConnectionLists.getItemIndex(grid.Connections) }/>;
				var tiles:XML = <tiles/>;
				for ( i = 0; i < grid.Connections.tiles.length; i++ )
				{
					tiles.appendChild(<id>{grid.GetMetaDataAtIndex(i)}</id>);
				}
				row.appendChild(tiles);
				rows.appendChild(row);
			}
			SpecialConnections.appendChild(rows);
			
			xml.appendChild(SpecialConnections);
		}
		
		static private function OutputTileBrushes( xml:XML ):void
		{
			var TileBrushes:XML = <tileBrushes/>;
			
			for ( var i:uint = 0; i < TileBrushesWindow.brushes.length; i++ )
			{
				var layerData:TileEditorLayerEntry = TileBrushesWindow.brushes[i].entry;
				var fileref:File = layerData.imageFile;// new File(layerData.imageFile);
				var imageFileName:String = ResolvePath( Global.CurrentProjectFile.parent, fileref );
				var brush:XML = <brush name={TileBrushesWindow.brushes[i].label} tileset={imageFileName}/>;
				
				for ( var row:uint = 0; row < layerData.rows.length; row++ )
				{
					var rowData:TileEditorRowEntry = layerData.rows[row];
					var rowXml:XML = <row y={rowData.startY} />
					for ( var col:uint = 0; col < rowData.tiles.length; col++ )
					{
						var tileData:TileEditorTileEntry = rowData.tiles[col];
						var tileXml:XML = <tile x={tileData.startX} id={tileData.tileId} />;
						rowXml.appendChild(tileXml);
					}
					brush.appendChild(rowXml);
				}
				TileBrushes.appendChild(brush);
			}
			
			xml.appendChild(TileBrushes);
		}
		
		static private function OutputBookmarks( xml:XML, app:App ):void
		{
			var Bookmarks:XML = <bookmarks/>;
			for each( var bookmark:Bookmark in app.bookmarks)
			{
				if (bookmark.gotoMenu.enabled )
				{
					Bookmarks.appendChild(<bookmark enabled={true} x={-bookmark.location.x} y={-bookmark.location.y}/>);
				}
				else
				{
					Bookmarks.appendChild(<bookmark enabled={false}/>);
				}
			}
			xml.appendChild(Bookmarks);
		}
		
		//} endregion
		
		//{ region Loading
		
		static private var spriteIdxAtStart:uint;
		static private var currentLoadingFile:File = null;
		static private var wantedSpriteSelection:SpriteEntry = null;
		static private var wantedLayerSelection:LayerEntry = null;
		static private var spriteIdxRemapDictionary:Dictionary = null;
		
		static private function LoadXml( file:File, loadedFunction:Function ):void
		{
			var filename:String = file.url;
			var urlRequest:URLRequest = new URLRequest(filename);
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT; // default
			urlLoader.addEventListener(Event.COMPLETE, xmlLoaded,false,0,true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlLoadFailedIO,false,0,true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, xmlLoadFailedSecurity, false, 0, true);
			var intervalId:uint = setInterval(continueLoadingXml, 200);
			urlLoader.load(urlRequest);
			
			// Hack to prevent the loader doing nothing occasionally. Having the interval seems to fix it.
			function continueLoadingXml( ):void
			{
				//trace(urlLoader.bytesLoaded);
			}
			
			function xmlLoaded(event:Event ):void
			{
				try
				{
					clearInterval(intervalId);
					
					//LogWindow.LogWriteLine("XmlLoaded.");
					
					// convert the loaded text into XML
					var xml:XML = XML(urlLoader.data);
					urlLoader.close();
					loadedFunction(xml);
				}
				catch(error:Error)
				{
					LogWindow.LogWriteLine("Load error 1 " + error);
					AlertBox.Show("Failed to parse XML: " + error, "Error");
					urlLoader.close();
				}
			}
			
			function xmlLoadFailedIO(event:IOErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load IO error " + event.text);
				AlertBox.Show("Failed to load file: " + event.text, "IO Error");
			}
			
			function xmlLoadFailedSecurity(event:SecurityErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load security error " + event.text);
				AlertBox.Show("Failed to load file:"  + event.text, "Security Error");
			}
		}
		
		static public function OpenProject( file:File, loadComplete:Function, loadAsNew:Boolean = true, append:Boolean = false, entireProject:Boolean = true, includeSprites:Boolean = true, includeMatrix:Boolean = true, includeBrushes:Boolean = true, includeLayers:Boolean = true, includeSettings:Boolean = true, relativeImagePath:Boolean = true ):void
		{
			//LogWindow.LogWriteLine("");
			var date:Date = new Date;
			//LogWindow.LogWriteLine("Open file on " + date.toString() + ": " + file.url);
			/*if ( file.exists )
			{
				LogWindow.LogWriteLine("File last modified on : " + file.modificationDate);
			}*/
			spriteIdxAtStart = 0;
			if ( loadAsNew )
			{
				FlxTilemapExt.ResetSharedData();
				Global.RememberFile( file.nativePath );
				Global.CurrentProjectFile = file;
				// Just make sure these variables are correct.
				entireProject = true;
				append = false;
				var currentState:EditorState = FlxG.state as EditorState;
				if ( currentState )
				{
					currentState.drawEditor.ClearSelectedSprites();
				}
				CustomPropertyType.TypesProvider = new ArrayCollection;
			}
			
			if ( relativeImagePath )
			{
				currentLoadingFile = Global.CurrentProjectFile;
			}
			else
			{
				currentLoadingFile = file;
			}

			LoadXml(file, xmlLoaded);
			
			function xmlLoaded(xml:XML ):void
			{
				try
				{
					//LogWindow.LogWriteLine("File closed.");
					
					
					var app:App = App.getApp();
					
					// Can't use the backup method (where I load and then either delete the old data or restore it on success/fail)
					// Because for some reason it causes memory to expand more. It does restore itself as soon as you add a new
					// layer group though !?!?!?!
					
					HistoryStack.Clear();
					spriteIdxAtStart = SpriteEntry.GetEntryCount();
					if ( !append )
					{
						if ( app.tileMatrixWindow && ( entireProject || includeMatrix) )
						{
							app.tileMatrixWindow.Reset();
						}
						for each( var bookmark:Bookmark in app.bookmarks )
						{
							bookmark.gotoMenu.enabled = false;
							bookmark.location = null;
						}
						if ( includeSprites || includeLayers || entireProject)
						{
							spriteIdxAtStart = 0;
							ImageBank.Clear();
							app.spriteData[0].children.removeAll();
							app.spriteData.itemUpdated( app.spriteData[0] );
						}
						if ( includeLayers || entireProject )
						{
							app.layerGroups.removeAll();
							app.layerGroups.itemUpdated( app.layerGroups );
							var currentState:EditorState = FlxG.state as EditorState;
							if ( currentState )
							{
								currentState.UpdateMapList();
								currentState.UpdateCurrentTileList( app.CurrentLayer );
							}
							AvatarLink.ClearAllLinks();
						}
					}
			
					//ImageBank.BackUp();
					//ImageBank.Initialize();
						
					
					finishedLoadingSprites = false;
					numLoadingSprites = 0;
					var waitForSettings:Boolean = false;
					
					spriteIdxRemapDictionary = null;
					
					var settingsXml:XML = null;
					
					if ( entireProject || includeSprites || includeLayers )
					{
						// Load custom property types before anything else.
						CustomPropertyType.TypesProvider = new ArrayCollection();
						CustomPropertyType.LoadAll(xml);
						
						if ( includeLayers && append )
						{
							spriteIdxRemapDictionary = new Dictionary;
						}
						var spriteData:SpriteEntry = app.spriteData[0];

						if ( xml.hasOwnProperty("spriteEntriesFile") ) // legacy
						{
							Global.CurrentSettingsFile = currentLoadingFile.parent.resolvePath(xml.spriteEntriesFile);
							if ( entireProject )
							{
								Global.SaveSpritesSeparately = true;
							}
							LoadXml(Global.CurrentSettingsFile, spritesXmlLoaded);
						}
						else if( xml.hasOwnProperty("settingsFile") )
						{
							Global.CurrentSettingsFile = currentLoadingFile.parent.resolvePath(xml.settingsFile);
							waitForSettings = true;
							LoadXml(Global.CurrentSettingsFile, loadedSettings);
						}
						else
						{
							Global.CurrentSettingsFile = null;
							Global.SaveSpritesSeparately = false;
							spritesXmlLoaded(xml);
						}
						
						function loadedSettings(settingsXmlData:XML):void
						{
							settingsXml = settingsXmlData;
							CustomPropertyType.LoadAll(settingsXml);
							spritesXmlLoaded(xml);
							waitForSettings = false;
							spritesXmlLoaded(settingsXmlData);
						}
						
						function spritesXmlLoaded(spriteXml:XML ):void
						{
							var spriteEntriesXml:XMLList = spriteXml.spriteEntries;
							if ( spriteEntriesXml )
							{
								ReadSpriteEntry( spriteEntriesXml.*, spriteData, append );
								app.spriteList.expandItem(app.spriteData[0], true);
								if ( wantedSpriteSelection != null )
								{
									app.spriteList.selectedItem = wantedSpriteSelection;
									wantedSpriteSelection = null;
								}
							}
							//currentLoadingFile = Global.CurrentProjectFile;
							if ( entireProject && Global.SaveSpritesSeparately )
							{
								SpriteEntry.ResetSpriteEntryIds(spriteEntriesXml.@currentId);
							}
							if( !waitForSettings)
								finishedLoadingSprites = true;
						}
					}
					
					//trace("num sprites remaining = " + numLoadingSprites);
					
					var intervalId:uint = setInterval(continueLoading, 200);
					
					//LogWindow.LogWriteLine("Load sprites.");
					
					function continueLoading( ):void
					{
						//trace("num sprites remaining = " + numLoadingSprites);
						if ( numLoadingSprites != 0 || !finishedLoadingSprites || waitForSettings )
						{
							return;
						}
						
						date = new Date;
						//LogWindow.LogWriteLine("Sprites loaded." + date.toString() );
						
						clearInterval(intervalId);
						
						// Update the tree so that the leaf icon is shown.
						app.spriteData.itemUpdated( app.spriteData[0] );
						
						//trace("all sprites done");
						
						var linkDictionary:Dictionary = new Dictionary;
						if ( entireProject || includeLayers )
						{
							GenerateLinksDictionary(xml.links.link, linkDictionary );
							var instances:Vector.<PathInstanceData> = new Vector.<PathInstanceData>();
							var layerGroups:ArrayCollection = app.layerGroups;
							layerGroups.removeAll();
							var layersXml:XMLList = xml.layers;
							if ( layersXml )
							{
								ReadLayerGroups( layersXml.group, layerGroups, spriteData, instances, linkDictionary );
							}
							var templatesXml:XMLList = xml.layerTemplates;
							if ( templatesXml && templatesXml.length() > 0 )
							{
								app.layerTemplates.removeAll();
								ReadLayers( templatesXml.*, null, app.layerTemplates, null, null, instances, linkDictionary );
							}
							if ( settingsXml && settingsXml.layerTemplates && settingsXml.layerTemplates.length() > 0 )
							{
								app.layerTemplates.removeAll();
								ReadLayers( settingsXml.layerTemplates.*, null, app.layerTemplates, null, null, instances, linkDictionary );
							}
							
							UpdateInstances( xml.instanceLists.path, instances );
							
							AddLinks( xml.links.link, linkDictionary );
						}
						
						if ( entireProject || includeMatrix )
						{
							if ( !append )
							{
								app.tileMatrices.removeAll();
								TileConnectionList.tileConnectionLists.removeAll();
								app.tileMatrixWindow.SpecialTilesRows.removeAllChildren();
							}
							if ( settingsXml )
							{
								ReadTileMatrix( settingsXml, app, append);
							}
							ReadTileMatrix( xml, app, append );
						}
						
						if ( entireProject || includeBrushes )
						{
							if ( !append )
							{
								TileBrushesWindow.brushes.removeAll();
							}
							if ( settingsXml )
							{
								ReadTileBrushes( settingsXml.tileBrushes );
							}
							ReadTileBrushes( xml.tileBrushes );
						}
						
						var currentState:EditorState = FlxG.state as EditorState;
						
						if ( entireProject || includeSettings )
						{
							advancedColorPicker.initColors();
							var swatchesXml:XMLList = xml.colorSwatches;
							for each (var swatchXml:XML in swatchesXml.colour)
							{
								advancedColorPicker.swatchColors.push( uint(swatchXml) );
								advancedColorPicker.globalColors.push( uint(swatchXml) );
							}
							
							if ( xml.hasOwnProperty("bgColor") == true )
							{
								FlxState.bgColor = (uint)(xml.bgColor)| 0xff000000;
								var blue:uint = FlxState.bgColor & 0xff;
								Global.MapBoundsColour = ( blue > 0xaa ) ? 0xff000000 : 0xffffffff;
							}
							
							if ( entireProject )
							{
								if( xml.hasOwnProperty("viewPos") )
								{
									var x:int = xml.viewPos.@x;
									var y:int = xml.viewPos.@y;
									var viewPos:FlxPoint = new FlxPoint(x,y);
									currentState.MoveCameraToLocationExact( viewPos, 1, 1, true);
								}
								if ( xml.hasOwnProperty("firstLayersTop") )
								{
									app.firstLayersTopMenuItem.checked = Global.DisplayLayersFirstOnTop = (xml.firstLayersTop == true);
								}
							}
					
							ReadBookmarks(xml, app);
							
							Global.LoadColorGrid( xml );
							Global.LoadOptions( xml.options, true );
						}
						
						if ( entireProject || includeSprites || includeLayers )
						{
							CustomPropertyType.ConvertDataRefs();
						}

						
						if ( currentState )
						{
							currentState.UpdateMapList();
							currentState.UpdateCurrentTileList( app.CurrentLayer );
						}
						
						if ( xml.hasOwnProperty("exporter") )
							Global.ExporterSettings.Load( xml.exporter );
						if ( xml.hasOwnProperty("projectExporter") )
						{
							Global.ProjectExporterSettings.settings.length = 0;
							Global.ProjectExporterSettings.Load( xml.projectExporter );
						}
							
						if ( xml.hasOwnProperty("guides") )
							Global.LoadGridSettings( xml.guides );
						if ( settingsXml != null && settingsXml.hasOwnProperty("guides") )
							Global.LoadGridSettings( settingsXml.guides );
						
						//LogWindow.LogWriteLine("Load almost complete.");
						
						if ( loadComplete != null )
						{
							loadComplete();
						}
						
						// Reset layer ids so numbers stay reasonable for each session.
						// Must be done AFTER everything else has loaded as properties reference the old ids during the load.
						if ( entireProject )
						{
							LayerEntry.ResetLayerEntryIds();
						}
						if ( entireProject || includeLayers )
						{
							for each( var group:LayerEntry in app.layerGroups )
							{
								for each( var layer:LayerEntry in group.children )
								{
									layer.UpdateLayerEntryId();
								}
							}
						}
						
						if ( !Global.SaveSpritesSeparately )
						{
							if ( entireProject )
							{
								SpriteEntry.ResetSpriteEntryIds();
							}
							currentState.UpdateSpriteEntryIds( app.spriteData[0] );
						}
						
						HistoryStack.RecordSave();
						EditorState.recordSave();
						if ( loadAsNew )
						{
							Global.windowedApp.title = file.name + " - DAME";
						}
						
						if ( App.getApp().brushesWindow )
						{
							App.getApp().brushesWindow.ListBrushes.selectedItem = null;
							if ( App.getApp().brushesWindow.visible )
							{
								App.getApp().brushesWindow.recalcPreview();
							}
						}
						
						date = new Date;
						//LogWindow.LogWriteLine("Load successful! at " + date.toString() );
					}
					
				}
				catch (error:Error)
				{
					//LogWindow.LogWriteLine("Load error 1 " + error);
					//ImageBank.RestoreBackup();
					//AlertBox.Show("Failed to parse XML: " + error, "Error");
					//urlLoader.close();
				}

			}
			/*
			function xmlLoadFailedIO(event:IOErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load IO error " + event.text);
				AlertBox.Show("Failed to load file: " + event.text, "IO Error");
			}
			
			function xmlLoadFailedSecurity(event:SecurityErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load security error " + event.text);
				AlertBox.Show("Failed to load file:"  + event.text, "Security Error");
			}*/
		}
		
		static private function ReadSpriteEntry( xml:XMLList, groupEntry:SpriteEntry, checkForDupes:Boolean ):void
		{
			if ( xml == null )
			{
				return;
			}
			for each (var entryXml:XML in xml)
			{
				var spriteEntry:SpriteEntry;
				if ( entryXml.name() == "group" )
				{
					spriteEntry = new SpriteEntry( entryXml.@name, new ArrayCollection() );
					spriteEntry.id = spriteIdxAtStart + entryXml.@idx;
					groupEntry.children.addItemAt( spriteEntry, groupEntry.children.length );
					ReadSpriteEntry( entryXml.*, spriteEntry, checkForDupes );
					if ( xml.@open == "true" )
					{
						App.getApp().spriteList.expandItem(spriteEntry, true);
					}
				}
				else
				{
					spriteEntry = new SpriteEntry( entryXml.@name );
					var callbackData:Object = new Object;
					callbackData.width = entryXml.@width;
					callbackData.height = entryXml.@height;
					
					
					
					var filename:String = entryXml.@image;
					var imageFile:File = currentLoadingFile.parent.resolvePath(filename);
					spriteEntry.SetImageFileNoLoad( imageFile );
					spriteEntry.SetClassName( entryXml.@className );
					spriteEntry.SetConstructorText( entryXml.@constructor );
					spriteEntry.id = spriteIdxAtStart + uint( entryXml.@idx );
					spriteEntry.Bounds.x = entryXml.@boundsX;
					spriteEntry.Bounds.y = entryXml.@boundsY;
					spriteEntry.Bounds.width = entryXml.@boundsWidth;
					spriteEntry.Bounds.height = entryXml.@boundsHeight;
					spriteEntry.Anchor.x = entryXml.@anchorX;
					spriteEntry.Anchor.y = entryXml.@anchorY;
					if( entryXml.hasOwnProperty("@centerAnchor") )
						spriteEntry.CenterAnchor = entryXml.@centerAnchor == true;
					if ( entryXml.hasOwnProperty("@canEditFrames") )
						spriteEntry.CanEditFrames = entryXml.@canEditFrames == true;
					if ( entryXml.hasOwnProperty("@lockRotation") )
						spriteEntry.LockRotationTo90Degrees = entryXml.@lockRotation == true;
					
					if ( entryXml.name() == "tileEntry" )
					{
						spriteEntry.TileOrigin.x = entryXml.@offsetX;
						spriteEntry.TileOrigin.y = entryXml.@offsetY;
						
						spriteEntry.IsTileSprite = true;
					}
					else
					{
						spriteEntry.SetPreviewIndex( entryXml.@preview );
						
						if ( entryXml.anims.length() )
						{
							spriteEntry.anims = new Vector.<TileAnim>;
							for each( var anim:XML in entryXml.anims.anim )
							{
								var tileAnim:TileAnim = new TileAnim;
								spriteEntry.anims.push( tileAnim );
								tileAnim.Load(anim);
							}
						}
						spriteEntry.shapes.Load(entryXml);
					}
					
					var addSprite:Boolean = true;
					if ( checkForDupes )
					{
						var matchSprite:SpriteEntry = App.getApp().spriteData[0].FindMatch( spriteEntry );
						if( matchSprite )
						{
							spriteIdxRemapDictionary[ uint( entryXml.@idx ) ] = matchSprite.id;
							addSprite = false;
						}
					}
					if ( addSprite )
					{
						spriteEntry.SetImageFileNoLoad( null );
						numLoadingSprites++;
						if ( entryXml.name() == "tileEntry" )
						{							
							spriteEntry.SetImageFile( imageFile, recalcTiledBitmapPreview, callbackData, spriteLoadFailed );
						}
						else
						{
							spriteEntry.SetImageFile( imageFile, recalcBitmapPreview, callbackData, spriteLoadFailed );
						}
						
						if( entryXml.hasOwnProperty("@creation") == true )
							spriteEntry.creationText = entryXml.@creation;
						if( entryXml.hasOwnProperty("@exports") == true )
							spriteEntry.Exports = entryXml.@exports == true;
						if( entryXml.hasOwnProperty("@canScale") == true )
							spriteEntry.CanScale = entryXml.@canScale == true;
						if( entryXml.hasOwnProperty("@canRotate") == true )
							spriteEntry.CanRotate = entryXml.@canRotate == true;
						if ( entryXml.hasOwnProperty("@surfaceObject") == true )
							spriteEntry.IsSurfaceObject = entryXml.@surfaceObject == true;
						if ( entryXml.hasOwnProperty("@tileIndex") )
							spriteEntry.tilePreviewIndex = entryXml.@tileIndex;
							
						
						groupEntry.children.addItemAt( spriteEntry, groupEntry.children.length );
						ReadProperties( entryXml.properties.*, spriteEntry );
					}
				}
				if ( entryXml.hasOwnProperty("@selected") )
				{
					wantedSpriteSelection = spriteEntry;
				}
			}
		}
		
		static private function spriteLoadFailed( file:File ):void
		{
			numLoadingSprites--;
		}
		
		static private function recalcTiledBitmapPreview( spriteEntry:SpriteEntry, callbackData:Object ):void
		{
			var sourceRect:Rectangle = new Rectangle( spriteEntry.TileOrigin.x, spriteEntry.TileOrigin.y, callbackData.width, callbackData.height);
			var flashPoint:Point = new Point(0, 0);

			spriteEntry.previewBitmap = new Bitmap( new BitmapData( callbackData.width, callbackData.height,true,0xffffff) );
			spriteEntry.previewBitmap.bitmapData.copyPixels( spriteEntry.bitmap.bitmapData, sourceRect, flashPoint );
			
			numLoadingSprites--;
		}
		
		static private function recalcBitmapPreview( spriteEntry:SpriteEntry, callbackData:Object ):void
		{
			var numRows:uint = Math.ceil( spriteEntry.bitmap.height / callbackData.height );
			var numColumns:uint = Math.ceil( spriteEntry.bitmap.width / callbackData.width );
			spriteEntry.numFrames = numColumns * numRows;
			
			var currentRow:uint = spriteEntry.previewIndex / numColumns;
			var currentColumn:uint = spriteEntry.previewIndex % numColumns;
				
			var sourceRect:Rectangle = new Rectangle( currentColumn * callbackData.width, currentRow * callbackData.height, 1, 1);
			var flashPoint:Point = new Point(0, 0);

			sourceRect.width = callbackData.width;
			sourceRect.height = callbackData.height;
			spriteEntry.previewBitmap = new Bitmap( new BitmapData( callbackData.width, callbackData.height,true,0xffffff) );
			spriteEntry.previewBitmap.bitmapData.copyPixels( spriteEntry.bitmap.bitmapData, sourceRect, flashPoint );
			
			numLoadingSprites--;
		}
		
		static private function ReadProperties(xmlList:XMLList, obj:Object ):void
		{
			if ( xmlList == null )
			{
				return;
			}
			for each (var xml:XML in xmlList)
			{
				if ( obj.properties == null )
				{
					obj.properties = new ArrayCollection();
				}
				if ( xml.name() == "type" )
				{
					var typeClass:Class;
					var type:String = String(xml.@["typeof"]);
					var valueString:String = String(xml.@value);
					var value:*;
					var customType:CustomPropertyType = null;
					if ( type == "String" )
					{
						typeClass = String;
						value = valueString;
					}
					else if ( type == "Float" )
					{
						typeClass = Number;
						value = Number(valueString);
					}
					else if ( type == "Int" )
					{
						typeClass = int;
						value = int(valueString);
					}
					else if ( type == "Boolean" )
					{
						typeClass = Boolean;
						value = valueString;	// Stores Booleans as just true/false strings.
					}
					else if ( type == "Custom" || type == "Filter" )
					{
						typeClass = CustomPropertyType;
						var customTypeIdx:int = int(xml.@customTypeIdx);
						customType = CustomPropertyType.TypesProvider.getItemAt(customTypeIdx) as CustomPropertyType;
						// Sanity check!
						if ( customType == null || customType.name != String(xml.@typeName) )
						{
							customType = CustomPropertyType.GetTypeByName( String(xml.@typeName) );
						}
						if ( customType )
						{
							var dataIdx:int = -1;
							if ( type == "Filter" )
							{
								typeClass = CustomPropertyFilterType;
								var customFilterType:CustomPropertyFilterType = customType as CustomPropertyFilterType;
								var dataId:int = int(xml.@dataId);
								if ( customFilterType )
								{
									dataIdx = customFilterType.indexOfData(dataId);
								}
							}
							if ( dataIdx != -1 )
							{
								// Sanity check!
								if ( customType.list[dataIdx].label != valueString )
								{
									dataIdx = -1;
								}
							}
							if ( dataIdx == -1 )
							{
								dataIdx = customType.indexOfLabel(valueString);
							}
							if ( dataIdx == -1 && customType.list.length )
							{
								dataIdx = 0;
							}
							if ( dataIdx != -1 )
							{
								value = customType.list[dataIdx];
							}
						}
					}
					else
					{
						typeClass = String;
						value = valueString;
						//throw new Error("Unknown property type: " + type );
					}
					var newPropType:PropertyType = new PropertyType( typeClass, String(xml.@name), value, customType );
					if ( xml.hasOwnProperty("@hidden") )
					{
						newPropType.Hidden = xml.@hidden == true;
					}
					obj.properties.addItemAt( newPropType, obj.properties.length );
				}
				else if( xml.name() == "dataOverride" && xml.@idx < obj.properties.length )
				{
					// Objects that can use dataOverrides will have already created properties for all base props.
					// Just find the entry and override the value.
					var prop:PropertyBase = obj.properties[ xml.@idx ];
					if ( prop.Type == String )
					{
						prop.Value = String(xml.@value);
					}
					else if ( prop.Type == Number )
					{
						prop.Value = Number(xml.@value);
					}
					else if ( prop.Type == int )
					{
						prop.Value = int(xml.@value);
					}
					else if ( prop.Type == Boolean )
					{
						prop.Value = Boolean(xml.@value == true);
					}
					else if ( prop.Type == CustomPropertyFilterType )
					{
						var filterType:CustomPropertyFilterType = prop.GetTypeObj() as CustomPropertyFilterType;
						if ( filterType && xml.hasOwnProperty("@dataId") )
						{
							dataIdx = filterType.indexOfData(int(xml.@dataId));
							if ( dataIdx != -1 )
							{
								prop.Value = filterType.list[dataIdx];
							}
						}
					}
					else if ( prop.Type == CustomPropertyType )
					{
						customType = prop.GetTypeObj() as CustomPropertyType;
						if ( customType )
						{
							dataIdx = customType.indexOfLabel(String(xml.@value));
							if ( dataIdx != -1 )
							{
								prop.Value = customType.list[dataIdx];
							}
						}
					}
				}
			}
		}
		
		static private function ReadLayerGroups( xmlList:XMLList, layerGroups:ArrayCollection, spriteEntries:SpriteEntry, instances:Vector.<PathInstanceData>, linkDictionary:Dictionary ):void
		{
			if ( xmlList == null )
			{
				return;
			}
			
			wantedLayerSelection = null;
			
			var app:App = App.getApp();
			
			for each (var xml:XML in xmlList)
			{
				var group:LayerGroup = new LayerGroup( xml.@name );
				layerGroups.addItem( group );
				group.SetScrollFactors( xml.@xScroll, xml.@yScroll );
				group.visible = (xml.@visible == "true");
				if ( xml.hasOwnProperty("@locked") == true )
					group.locked = xml.@locked == true;
				if ( xml.hasOwnProperty("@exports") == true )
					group.exports = xml.@exports == true;
				if ( xml.hasOwnProperty("@id") == true )
					group.id = uint(xml.@id);
				
				ReadProperties( xml.properties.*, group );
				ReadLayers( xml.*, group, group.children, layerGroups, spriteEntries, instances, linkDictionary );
				
				group.UpdateVisibility();
				
				if ( xml.@open == "true" )
				{
					app.layerTree.expandItem(group, true);
				}
				if ( xml.hasOwnProperty("@selected") )
				{
					SelectLayer(group);
				}
				if ( wantedLayerSelection )
				{
					app.layerTree.selectedItem = wantedLayerSelection;
					var currentState:EditorState = FlxG.state as EditorState;
					currentState.UpdateMapList();
					currentState.UpdateCurrentTileList( app.CurrentLayer );
					app.layerChangedCallback();
					wantedLayerSelection = null;
				}
			}
		}
		
		static private function SelectLayer( layer:LayerEntry ):void
		{
			wantedLayerSelection = layer;
			var app:App = App.getApp();
			app.layerTree.selectedItem = layer;
			var currentState:EditorState = FlxG.state as EditorState;
			currentState.UpdateMapList();
			currentState.UpdateCurrentTileList( app.CurrentLayer );
			app.layerChangedCallback();
		}
		
		static private function ReadLayers( xmlList:XMLList, group:LayerGroup, layerCollection:ArrayCollection, layerGroups:ArrayCollection, spriteEntries:SpriteEntry, instances:Vector.<PathInstanceData>, linkDictionary:Dictionary ):void
		{
			if ( xmlList == null )
			{
				return;
			}
			
			for each (var xml:XML in xmlList)
			{
				if ( xml.name() == "maplayer" )
				{
					var mapLayer:LayerMap = new LayerMap( group, xml.@name );
					var rowList:XMLList = xml.row;
					var mapString:String = new String();
					for each( var row:XML in rowList )
					{
						mapString += row;
						mapString += "\n";
					}
					var filename:String = xml.@tileset;
					var imageFile:File = currentLoadingFile.parent.resolvePath(filename);
					
					if ( xml.hasOwnProperty("@id") == true )
						mapLayer.id = uint(xml.@id);
					
					var xStagger:int = ( xml.hasOwnProperty("@xStagger") == true ) ? xml.@xStagger : 0;
					var tileSpacingX:int = ( xml.hasOwnProperty("@tileSpacingX") == true ) ? xml.@tileSpacingX : xml.@tileWidth;
					var tileSpacingY:int = ( xml.hasOwnProperty("@tileSpacingY") == true ) ? xml.@tileSpacingY : xml.@tileHeight;
					var tileOffsetX:int = ( xml.hasOwnProperty("@tileOffsetX") == true ) ? xml.@tileOffsetX : 0;
					var tileOffsetY:int = ( xml.hasOwnProperty("@tileOffsetY") == true ) ? xml.@tileOffsetY : 0;

					if( xml.hasOwnProperty("@selected") )
					{
						mapLayer.ImageLoadedCallback = SelectLayer;
					}
					mapLayer.CreateMapFromString( imageFile, mapString, xml.@tileWidth, xml.@tileHeight, tileSpacingX, tileSpacingY, xStagger, tileOffsetX, tileOffsetY );
					
					mapLayer.SetScrollFactors( xml.@xScroll, xml.@yScroll );
					mapLayer.visible = (xml.@visible == "true");
					mapLayer.UpdateVisibility();
					mapLayer.map.x = xml.@x;
					mapLayer.map.y = xml.@y;
					
					mapLayer.HasHits = (xml.@hasHits == "true");
					if( xml.hasOwnProperty("@drawIdx") == true )
						mapLayer.map.UpdateDrawIndex(xml.@drawIdx);
					if( xml.hasOwnProperty("@collideIdx") == true )
						mapLayer.map.collideIndex = xml.@collideIdx;
					if ( xml.hasOwnProperty("@eraseIdx") == true )
						mapLayer.EraseTileIdx = xml.@eraseIdx;
					if ( xml.hasOwnProperty("@locked") == true )
						mapLayer.locked = xml.@locked == true;
					if ( xml.hasOwnProperty("@exports") == true )
						mapLayer.exports = xml.@exports == true;
					if ( xml.hasOwnProperty("@isMaster") == true )
						mapLayer.SetMasterLayer( xml.@isMaster == true );
					if ( xml.hasOwnProperty("@mapType") == true )
						mapLayer.tilemapType = xml.@mapType;
					if ( xml.hasOwnProperty("@hasHeight") == true )
						mapLayer.hasHeight = xml.@hasHeight == true;
					if ( xml.hasOwnProperty("@repeatX") == true )
						mapLayer.map.repeatingX = xml.@repeatX == true;
					if ( xml.hasOwnProperty("@repeatY") == true )
						mapLayer.map.repeatingY = xml.@repeatY == true;
						
					if ( xml.anims.length() )
					{
						if ( xml.hasOwnProperty("@sharesTileAnims") == false || FlxTilemapExt.sharedTileAnims[imageFile] == null )
						{
							mapLayer.map.tileAnims = new Vector.<TileAnim>;
							for each( var anim:XML in xml.anims.anim )
							{
								var tileAnim:TileAnim = new TileAnim;
								mapLayer.map.tileAnims.push( tileAnim );
								tileAnim.Load(anim);
							}
							if ( xml.hasOwnProperty("@sharesTileAnims") == true )
							{
								mapLayer.SetSharesTileAnims(true);
							}
						}
					}
					
					if ( xml.hasOwnProperty("stacks") == true )
					{
						var stacksXml:XML = xml.stacks[0];
						mapLayer.map.numStackedTiles = 0;
						mapLayer.map.stackHeight = stacksXml.@height;
						mapLayer.map.stackedTiles = new Dictionary;
						for each( var stack:XML in stacksXml.stack )
						{
							var tileStr:String = String(stack);
							var tileIds:Array = tileStr.split(",");
							var tileInfo:StackTileInfo = new StackTileInfo;
							var maxTiles:int = 0;
							for each( var tileid:String in tileIds)
							{
								var tileData:Array = tileid.split(":");
								if ( tileData.length == 2 )
								{
									var key:uint = uint(tileData[0]);
									var value:uint = uint(tileData[1]);
									tileInfo.tiles[key] = value;
									maxTiles = Math.max(maxTiles, uint(tileData[0]));
								}
							}
							if ( maxTiles )
							{
								tileInfo.SetHeight( maxTiles );
								mapLayer.map.highestStack = Math.max(mapLayer.map.highestStack, maxTiles );
								mapLayer.map.stackedTiles[int(stack.@id)] = tileInfo;
								mapLayer.map.numStackedTiles++;
							}
						}
					}
					
					if ( xml.hasOwnProperty("@sharesTileProps") == false || FlxTilemapExt.sharedProperties[imageFile] == null )
					{
						if ( xml.hasOwnProperty("tileProperties") )
						{
							for each( var propXml:XML in xml.tileProperties.properties )
							{
								var temp:Object = new Object;
								temp.properties = null;
								ReadProperties( propXml.*, temp );
								mapLayer.map.propertyList.push( temp.properties );
							}
						}
						if ( xml.hasOwnProperty("@sharesTileProps") == true )
						{
							mapLayer.SetSharesTileProperties(true);
						}
					}
					layerCollection.addItem( mapLayer );
					ReadProperties( xml.properties.*, mapLayer );
				}
				else if ( xml.name() == "imagelayer" )
				{
					var imageLayer:LayerImage = new LayerImage( group, xml.@name );
					filename = xml.@file;
					imageFile = currentLoadingFile.parent.resolvePath(filename);
					imageLayer.SetImage( imageFile );
					imageLayer.SetScrollFactors( xml.@xScroll, xml.@yScroll );
					imageLayer.sprite.x = xml.@x;
					imageLayer.sprite.y = xml.@y;
					imageLayer.locked = xml.@locked == true;
					imageLayer.exports = xml.@exports == true;
					imageLayer.visible = (xml.@visible == "true");
					imageLayer.UpdateVisibility();
					imageLayer.SetOpacity( xml.@opacity );
					ReadProperties( xml.properties.*, imageLayer );
					layerCollection.addItem( imageLayer );
					if( xml.hasOwnProperty("@selected") )
						SelectLayer(imageLayer);
					if ( xml.hasOwnProperty("@id") == true )
						imageLayer.id = uint(xml.@id);
				}
				else if ( xml.name() == "spritelayer" )
				{
					var spriteLayer:LayerSprites = new LayerSprites( group, xml.@name );
					ReadAvatarLayer( xml, spriteLayer );
					
					var spriteList:XMLList = xml.sprite;
					for each( var spriteXml:XML in spriteList )
					{
						var sprite:EditorAvatar;
						var spriteTrailObject:SpriteTrailObject;
						var entry:SpriteEntry = null;
						if ( spriteXml.spriteTrailData.length() )
						{
							sprite = spriteTrailObject = new SpriteTrailObject( spriteLayer );
							spriteTrailObject.trailData.Load(spriteXml, spriteEntries, spriteIdxAtStart);
						}
						else
						{
							sprite = new EditorAvatar( spriteXml.@x, spriteXml.@y, spriteLayer );
							var idx:uint = uint( spriteXml.@idx );
							if ( spriteIdxRemapDictionary && spriteIdxRemapDictionary[ idx ] )
							{
								idx = spriteIdxRemapDictionary[ idx ];
							}
							else
							{
								idx = spriteIdxAtStart + idx;
							}
							entry = GetSpriteEntryFromIndex( spriteEntries, idx );
						}
						sprite.SetGUID( spriteXml.@guid );
						
						if( spriteXml.hasOwnProperty("@Z") == true )
							sprite.z = -spriteXml.@Z;
						sprite.scale.x = spriteXml.@scaleX;
						sprite.scale.y = spriteXml.@scaleY;
						if ( entry )
						{
							if ( spriteXml.hasOwnProperty("@frame") )
							{
								sprite.animIndex = spriteXml.@frame;
							}
							sprite.SetFromSpriteEntry( entry, true, true );
						}
						
						
						sprite.angle = spriteXml.@angle;
						sprite.Flipped = (spriteXml.@flipped == "true");
						if ( spriteXml.hasOwnProperty("@sheetX") && spriteXml.hasOwnProperty("@sheetY") )
						{
							var tx:Number = spriteXml.@sheetX;
							var ty:Number = spriteXml.@sheetY;
							sprite.TileOrigin = new FlxPoint( tx, ty );
						}
						if ( spriteXml.hasOwnProperty("@sheetWid") && spriteXml.hasOwnProperty("@sheetHt") )
						{
							var sx:Number = spriteXml.@sheetWid;
							var sy:Number = spriteXml.@sheetHt;
							sprite.TileDims = new FlxPoint(sx, sy );
							if ( spriteXml.hasOwnProperty("@width") && spriteXml.hasOwnProperty("@height") )
							{
								sprite.width = spriteXml.@width;
								sprite.height = spriteXml.@height;
							}
						}
						sprite.offset.x = - ( sprite.width - sprite.frameWidth ) / 2;
						sprite.offset.y = - ( sprite.height - sprite.frameHeight ) / 2;
						
						if ( sprite.TileOrigin || sprite.TileDims )
						{
							sprite.SetAsTile();
						}
						
						spriteLayer.sprites.add( sprite, true );
						ReadProperties( spriteXml.properties.*, sprite );
						
						if ( spriteXml.@attachedTo )
						{
							var attached:EditorAvatar = GetAvatarFromGUID( layerGroups, spriteXml.@attachedTo, true );
							if ( attached )
							{
								attached.AttachAvatar(sprite);
							}
						}
						
						if ( linkDictionary[sprite.GetGUID()] )
						{
							linkDictionary[ sprite.GetGUID() ] = sprite;
						}
					}
					ReadProperties( xml.properties.*, spriteLayer );
					layerCollection.addItem( spriteLayer );
					if( xml.hasOwnProperty("@selected") )
						SelectLayer(spriteLayer);
				}
				else if ( xml.name() == "shapelayer" )
				{
					var shapeLayer:LayerShapes = new LayerShapes( group, xml.@name );
					ReadAvatarLayer( xml, shapeLayer );
					
					var shapeList:XMLList = xml.shape;
					for each( var shapeXml:XML in shapeList )
					{
						var isText:Boolean = shapeXml.hasOwnProperty("@text") == true;
						var shape:ShapeObject;
						if ( isText )
						{
							var textObject:TextObject = new TextObject( shapeXml.@x, shapeXml.@y, shapeXml.@text, shapeLayer );
							shape = textObject;
							
							// Need to set these before generating the text.
							shape.width = shapeXml.@width;
							shape.height = shapeXml.@height;
							
							if ( shapeXml.hasOwnProperty("@bmpFile") )
							{
								var charSetType:String = shapeXml.@charSetType;
								var charSet:String = shapeXml.@charSet;
								if ( charSetType != "Other" )
								{
									var typeIndex:int = FlxBitmapFont.fontCharactersArray.indexOf(charSetType);
									if( typeIndex != -1 )
										charSet = FlxBitmapFont.fontSets[ typeIndex ];
								}
								// Uses a placeholder bmp until the image is loaded.
								textObject.bmpText = new FlxBitmapFont( new BitmapData(10,10), shapeXml.@charWid, shapeXml.@charHt, charSet, 0 );
								textObject.bmpText.width = 10;
								textObject.bmpText.height = 10;
								textObject.bmpText.scaler = shapeXml.@scale;
								textObject.bmpText.autoTrim = shapeXml.@autoTrim == true;
								textObject.bmpText.setText( shapeXml.@text, true, shapeXml.@xSpace, shapeXml.@ySpace, shapeXml.@align, false);
								filename = shapeXml.@bmpFile;
								textObject.bmpText.bmpFile = currentLoadingFile.parent.resolvePath(filename);
								textObject.bmpText.characterSetType = charSetType;
								textObject.bmpText.characterSet = charSet;
								textObject.bmpText.loadImage();
							}
							else
							{
								textObject.text.setFormat(shapeXml.@family, shapeXml.@fontsize, shapeXml.@color, shapeXml.@align);
								textObject.text.Resize(shape.width, shape.height);
								textObject.text.Regen();
							}
							shape = textObject;
						}
						else
						{
							var isCircle:Boolean = shapeXml.@type == "circle";
							shape = new ShapeObject( shapeXml.@x, shapeXml.@y, isCircle, shapeLayer );
						}
						
						if ( shapeXml.hasOwnProperty("@fillColor") == true )
						{
							shape.colourOverriden = true;
							shape.fillColour = (uint)(shapeXml.@fillColor) | 0xff000000;
						}
						if ( shapeXml.hasOwnProperty("@alpha") )
						{
							shape.colourOverriden = true;
							shape.alphaValue = shapeXml.@alpha;
						}
						if( shapeXml.hasOwnProperty("@Z") == true )
							shape.z = -shapeXml.@Z;
						shape.SetGUID( shapeXml.@guid );
						shape.width = shapeXml.@width;
						shape.height = shapeXml.@height;
						if ( shapeXml.hasOwnProperty("@scaleX") )
							shape.scale.x = shapeXml.@scaleX;
						else
							shape.scale.x = shape.width / shape.frameWidth;
						if ( shapeXml.hasOwnProperty("@scaleY") )
							shape.scale.y = shapeXml.@scaleY;
						else
							shape.scale.y = shape.height / shape.frameHeight;
						shape.offset.x = - ( shape.width - shape.frameWidth ) / 2;
						shape.offset.y = - ( shape.height - shape.frameHeight ) / 2;
						
						shape.angle = shapeXml.@angle;
						shapeLayer.sprites.add( shape, true );
						ReadProperties( shapeXml.properties.*, shape );
						
						if ( linkDictionary[shape.GetGUID()] )
						{
							linkDictionary[ shape.GetGUID() ] = shape;
						}
					}
					ReadProperties( xml.properties.*, shapeLayer );
					layerCollection.addItem( shapeLayer );
					if( xml.hasOwnProperty("@selected") )
						SelectLayer(shapeLayer);
				}
				else if ( xml.name() == "pathlayer" )
				{
					var pathLayer:LayerPaths = new LayerPaths( group, xml.@name );
					ReadAvatarLayer( xml, pathLayer );

					var pathList:XMLList = xml.path;
					for each( var pathXml:XML in pathList )
					{
						var path:PathObject = new PathObject( pathXml.@x, pathXml.@y, ( pathXml.@curved == "true" ), pathLayer );
						path.SetGUID( pathXml.@guid );
						if( pathXml.hasOwnProperty("@Z") == true )
							path.z = -pathXml.@Z;
						path.IsClosedPoly = (pathXml.@closed == "true" );
						var nodeList:XMLList = pathXml.node;
						if ( pathXml.@instanced == "false" )
						{
							ReadPathNodes( nodeList, path.nodes, path.IsCurved );
							path.Invalidate();
						}
						else
						{
							var instanceId:int = pathXml.@instanceId;
							if ( instanceId < instances.length )
							{
								instances[ instanceId ].avatars.push( path );
							}
							else
							{
								path.instancedShapes = new Vector.<PathObject>();
								path.instancedShapes.push( path );
								instances.push( new PathInstanceData( path.instancedShapes ) );
							}
						}
						
						if ( pathXml.hasOwnProperty("events") )
						{
							for each( var eventXml:XML in pathXml.events.event )
							{
								var pathEvent:PathEvent = new PathEvent(eventXml.@x, eventXml.@y, pathLayer, path);
								pathEvent.percentInSegment = eventXml.@percent;
								pathEvent.segmentNumber = eventXml.@segment;
													
								ReadProperties( eventXml.properties.*, pathEvent );
								path.AddPathEvent(pathEvent);
							}
						}
						
						pathLayer.sprites.add( path, true );
						ReadProperties( pathXml.properties.*, path );
						
						if ( linkDictionary[path.GetGUID()] )
						{
							linkDictionary[ path.GetGUID() ] = path;
						}
						
						if ( pathXml.@attachedChild )
						{
							attached = GetAvatarFromGUID( layerGroups, pathXml.@attachedChild, false );
							if ( attached )
							{
								path.AttachAvatar(attached);
							}
						}
					}
					ReadProperties( xml.properties.*, pathLayer );
					layerCollection.addItem( pathLayer );
					if( xml.hasOwnProperty("@selected") )
						SelectLayer(pathLayer);
				}
			}
		}
		
		private static function ReadAvatarLayer( xml:XML, layer:LayerAvatarBase ):void
		{
			layer.SetScrollFactors( xml.@xScroll, xml.@yScroll );
			layer.visible = (xml.@visible == "true");
			layer.UpdateVisibility();
			if ( xml.hasOwnProperty("@locked") == true )
				layer.locked = xml.@locked == true;
			if ( xml.hasOwnProperty("@exports") == true )
				layer.exports = xml.@exports == true;
			if ( xml.hasOwnProperty("@aligned") == true )
				layer.AlignedWithMasterLayer = xml.@aligned == true;
			if ( xml.hasOwnProperty("@sort") == true )
				layer.AutoDepthSort = xml.@sort == true;
			if ( xml.hasOwnProperty("@id") == true )
				layer.id = uint(xml.@id);
		}
		
		private static function ReadPathNodes( nodeListXml:XMLList, nodes:Vector.<PathNode>, curved:Boolean ):void
		{
			nodes.length = 0;
			for each( var nodeXml:XML in nodeListXml )
			{
				var node:PathNode = new PathNode( nodeXml.@x, nodeXml.@y, curved );
				if ( curved )
				{
					node.tangent1.create_from_points( nodeXml.@tan1x, nodeXml.@tan1y );
					node.tangent2.create_from_points( nodeXml.@tan2x, nodeXml.@tan2y );
				}
				nodes.push( node );
			}
		}
		
		private static function GetAvatarFromGUID( layerGroups:ArrayCollection, guid:String, isPath:Boolean ):EditorAvatar
		{
			var i:uint = layerGroups.length;
			while( i-- )
			{
				var group:LayerGroup = layerGroups[i];
				var j:uint = group.children.length;
				while ( j-- )
				{
					var layer:LayerAvatarBase = null;
					if ( isPath )
					{
						var layerPath:LayerPaths = group.children[j] as LayerPaths;
						if ( layerPath )
						{
							layer = layerPath;
						}
					}
					else
					{
						var layerSprites:LayerSprites = group.children[j] as LayerSprites;
						if ( layerSprites )
						{
							layer = layerSprites;
						}
					}
					if ( layer )
					{
						var k:uint = layer.sprites.members.length;
						while ( k-- )
						{
							var avatar:EditorAvatar = layer.sprites.members[k];
							if ( avatar.GetGUID() == guid )
							{
								return avatar;
							}
						}
					}
				}
			}
			return null;
		}
		
		public static function GetSpriteEntryFromIndex( spriteEntry:SpriteEntry, index:uint ):SpriteEntry
		{
			if ( spriteEntry.children == null )
			{
				if ( spriteEntry.id == index )
				{
					return spriteEntry;
				}
			}
			
			for each( var entry:SpriteEntry in spriteEntry.children )
			{
				var result:SpriteEntry = GetSpriteEntryFromIndex( entry, index );
				if ( result != null )
				{
					return result;
				}
			}
			
			return null;
		}
		
		static private function GenerateLinksDictionary( linksXml:XMLList, linkDictionary:Dictionary ):void
		{
			var dummyObject:Object = new Object;
			for each( var linkXml:XML in linksXml )
			{
				linkDictionary[String(linkXml.@from)] = dummyObject;
				linkDictionary[String(linkXml.@to)] = dummyObject;
			}
		}
		
		static private function AddLinks( linksXml:XMLList, linkDictionary:Dictionary ):void
		{
			for each( var linkXml:XML in linksXml )
			{
				var fromAvatar:EditorAvatar = linkDictionary[String(linkXml.@from)] as EditorAvatar;
				var toAvatar:EditorAvatar = linkDictionary[String(linkXml.@to)] as EditorAvatar;
				if ( fromAvatar && toAvatar )
				{
					var link:AvatarLink = AvatarLink.GenerateLink(fromAvatar, toAvatar);
					ReadProperties(linkXml.properties.*, link);
				}
			}
		}
		
		static private function UpdateInstances( instancesXml:XMLList, instances:Vector.<PathInstanceData> ):void
		{
			if ( instancesXml == null )
			{
				return;
			}
			var i:uint = 0;
			for each (var entryXml:XML in instancesXml)
			{
				var firstAvatar:PathObject = null;
				var avatars:Vector.<PathObject> = instances[i].avatars;
				for ( var j:uint = 0; j < avatars.length; j++ )
				{
					if ( firstAvatar == null )
					{
						firstAvatar = avatars[j];
						firstAvatar.SetInstanced( null );
						ReadPathNodes( entryXml.node, firstAvatar.nodes, firstAvatar.IsCurved );
					}
					else
					{
						var avatar:PathObject = avatars[j];
						avatar.SetInstanced( firstAvatar );
					}
					
				}
				if ( firstAvatar )
				{
					firstAvatar.Invalidate();
				}
				i++;
			}
		}
		
		static private function ReadTileMatrix( xml:XML, app:App, append:Boolean ):void
		{
			var tileMatrix:XMLList = xml.tileMatrix;
			if ( tileMatrix == null || tileMatrix.length() == 0 )
			{
				return;
			}
			
			var currentMatrix:int = -1;
			if ( !append || app.tileMatrices.length == 0 )
			{
				if( tileMatrix.hasOwnProperty("@currentMatrix") )
				{
					currentMatrix = tileMatrix.@currentMatrix;
				}
				var rowCount:uint = tileMatrix.@rows;
				var colCount:uint = tileMatrix.@cols;
				app.tileMatrix.Resize(colCount, rowCount);
				EditorTypeTileMatrix.IgnoreClearTiles = Global.windowedApp.tileMatrix.IgnoreClearTiles.selected = (tileMatrix.@ignoreClear == true);
				EditorTypeTileMatrix.IgnoreMapEdges = Global.windowedApp.tileMatrix.IgnoreMapEdges.selected = (tileMatrix.@ignoreMapEdges == true);
				EditorTypeTileMatrix.RandomizeMiddleTiles = Global.windowedApp.tileMatrix.RandomizeMiddleTiles.selected = (tileMatrix.@randomizeMiddle == true);
				if ( tileMatrix.hasOwnProperty("@allowSpecialTiles") )
				{
					EditorTypeTileMatrix.AllowSpecialTiles = Global.windowedApp.tileMatrix.AllowSpecialTiles.selected = (tileMatrix.@allowSpecialTiles == true);
					Global.windowedApp.tileMatrix.AllowSpecialTilesChanged();
				}
				
				app.tileMatrix.tilesetImageFile = null;// "";
				if ( tileMatrix.hasOwnProperty("@tileset") == true )
				{
					var imageFile:File = currentLoadingFile.parent.resolvePath(tileMatrix.@tileset);
					app.tileMatrix.tilesetImageFile = imageFile;
				}
				
				var i:uint = 0;
				var rowList:XMLList = tileMatrix.row;
				for each( var row:XML in rowList )
				{
					for each( var tile:XML in row.tile )
					{
						app.tileMatrix.SetTileIdForIndex(i, int(String(tile)), new BitmapData(1, 1));
						i++;
					}
				}
				app.tileMatrixWindow.RecheckDimensions();
				app.tileMatrix.MatchToFirstSuitableMap();
			}
			
			ReadTileMatrixConnections(tileMatrix.specialConnections, append);
			
			// Load the saved matrix list.
			
			var matrixList:XMLList = xml.tileMatrixData;
			if ( matrixList != null || matrixList.length() != 0 )
			{
				for each( var data:XML in matrixList )
				{
					var newMatrix:TileMatrixData = new TileMatrixData;
					newMatrix.name = data.@name;
					newMatrix.numColumns = data.@cols;
					newMatrix.numRows = data.@rows;
					newMatrix.IgnoreClearTiles = data.@ignoreClear == true;
					newMatrix.IgnoreMapEdges = data.@ignoreMapEdges == true;
					newMatrix.RandomizeMiddleTiles = data.@randomizeMiddle == true;
					if ( data.hasOwnProperty("@allowSpecialTiles") )
					{
						newMatrix.AllowSpecialTiles = (data.@allowSpecialTiles == true);
					}
					if ( data.hasOwnProperty("@tileset") == true )
					{
						imageFile = currentLoadingFile.parent.resolvePath(data.@tileset);
						newMatrix.tilesetImageFile = imageFile;
					}
					// Should only be one tiles entry.
					for each( var tiles:XML in data.tiles )
					{
						var tileStr:String = String(tiles);
						var tileIds:Array = tileStr.split(",");
						for each( var id:String in tileIds)
						{
							newMatrix.tileIds.push(uint(id));
						}
					}
					
					newMatrix.SpecialTileRows.length = 0;
					for each( var connections:XML in data.connections )
					{
						newMatrix.HasConnectionData = true;
						var rowData:SpecialTileRowData = new SpecialTileRowData();
						rowData.set = TileConnectionList.tileConnectionLists[connections.@set];
						for each( tiles in connections.tiles )
						{
							tileStr = String(tiles);
							tileIds = tileStr.split(",");
							for each( id in tileIds)
							{
								rowData.tiles.push(uint(id));
							}
						}
						newMatrix.SpecialTileRows.push(rowData);
					}
					
					newMatrix.MatchToFirstSuitableMap();
					
					app.tileMatrices.addItem(newMatrix);
				}
			}
			
			if ( !append )
			{
				if ( currentMatrix != -1 )
				{
					// Ensure that the current matrix is the one that's selected.
					app.tileMatrixWindow.MatrixChooser.selectedIndex = currentMatrix;
					app.tileMatrixWindow.currentMatrixData = app.tileMatrices.getItemAt(currentMatrix) as TileMatrixData;
				}
				else
				{
					// Add this as a new matrix entry to cope with backwards compatibility.
					newMatrix = new TileMatrixData();
					newMatrix.name = "matrix" + (app.tileMatrices.length + 1);
					// The matrix can be completely empty becaue it will be autosaved anyway.
					app.tileMatrices.addItem(newMatrix);
					app.tileMatrixWindow.currentMatrixData = newMatrix;
					app.tileMatrixWindow.setSavedMatrixData(newMatrix, true);
					app.tileMatrixWindow.MatrixChooser.selectedIndex = app.tileMatrices.length - 1;
				}
			}
		}
		
		static private function ReadTileMatrixConnections(SpecialConnections:XMLList, append:Boolean ):void
		{
			if ( SpecialConnections == null || SpecialConnections.length() == 0 )
			{
				return;
			}
			
			// Input the connection sets.
			var sets:XMLList = SpecialConnections.sets;
			
			var tiles:Vector.<TileConnections>;
			
			for each( var connections:XML in sets.connections )
			{
				tiles = new Vector.<TileConnections>();
				for each( var entry:XML in connections.entry )
				{
					var green:uint = uint(entry.@green);
					var red:uint = uint(entry.@red);
					tiles.push(new TileConnections(green, red));
				}
				TileConnectionList.tileConnectionLists.addItem(new TileConnectionList(connections.@name, tiles));
			}
			
			if ( !append || Global.windowedApp.tileMatrix.SpecialTilesRows.getChildren().length == 0)
			{
				// Output the rows being used.
				for each( var row:XML in SpecialConnections.rows.row )
				{
					var newRow:SpecialTilesRow = new SpecialTilesRow();
					newRow.RowRemoved = Global.windowedApp.tileMatrix.OnSpecialTilesRemoved;
					newRow.SetRenamed = Global.windowedApp.tileMatrix.OnSpecialSetRenamed;
					newRow.SetRemoved = Global.windowedApp.tileMatrix.OnSpecialSetRemoved;
					newRow.SetRemoved = Global.windowedApp.tileMatrix.OnSpecialSetRemoved;
					newRow.initTileConnectionsIndex = row.@set;
					newRow.initTileIds = [];
					for each( var tileId:XML in row.tiles.id )
					{
						newRow.initTileIds.push( uint(tileId) )
					}
					Global.windowedApp.tileMatrix.SpecialTilesRows.addChild(newRow);
				}
			}
		}
		
		static private function ReadTileBrushes( TileBrushes:XMLList ):void
		{			
			if ( App.getApp().brushesWindow )
			{
				App.getApp().brushesWindow.ListBrushes.validateNow();
			}
			
			if ( TileBrushes == null || TileBrushes.length() == 0 )
			{
				return;
			}
			
			for each( var brushXml:XML in TileBrushes.brush )
			{
				var layerData:TileEditorLayerEntry = new TileEditorLayerEntry(null);
				var imageFile:File = currentLoadingFile.parent.resolvePath(brushXml.@tileset);
				layerData.imageFile = imageFile;
				for each( var rowXml:XML in brushXml.row )
				{
					var row:TileEditorRowEntry = new TileEditorRowEntry(rowXml.@y);
					layerData.rows.push(row);
					for each( var tileXml:XML in rowXml.tile )
					{
						var tile:TileEditorTileEntry = new TileEditorTileEntry(tileXml.@x);
						tile.tileId = tileXml.@id;
						row.tiles.push(tile);
					}
				}
				var data:Object = { label:brushXml.@name, entry:layerData };
				TileBrushesWindow.brushes.addItem(data);
				
			}
		}
		
		static private function ReadBookmarks( xml:XML, app:App ):void
		{
			var i:uint = 0;
			for each( var bookmarkXml:XML in xml.bookmarks.bookmark )
			{
				if ( bookmarkXml.@enabled == true)
				{
					app.bookmarks[i].gotoMenu.enabled = true;
					app.bookmarks[i].location = new FlxPoint( -bookmarkXml.@x, -bookmarkXml.@y );
				}
				i++;
			}
		}
		
		//} endregion
		
		static private function ResolvePath( sourceFile:File, targetFile:File ):String
		{
			var imageFileName:String = sourceFile.getRelativePath( targetFile, true );
			if ( imageFileName == null )
			{
				var f:File = sourceFile.resolvePath( targetFile.url );
				if ( f )
				{
					imageFileName = f.nativePath;
				}
			}
			return imageFileName;
		}
		
	}

}

import com.Game.PathObject;

internal class PathInstanceData
{
	public var avatars:Vector.<PathObject> = null;
	
	public function PathInstanceData( instancedShapes:Vector.<PathObject> )
	{
		avatars = instancedShapes;
	}
}
