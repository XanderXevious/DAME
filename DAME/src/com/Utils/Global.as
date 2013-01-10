package com.Utils
{
	import com.Editor.EditorTypeDraw;
	import com.Editor.EditorTypeSprites;
	import com.Editor.EditorTypeTiles;
	import com.Editor.GuideLayer;
	import com.FileHandling.ExporterSetting;
	import com.Game.SpriteTrailData;
	import com.Tiles.FlxTilemapExt;
	import com.Tiles.TileConnectionList;
	import com.UI.DameStatusBar;
	import com.UI.Docking.DockablePage;
	import com.UI.Docking.DockableTabNav;
	import com.UI.Docking.DockManager;
	import com.UI.ExtendedDividedBox;
	import com.UI.PopupWindowManager;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.NativeWindow;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileStream;
	import flash.filesystem.FileMode;
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequestHeader;
	import flash.utils.clearInterval;
	import flash.utils.Dictionary;
	import flash.utils.setInterval;
	import mx.controls.Menu;
	import mx.core.Container;
	import org.flixel.FlxState;
	import XML;
	import flash.xml.XMLNode;
	import flash.xml.XMLNodeType;
	import flash.xml.XMLDocument;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import com.UI.AlertBox;
	import mx.core.WindowedApplication;
	import mx.controls.PopUpMenuButton;
	import com.UI.TilePalette;
	import com.UI.TileMatrix;
	import com.UI.Docking.DockableWindow;
	import mx.containers.dividedBoxClasses.BoxDivider;
	
	//import com.UI.LogWindow;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Global
	{
		public static var SelectionColour:uint = 0xffffffff;
		public static var SelectionColourOtherLayer:uint = 0x55ffffff;
		
		public static var PathColour:uint = 0xffffffff;
		public static var PathNodeColourSelected1:uint = 0xff00ff00;
		public static var PathTangentColour:uint = 0xffff0000;
		public static var PathTangentColourSelected1:uint = 0xffffff00;
		public static var PathTangentColourSelected2:uint = 0xffff0000;
		public static var PathColourInstanced:uint = 0xff00ffff;
		public static var PathNodeColourInstancedSelected1:uint = 0xff00ff00;
		
		public static var MapBoundsColour:uint = 0xff000000;
		public static var TileUnderCursorColour:uint = 0x99ffffff;
		public static var TileUnderCursorColourStackBase:uint = 0x77ffffff;
		
		public static var TileDrawnColour1:uint = 0x66ffffff;
		public static var TileDrawnColour2:uint = 0x11000000;
		
		public static var GridLineColour:uint = 0x77ff0000;
		public static var RegionGridLineColour:uint = 0xccffffff;
		public static var ShapeColour:uint = 0xffff9966;	// Orange
		public static var ShapeOutlineColour:uint = 0xffffff00;
		public static var ShapeAlpha:Number = 0.5;
		
		public static var PathEventOutlineColour:uint = 0xff0000ff;
		public static var PathEventColour:uint = 0xffeeeeff;
		
		public static var TileTintColour:uint = 0xffff66;
		public static var TileTintAlpha:Number = 0.6;
		
		public static var CurrentMapDataFile:File = File.documentsDirectory;
		public static var CurrentProjectFile:File = File.documentsDirectory;
		public static var CurrentSettingsFile:File = null;
		public static var CurrentImageFile:File = File.documentsDirectory;
		public static var StatusBarVisible:Boolean = true;
		public static var MarqueesVisible:Boolean = true;
		public static var AllowZoomOut:Boolean = false;
		public static var SaveExporterWithProject:Boolean = true;
		
		
		public static var SelectFromCurrentLayerOnly:Boolean = true;
		
		public static var windowedApp:application = null;
		public static var MyStatusBar:DameStatusBar = null;
		
		public static var DisableAutoUpdates:Boolean = false;
		
		public static const MaxFileHistory:uint = 10;
		
		public static var RecentFiles:Vector.<String> = new Vector.<String>();
		
		public static var ExporterSettings:ExporterData = new ExporterData;
		public static var ProjectExporterSettings:ExporterData = new ExporterData;
		public static var CustomExporterPath:File = File.documentsDirectory;
		
		public static var OnionSkinEnabled:Boolean = false;
		public static var OnionSkinAlpha:Number = 0.5;
		public static var SameGroupOnionSkinAlpha:Number = 0.5;
		public static var UseFlashShapeRenderer:Boolean = true;
		public static var DisplayLayersFirstOnTop:Boolean = false;
		
		public static var DrawTilesWithoutHeight:Boolean = false;
		public static var DrawCurrentTileWithHeight:Boolean = true;
		
		public static var DrawCurrentTileAbove:Boolean = false;
		
		public static var PlayAnims:Boolean = true;
		
		public static var spriteTrailData:SpriteTrailData = new SpriteTrailData;
		
		// Default colours are based on Arne's 16 colour palette.
		public static var colorGrid:Array = ResetColorGrid();
		
		public static var dockManager = new DockManager();
		
		public static var currentTheme:String = "";
		
		// AS3 bitmap limits.
		static public var MaxImageSize:int = 7000;		
		
		public static var ShowOverwritingImageAlert:Boolean = true;
		public static var KeepTileMatrixOnExitAnswer:uint = 0;
		public static var UseCheckeredTilePalette:Boolean = true;
		public static var TilePaletteBackgroundColour:uint = 0xffffff;
		
		public static var AllowEditingTemplateLayerList:Boolean = true;
		public static var ForceAddingTemplatedMapsOnly:Boolean = false;
		public static var ForceAddingTemplatedLayersOnly:Boolean = false;
		public static var PreventEditingMapTileset:Boolean = false;
		public static var PreventEditingSprites:Boolean = false;
		public static var SaveSpritesSeparately:Boolean = false;
		public static var SavePropertyTypesSeparately:Boolean = false;
		public static var SaveLayerTemplatesSeparately:Boolean = false;
		public static var SaveTileMatrixSeparately:Boolean = false;
		public static var SaveTileBrushesSeparately:Boolean = false;
		public static var SaveGuidesSeparately:Boolean = false;
		
		//public static var RememberedAlerts:Dictionary = new Dictionary;	// e.g. RememberedAlerts[alertId] = AlertBox.YES
		
		public static function ResetColorGrid():Array
		{
			colorGrid = [ 0x000000, 0x9c9c9c, 0xffffff, 0xbe2532, 0xe06e8a, 0x483b2a, 0xa36323, 0xeb8833, 0xf6e16d, 0x2e474d, 0x42881e, 0xa2cd2e, 0x1a2531, 0x025683, 0x33a2f1, 0xb2dcee ];
			return colorGrid;
		}
		
		public static function CalculateSpecificShapeOutlineColour( fillColour:uint ):uint
		{
			var red:uint = (fillColour >> 16) & 0xff;
			var green:uint = (fillColour >> 8) & 0xff;
			var blue:uint = fillColour & 0xff;
			
			red = ( red > 0x99 ) ? red - 0x33 : red + 0x33;
			green = ( green > 0x99 ) ? green - 0x33 : green + 0x33;
			blue = ( blue > 0x99 ) ? blue - 0x33 : blue + 0x33;
			return ( (red << 16 ) | ( green << 8 ) | ( blue ) | 0xff000000 );
		}
		
		public static function CalculateShapeOutlineColour():void
		{
			ShapeOutlineColour = CalculateSpecificShapeOutlineColour( ShapeColour );
		}
		
		public static function RememberFile( filename:String ):void
		{
			var index:int = RecentFiles.indexOf( filename );
			if ( index != -1 )
			{
				RecentFiles.splice(index, 1);
			}
			else if ( RecentFiles.length == MaxFileHistory )
			{
				RecentFiles.splice(0, 1);
			}
			RecentFiles.push(filename);
			App.getApp().RefreshRecentFiles();
		}
		
		public static function SaveSettings(window:NativeWindow, closeOnSave:Boolean):void
		{
			//LogWindow.LogWriteLine("saving settings");
			//LogWindow.LogWriteLine( File.applicationStorageDirectory.nativePath + "/settings.xml");
			var file:File = File.applicationStorageDirectory.resolvePath("settings.xml");
			var stream:FileStream = new FileStream();
			stream.open(file, FileMode.WRITE);
			stream.addEventListener(IOErrorEvent.IO_ERROR, writeIOErrorHandler);
			var newXML:XMLDocument = new XMLDocument();
			XML.prettyIndent = 2;
			
			var xml:XML = 
				<settings>
				</settings>;
				
			var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
			// Define the Namespace (there is only one by default in the application descriptor file)
			var air:Namespace = appXML.namespaceDeclarations()[0];
			var version:String = appXML.air::version;
			xml.appendChild( <version>{ version }</version> );
			
			if( window.displayState != "minimized" )
			{
				var isMaximized:Boolean = ( window.displayState == "maximized" );
				if ( isMaximized )
				{
					window.restore();
					// Need to wait for the window to no longer be maximized so that all divider size calculations are
					// done from normal window size. This is because when we set the divider sizes they need to be the 
					// un-maxed ones, so that they scale up correctly.
					var intervalId:uint = setInterval(waitForRestore, 200);
					function waitForRestore( ):void
					{
						if ( window.displayState != "maximized" )
						{
							clearInterval(intervalId);
							continueSaving();
						}
					}
				}
				else
				{
					continueSaving();
				}
			}
			else
			{
				continueSaving();
			}
					
			function continueSaving():void
			{
				if( window.displayState != "minimized" )
				{
					var winXml:XML = ( < window x = { window.x }
									y = { window.y }
									width = { window.width } 
									height = { window.height } 
									maximized = { isMaximized } /> );
					xml.appendChild( winXml );
				}
				
				var fileHistoryXml:XML = < recentFiles />;
				for ( var i:uint = 0; i < RecentFiles.length; i++ )
				{
					var filename:String = RecentFiles[i];
					fileHistoryXml.appendChild( <file>{ filename }</file> );
				}
				xml.appendChild( fileHistoryXml );
				
				//LogWindow.LogWriteLine("Save last exporter as " + LastExporterName);
				
				var exporterXml:XML = ExporterSettings.Save(xml, "exporter", true);
				exporterXml[ "@customExporterPath" ] = CustomExporterPath ? CustomExporterPath.nativePath : "";
				exporterXml[ "@saveWithProject" ] = SaveExporterWithProject;
				
				xml.appendChild( < projectPath > { CurrentProjectFile.nativePath } </projectPath> );
				xml.appendChild( < mapDataPath > { CurrentMapDataFile.nativePath } </mapDataPath> );
				xml.appendChild( < imagePath > { CurrentImageFile.nativePath } </imagePath> );
				xml.appendChild( < selectFromCurrentLayerOnly > { SelectFromCurrentLayerOnly } </selectFromCurrentLayerOnly> );
				xml.appendChild( < theme > { currentTheme } </theme> );
				
				xml.appendChild( < disableUpdates > { DisableAutoUpdates } </disableUpdates> );
				xml.appendChild( < statusBar > { StatusBarVisible } </statusBar> );
				xml.appendChild( < marqueesVisible > { MarqueesVisible } </marqueesVisible> );
				xml.appendChild( < onionSkin > { OnionSkinEnabled } </onionSkin> );
				xml.appendChild( < onionSkinAlpha > { OnionSkinAlpha } </onionSkinAlpha> );
				xml.appendChild( < sameGroupOnionSkinAlpha > { SameGroupOnionSkinAlpha } </sameGroupOnionSkinAlpha> );
				xml.appendChild( < firstLayersTop > { DisplayLayersFirstOnTop } </firstLayersTop > );
				xml.appendChild( < allowZoomOut > { AllowZoomOut } </allowZoomOut > );
				xml.appendChild( < drawTilesWithoutHeight > { DrawTilesWithoutHeight } </drawTilesWithoutHeight > );
				xml.appendChild( < checkeredTilePalette > { UseCheckeredTilePalette } </checkeredTilePalette > );
				xml.appendChild( < tilePaletteBackgroundColour > { Misc.uintToHexStr6Digits(TilePaletteBackgroundColour) } </tilePaletteBackgroundColour> );
				xml.appendChild( < drawCurrentTileAbove > { DrawCurrentTileAbove } </drawCurrentTileAbove > );
				xml.appendChild( < playAnims > { PlayAnims } </playAnims > );
				
				xml.appendChild( < bgColour > { FlxState.bgColor } </bgColour> );
				xml.appendChild( < shapeColour > { ShapeColour } </shapeColour> ); 
				xml.appendChild( < shapeAlpha > { ShapeAlpha } </shapeAlpha> );
				xml.appendChild( < pathColour > { PathColour } </pathColour> );
				xml.appendChild( < pathColourInstanced > { PathColourInstanced } </pathColourInstanced> );
				
				xml.appendChild( < showOverwritingImageAlert > { ShowOverwritingImageAlert } </showOverwritingImageAlert> );
				if ( KeepTileMatrixOnExitAnswer )
				{
					xml.appendChild( < keepTileMatrixOnExit > { KeepTileMatrixOnExitAnswer } </keepTileMatrixOnExit> );
				}
				
				SaveGridSettings( xml );
				
				xml.appendChild( < selectHiddenTiles > { EditorTypeTiles.SelectHiddenTiles } </selectHiddenTiles> );
				xml.appendChild( < infiniteStacking > { EditorTypeTiles.InfiniteStacking } </infiniteStacking> );
				
				var drawXml:XML = < drawing />;
				
				drawXml.appendChild( < colour > { EditorTypeDraw.DrawColor } </colour> );
				drawXml.appendChild( < alpha > { EditorTypeDraw.DrawAlpha } </alpha> );
				drawXml.appendChild( < noise > { EditorTypeDraw.DrawNoise } </noise> );
				drawXml.appendChild( < perlin > { EditorTypeDraw.DrawPerlin } </perlin> );
				drawXml.appendChild( < thickness > { EditorTypeDraw.LineThickness } </thickness> );
				drawXml.appendChild( < locked > { EditorTypeDraw.LockedTileMode } </locked> );
				drawXml.appendChild( < drawOnBase > { EditorTypeDraw.DrawOnBaseOnly } </drawOnBase> );
				drawXml.appendChild( < perlinscale > { EditorTypeDraw.PerlinScale } </perlinscale> );
				drawXml.appendChild( < fillTolerance > { EditorTypeDraw.FloodFillTolerance } </fillTolerance> );
				var drawStyle:String = "freehand";
				if ( EditorTypeDraw.DrawLines )
					drawStyle = "lines";
				else if ( EditorTypeDraw.DrawCircles )
					drawStyle = "circles";
				else if ( EditorTypeDraw.DrawEllipses )
					drawStyle = "ellipses";
				else if ( EditorTypeDraw.DrawBoxes )
					drawStyle = "boxes";
				else if ( EditorTypeDraw.DrawPolyLines )
					drawStyle = "polygons";
				drawXml.appendChild( < drawStyle > { drawStyle } </drawStyle> );
				if ( EditorTypeDraw.DrawNewTiles )
					drawXml.appendChild( < drawNewTiles > { true } </drawNewTiles> );
				drawXml.appendChild( < fillColour > { Misc.uintToHexStr6Digits(EditorTypeDraw.ShapeFillColor) } </fillColour> );
				drawXml.appendChild( < fillAlpha > { EditorTypeDraw.ShapeFillAlpha } </fillAlpha> );
				
				if ( EditorTypeDraw.drawOrderMode == EditorTypeDraw.DRAW_BEHIND )
				{
					drawXml.appendChild( < order > { "BEHIND" } </order> );
				}
				else if ( EditorTypeDraw.drawOrderMode == EditorTypeDraw.DRAW_ABOVE )
				{
					drawXml.appendChild( < order > { "ABOVE" } </order> );
				}
				else
				{
					drawXml.appendChild( < order > { "ALWAYS" } </order> );
				}
				xml.appendChild( drawXml );
				
				SaveLayout( xml, window );
				
				SaveColorGrid( xml );
				
				SaveOptions( xml );
					
				var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
				outputString += xml.toString();
				outputString = outputString.replace(/\n/g, File.lineEnding);
				
				stream.writeUTFBytes(outputString);
				stream.close();
				
				if ( closeOnSave )
				{
					NativeApplication.nativeApplication.exit(); // closes child windows as well.
				}
			}
		}
		
		public static function SaveLayout(xml:XML, window:NativeWindow):void
		{
			var layoutXml:XML = < layout />;
			xml.appendChild( layoutXml );
			
			var divider:ExtendedDividedBox = Global.windowedApp.MainArea;
			var dock:DockablePage = null;
			
			var dividerXml:XML = SaveLayoutForDivider( layoutXml, divider );
			if ( dividerXml )
			{
				dividerXml[ "@id" ] = divider.id;
			}
			
			for ( var i:int = 0; i < PopupWindowManager.toolPopups.length; i++ )
			{
				var dockWindow:DockableWindow = PopupWindowManager.toolPopups[i] as DockableWindow;
				if ( dockWindow )
				{
					var windowXml:XML = < window title = { dockWindow.title }
												x = { dockWindow.nativeWindow.x } 
												y = { dockWindow.nativeWindow.y }
												width = { dockWindow.width }
												height = { dockWindow.height }
												minimized = { dockWindow.Minimized } />
					layoutXml.appendChild( windowXml );
					if ( dockWindow.container )
					{
						SaveLayoutForChildren( windowXml, dockWindow.container as Container );
					}
				}
			}
		}
		
		private static function SaveLayoutForDivider( parentXml:XML, divider:ExtendedDividedBox ):XML
		{
			if ( !divider )
				return null;
			var dividerXml:XML = < pane type = { "divider" } direction = { divider.direction }/>
			if ( divider.numDividers )
			{
				if ( divider.direction == "horizontal" )
					dividerXml[ "@pos" ] = divider.getDividerAt(0).x;
				else
					dividerXml[ "@pos" ] = divider.getDividerAt(0).y;
			}
			parentXml.appendChild( dividerXml );
			SaveLayoutForChildren(dividerXml, divider);
			return dividerXml;
		}
		
		private static function SaveLayoutForDock( parentXml:XML, dock:DockablePage ):XML
		{
			if ( !dock )
				return null;
			var dockXml:XML = < pane type = { "dock" } allowCenter = { dock.AllowCenterDock } canDrag = { !dock.DragBarHidden }/>;
			parentXml.appendChild( dockXml );
			var child:Container = dock.GetContents() as Container;
			if ( child )
			{
				SaveLayoutForContainer( dockXml, child );
			}
			return dockXml;
		}
		
		private static function SaveLayoutForTabs( parentXml:XML, tabnav:DockableTabNav ):XML
		{
			if ( !tabnav )
				return null;
			var tabsXml:XML = < pane type = { "tabs" } />
			parentXml.appendChild( tabsXml );
			SaveLayoutForChildren(tabsXml, tabnav);
			return tabsXml;
		}
		
		private static function SaveLayoutForContainer( parentXml:XML, container:Container):XML
		{
			if ( !container )
				return null;
				
			var xml:XML = SaveLayoutForDock( parentXml, container as DockablePage );
			if ( xml )
				return xml;
			xml = SaveLayoutForDivider( parentXml, container as ExtendedDividedBox );
			if ( xml )
				return xml;
			xml = SaveLayoutForTabs( parentXml, container as DockableTabNav );
			if ( xml )
				return xml;
				
			if ( container == App.getApp().tilePalette )
			{
				xml = < pane id = { "Tiles" } zoom = { App.getApp().myTileList.getZoomPercentString() } />
				parentXml.appendChild( xml );
				return xml;
			}
			/*if ( container == App.getApp().spriteTrailWindow )
			{
				xml = < pane id = { "Sprite Trails" } />
				parentXml.appendChild( xml );
				return xml;
			}*/
			else if ( container == Global.windowedApp.PropsBox ||
				container == Global.windowedApp.SpritesTab ||
				container == Global.windowedApp.LayersTab ||
				container == Global.windowedApp.MainCanvas )
			{
				xml = < pane id = { container.id } />
				parentXml.appendChild( xml );
				return xml;
			}
			return null;
		}
		
		private static function SaveLayoutForChildren(xml:XML, container:Container):void
		{
			if ( !container )
				return;
			
			for ( var i:int = 0; i < container.numChildren; i++ )
			{
				var child:Container = container.getChildAt(i) as Container;
				if( child )
				{
					SaveLayoutForContainer( xml, child);
				}
			}
		}
		
		static public function SaveOptions(xml:XML):void
		{
			var optionsXml:XML = < options />;
			optionsXml.appendChild(<AllowEditingTemplateLayerList> { AllowEditingTemplateLayerList } </AllowEditingTemplateLayerList> );
			optionsXml.appendChild( < ForceAddingTemplatedMapsOnly > { ForceAddingTemplatedMapsOnly } </ForceAddingTemplatedMapsOnly> );
			optionsXml.appendChild( < ForceAddingTemplatedLayersOnly > { ForceAddingTemplatedLayersOnly } </ForceAddingTemplatedLayersOnly> );
			optionsXml.appendChild(<PreventEditingMapTileset> { PreventEditingMapTileset } </PreventEditingMapTileset> );
			optionsXml.appendChild( < PreventEditingSprites > { PreventEditingSprites } </PreventEditingSprites> );
			optionsXml.appendChild( < SaveSpritesSeparately > { SaveSpritesSeparately } </SaveSpritesSeparately> );
			optionsXml.appendChild( < SavePropertyTypesSeparately > { SavePropertyTypesSeparately } </SavePropertyTypesSeparately> );
			optionsXml.appendChild( < SaveLayerTemplatesSeparately > { SaveLayerTemplatesSeparately } </SaveLayerTemplatesSeparately> );
			optionsXml.appendChild( < SaveTileMatrixSeparately > { SaveTileMatrixSeparately } </SaveTileMatrixSeparately> );
			optionsXml.appendChild( < SaveTileBrushesSeparately > { SaveTileBrushesSeparately } </SaveTileBrushesSeparately> );
			optionsXml.appendChild( < SaveGuidesSeparately > { SaveGuidesSeparately } </SaveGuidesSeparately> );
			
			xml.appendChild(optionsXml);
		}
		
		static public function SaveColorGrid(xml:XML):void
		{
			var colorGridXml:XML = < colourGrid />;
			for (var i:int = 0; i < colorGrid.length; i++ )
			{
				colorGridXml.appendChild( < colour > { Misc.uintToHexStr6Digits(colorGrid[i]) } </colour> );
			}
			xml.appendChild( colorGridXml );
		}
		
		static public function SaveGridSettings(xml:XML):void
		{
			var guidesXml:XML = < guides />;
			guidesXml.appendChild( < snap > { GuideLayer.SnappingEnabled } </snap> );
			guidesXml.appendChild( < visible > { GuideLayer.Visible } </visible> );
			guidesXml.appendChild( < x > { GuideLayer.XStart } </x> );
			guidesXml.appendChild( < y > { GuideLayer.YStart } </y> );
			guidesXml.appendChild( < xspace > { GuideLayer.XSpacing } </xspace> );
			guidesXml.appendChild( < yspace > { GuideLayer.YSpacing } </yspace> );
			guidesXml.appendChild( < gridcolour > { Misc.uintToHexStr8Digits(GridLineColour) } </gridcolour> );
			var snapType:String = "Anchor";
			switch( GuideLayer.SnapPosType )
			{
				case GuideLayer.SnapPosType_Anchor:
					snapType = "Anchor";
					break;
				case GuideLayer.SnapPosType_TopLeft:
					snapType = "TopLeft";
					break;
				case GuideLayer.SnapPosType_Center:
					snapType = "Center";
					break;
				case GuideLayer.SnapPosType_BoundsTopLeft:
					snapType = "BoundsTopLeft";
					break;
			}
			guidesXml.appendChild( < snaptype > { snapType } </snaptype> );
			guidesXml.appendChild( < paintcontinuous > { GuideLayer.PaintContinuouslyWhenSnapped } </paintcontinuous> );
			guidesXml.appendChild( < showgameregion > { GuideLayer.ShowGameRegion } </showgameregion> );
			guidesXml.appendChild( < gameregionwidth > { GuideLayer.RegionWidth } </gameregionwidth> );
			guidesXml.appendChild( < gameregionheight > { GuideLayer.RegionHeight } </gameregionheight> );
			guidesXml.appendChild( < gameregionopacity > { GuideLayer.RegionOpacity } </gameregionopacity> );
			guidesXml.appendChild( < gameregioncentered > { GuideLayer.RegionCentered } </gameregioncentered> );
			guidesXml.appendChild( < minGridSpace > { GuideLayer.MinGridSpace } </minGridSpace> );
			guidesXml.appendChild( < showregiongrid > { GuideLayer.ShowRegionGrid } </showregiongrid> );
			guidesXml.appendChild( < regiongridx > { GuideLayer.RegionGridXStart } </regiongridx> );
			guidesXml.appendChild( < regiongridy > { GuideLayer.RegionGridYStart } </regiongridy> );
			guidesXml.appendChild( < regiongridcolour > { Misc.uintToHexStr8Digits(RegionGridLineColour) } </regiongridcolour> );
			xml.appendChild(guidesXml);
		}
		
		static private function writeIOErrorHandler(event:IOErrorEvent):void
		{
			AlertBox.Show("Failed to save settings: " + event.type, "Error");
		}
		
		static public function LoadSettings( window:NativeWindow ):void
		{
			//LogWindow.LogWriteLine("Load settings");
			FlxState.bgColor = 0xff777777;
			//LogWindow.LogWriteLine( File.applicationStorageDirectory.nativePath + "/settings.xml");
			var file:File = File.applicationStorageDirectory.resolvePath("settings.xml");
			//LogWindow.LogWriteLine( file.url );
			var urlRequest:URLRequest = new URLRequest( file.url );// Misc.FixMacFilePaths(file.nativePath));
			var urlLoader:URLLoader = new URLLoader();
			var header:URLRequestHeader = new URLRequestHeader("pragma", "no-cache");
			urlRequest.requestHeaders.push(header);
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT; // default
			urlLoader.addEventListener(Event.COMPLETE, xmlLoaded, false, 0, true);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlLoadFailedIO,false,0,true);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, xmlLoadFailedSecurity, false, 0, true);
			var intervalId:uint = setInterval(continueLoading, 200);
			urlLoader.load(urlRequest);
			
			TileConnectionList.AddDefaults();
			
			
			//trace("try load settings: " + file.nativePath);
			
			
			// Hack to prevent the loader doing nothing occasionally. Having the interval seems to fix it.
			function continueLoading( ):void
			{
				//trace(urlLoader.bytesLoaded);
			}
			
			function xmlLoaded(event:Event ):void
			{
				clearInterval(intervalId);
				//trace("xml loaded");
				try
				{
					// convert the loaded text into XML
					var xml:XML = XML(urlLoader.data);
					
					var doMaximize:Boolean = false;
					
					//LogWindow.LogWriteLine("Settings loaded.");
					
					var xmlList:XMLList = xml.window;
					if ( xmlList )
					{
						var winxml:XML = xmlList[0];
						if ( winxml )
						{
							if ( winxml.@maximized == "true" )
							{
								// We'll maximize later...
								doMaximize = true;
								window.x = winxml.@x;
								window.y = winxml.@y;
								window.width = winxml.@width;
								window.height = winxml.@height;
							}
							else
							{
								window.x = winxml.@x;
								window.y = winxml.@y;
								window.width = winxml.@width;
								window.height = winxml.@height;
							}
							
						}
					}
					
					xmlList = xml.recentFiles.file;
					for each (var fileXml:XML in xmlList)
					{
						//LogWindow.LogWriteLine("Add recent file:" + fileXml );
						RecentFiles.push( fileXml );
					}
					
					var app:App = App.getApp();
							
					app.RefreshRecentFiles();
					
					StatusBarVisible = xml.statusBar == true;
					app.statusBarMenuItem.checked = StatusBarVisible;
					
					if ( xml.hasOwnProperty("marqueesVisible") )
					{
						app.marqueesMenuItem.checked = MarqueesVisible = xml.marqueesVisible == true;
					}
					
					app.DisableAutoUpdates.checked = DisableAutoUpdates = xml.disableUpdates == true;
					
					if ( ExporterSettings.Load( xml.exporter ) )
					{
						if ( xml.exporter.hasOwnProperty("@saveWithProject") )
						{
							SaveExporterWithProject = xml.exporter.@saveWithProject == true;
						}
						try
						{
							CustomExporterPath = new File( xml.exporter.@customExporterPath );
						}
						catch ( error:Error)
						{
							CustomExporterPath = null;
						}
					}
					
					CurrentProjectFile = new File( xml.projectPath );
					CurrentMapDataFile = new File( xml.mapDataPath );
					CurrentImageFile = new File( xml.imagePath );
					
					app.SelectFromCurrentLayerMenuItem.checked = SelectFromCurrentLayerOnly = xml.selectFromCurrentLayerOnly == true;
					
					LoadGridSettings(xml.guides);
					
					FlxState.bgColor = xml.bgColour;
					var blue:uint = FlxState.bgColor & 0xff;
					MapBoundsColour = ( blue > 0xaa ) ? 0xff000000 : 0xffffffff;
					
					PathColour = xml.pathColour;
					PathColourInstanced = xml.pathColourInstanced;
					ShapeColour = xml.shapeColour;
					ShapeAlpha = xml.shapeAlpha;
					CalculateShapeOutlineColour();
					
					app.onionSkinMenuItem.checked = OnionSkinEnabled = (xml.onionSkin == true);
					OnionSkinAlpha = xml.onionSkinAlpha;
					if ( xml.hasOwnProperty("sameGroupOnionSkinAlpha") )
					{
						SameGroupOnionSkinAlpha = xml.sameGroupOnionSkinAlpha;
					}
					else
					{
						SameGroupOnionSkinAlpha = OnionSkinAlpha;
					}
					
					app.firstLayersTopMenuItem.checked = DisplayLayersFirstOnTop = (xml.firstLayersTop == true);
					if ( xml.hasOwnProperty("allowZoomOut") )
					{
						app.allowZoomOutMenuItem.checked = AllowZoomOut = (xml.allowZoomOut == true );
					}
					if ( xml.hasOwnProperty("drawTilesWithoutHeight") )
					{
						app.drawTilesWithoutHeightMenuItem.checked = DrawTilesWithoutHeight = (xml.drawTilesWithoutHeight == true );
					}
					if ( xml.hasOwnProperty("checkeredTilePalette") )
					{
						UseCheckeredTilePalette = (xml.checkeredTilePalette == true);
					}
					if ( xml.hasOwnProperty("tilePaletteBackgroundColour") )
					{
						TilePaletteBackgroundColour = (uint)(xml.tilePaletteBackgroundColour);
					}
					if ( xml.hasOwnProperty("drawCurrentTileAbove") )
					{
						app.drawCurrentTileAboveMenuItem.checked = DrawCurrentTileAbove = (xml.drawCurrentTileAbove == true );
					}
					if ( xml.hasOwnProperty("playAnims") )
					{
						app.playAnimsMenuItem.checked = PlayAnims = (xml.playAnims == true );
					}
					EditorTypeTiles.SelectHiddenTiles = xml.selectHiddenTiles == true;
					if ( xml.hasOwnProperty("infiniteStacking") )
					{
						EditorTypeTiles.InfiniteStacking = xml.infiniteStacking == true;
						app.InfiniteStackingMenuItem.checked = EditorTypeTiles.InfiniteStacking;
					}
					
					if ( xml.hasOwnProperty("showOverwritingImageAlert" ) )
					{
						ShowOverwritingImageAlert = ( xml.showOverwritingImageAlert == true );
					}
					if ( xml.hasOwnProperty("keepTileMatrixOnExit" ) )
					{
						KeepTileMatrixOnExitAnswer = xml.keepTileMatrixOnExit;
					}
					
					if( xml.drawing.hasOwnProperty("fillTolerance") )
					{
						EditorTypeDraw.FloodFillTolerance = Global.windowedApp.FillTolerance.value = xml.drawing.fillTolerance;
					}
			
					EditorTypeDraw.DrawColor = xml.drawing.colour;
					Global.windowedApp.colorPick.setStyle("backgroundColor", EditorTypeDraw.DrawColor);
					EditorTypeDraw.DrawAlpha = xml.drawing.alpha;
					EditorTypeDraw.DrawNoise = xml.drawing.noise == true;
					EditorTypeDraw.DrawPerlin = xml.drawing.perlin == true;
					EditorTypeDraw.LineThickness = xml.drawing.thickness;
					EditorTypeDraw.LockedTileMode = xml.drawing.locked == true;
					EditorTypeDraw.DrawOnBaseOnly = xml.drawing.drawOnBase == true;
					EditorTypeDraw.PerlinScale = xml.drawing.perlinscale;
					if ( xml.drawing.order == "BEHIND" )
					{
						EditorTypeDraw.drawOrderMode = EditorTypeDraw.DRAW_BEHIND;
					}
					else if ( xml.drawing.order == "ABOVE" )
					{
						EditorTypeDraw.drawOrderMode = EditorTypeDraw.DRAW_ABOVE;
					}
					else
					{
						EditorTypeDraw.drawOrderMode = EditorTypeDraw.DRAW_ALWAYS;
					}
					var popup:PopUpMenuButton = Global.windowedApp.DrawOrderMode;
					Menu(popup.popUp).selectedIndex = EditorTypeDraw.drawOrderMode;
					popup.label = popup.dataProvider[EditorTypeDraw.drawOrderMode].label;
					popup.setStyle("icon", popup.dataProvider[EditorTypeDraw.drawOrderMode].icon);
					popup.toolTip = popup.dataProvider[EditorTypeDraw.drawOrderMode].toolTip;
					
					
					
					if ( xml.drawing.hasOwnProperty("drawStyle") )
					{
						var drawStyle:String = xml.drawing.drawStyle;
						if ( drawStyle == "lines" )
						{
							EditorTypeDraw.DrawLines = true;
						}
						else if ( drawStyle == "circles" )
						{
							EditorTypeDraw.DrawCircles = true;
						}
						else if ( drawStyle == "ellipses" )
						{
							EditorTypeDraw.DrawEllipses = true;
						}
						else if ( drawStyle == "boxes" )
						{
							EditorTypeDraw.DrawBoxes = true;
						}
						else if ( drawStyle == "polygons" )
						{
							EditorTypeDraw.DrawBoxes = true;
						}
						popup = Global.windowedApp.DrawStyle;
						var drawStyleIndex:int = -1;
						for ( var i:uint = 0; i < popup.dataProvider.length; i++ )
						{
							if ( popup.dataProvider[i].data == drawStyle )
							{
								Menu(popup.popUp).selectedIndex = i;
								popup.label = popup.dataProvider[i].label;
								popup.setStyle("icon", popup.dataProvider[i].icon);
								popup.toolTip = popup.dataProvider[i].toolTip;
								break;
							}
						}
						
					}
					if ( xml.drawing.hasOwnProperty("drawNewTiles") )
						EditorTypeDraw.DrawNewTiles = xml.drawing.drawNewTiles == true;
					if ( xml.drawing.hasOwnProperty("fillColour") )
						EditorTypeDraw.ShapeFillColor = (uint)(xml.drawing.fillColour);
					if ( xml.drawing.hasOwnProperty("fillAlpha") )
						EditorTypeDraw.ShapeFillAlpha = xml.drawing.fillAlpha;
					
					
					LoadLayout( xml );
					
					LoadColorGrid( xml );
					
					LoadOptions(xml.options);
					
					if ( doMaximize )
					{
						// Must be done after the layout has been loaded so the divider proportions scale correctly.
						window.maximize();
					}
					
					if ( xml.hasOwnProperty("theme" ) )
					{
						App.getApp().selectTheme(String(xml.theme));
					}
				
					urlLoader.close();
					
				}
				catch (error:Error)
				{
					//AlertBox.Show("Failed to parse settings XML: " + error, "Error");
					urlLoader.close();
					windowedApp.SettingsLoaded();
				}
				
				windowedApp.SettingsLoaded();

			}
			
			function xmlLoadFailedIO(event:IOErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load IO error " + event.text);
				//AlertBox.Show("Failed to load file", "Error");
				windowedApp.SettingsLoaded();
			}
			
			function xmlLoadFailedSecurity(event:SecurityErrorEvent ):void
			{
				//LogWindow.LogWriteLine("Load Security error " + event.text);
				//AlertBox.Show("Failed to load file", "Error");
				windowedApp.SettingsLoaded();
			}
		}
		
		public static function LoadLayout(xml:XML):void
		{
			var mainDivider:ExtendedDividedBox = Global.windowedApp.MainArea;
			var layoutXml:XMLList = xml.layout;
			if ( layoutXml )
			{
				// Store backups so we can restore them later into their new containers.
				var props:Container = Global.windowedApp.PropsBox;
				var sprites:Container = Global.windowedApp.SpritesTab;
				var layers:Container = Global.windowedApp.LayersTab;
				var canvas:Container = Global.windowedApp.MainCanvas;
				var tiles:TilePalette = App.getApp().tilePalette;
				//var spriteTrails:Container = App.getApp().spriteTrailWindow;
				
				var mainXml:XML = layoutXml.pane.(@id == mainDivider.id)[0];
				if ( mainXml )
				{
					mainDivider.PreDelete();
					mainDivider.removeAllChildren();
					var dividerData:DividerInfo = LoadDivider( mainXml, mainDivider );
					mainDivider.validateNow();
					resizeDividerChildren(dividerData);
				}
				
				var windows:XMLList = layoutXml.window;
				for each( var windowXml:XML in windows )
				{
					var window:DockableWindow = App.CreatePopupWindow(DockableWindow, false) as DockableWindow;
					window.Resize();
					window.nativeWindow.x = windowXml.@x;
					window.nativeWindow.y = windowXml.@y;
					window.width = windowXml.@width;
					window.height = windowXml.@height;
					window.title = windowXml.@title;
					
					dividerData = new DividerInfo( null );
					LoadChildren( windowXml, window.container, dividerData );
					resizeDividerChildren(dividerData);
					if ( windowXml.@minimized == true )
					{
						window.MakeMinimized();
					}
				}
			}
			
			function resizeDividerChildren(dividerData:DividerInfo):void
			{
				if ( dividerData.m_divider )
				{
					if ( dividerData.m_divider.numDividers )
					{
						var box:BoxDivider = dividerData.m_divider.getDividerAt(0);
						if ( box )
						{
							if ( dividerData.m_divider.direction == "horizontal" )
								box.x = dividerData.m_pos;
							else
								box.y = dividerData.m_pos;
						}
					}
					dividerData.m_divider.validateNow();
				}
				for each( var child:DividerInfo in dividerData.m_children )
				{
					resizeDividerChildren( child );
				}
			}
			
			function LoadPane(xml:XML, parent:Container, dividerData:DividerInfo ):void
			{
				if ( xml.@type == "dock" )
				{
					var dock:DockablePage = new DockablePage;
					dock.AllowCenterDock = xml.@allowCenter == true;
					dock.DragBarHidden = xml.@canDrag == false;
					LoadChildren( xml, dock, dividerData );
					parent.addChild( dock );
					dock.percentHeight = 100;
					dock.percentWidth = 100;
				}
				else if ( xml.@type == "divider" )
				{
					var divider:ExtendedDividedBox = new ExtendedDividedBox;
					parent.addChild( divider );
					if ( dividerData )
					{
						var childDividerData:DividerInfo = LoadDivider( xml, divider );
						dividerData.m_children.push( childDividerData );
					}
				}
				else if ( xml.@type == "tabs" )
				{
					var tabs:DockableTabNav = new DockableTabNav;
					parent.addChild( tabs );
					LoadTabs( xml, tabs );
				}
				else if ( xml.hasOwnProperty("@id") )
				{
					var child:Container = null;
					if ( xml.@id == props.id )
						child = props;
					else if ( xml.@id == sprites.id )
						child = sprites;
					else if ( xml.@id == layers.id )
						child = layers;
					else if ( xml.@id == canvas.id )
						child = canvas;
					else if ( xml.@id == "Tiles" || xml.@id == "Sprite Trails")
					{
						if ( xml.@id == "Tiles" )
						{
							child = tiles;
							tiles.SetZoom( xml.@zoom );
						}
						/*else if ( xml.@id == "Sprite Trails" )
						{
							spriteTrails = App.getApp().CreateSpriteTrailWindow();
							//App.getApp().showSpriteTrailSettingsMenuItem.checked = true;
							child = spriteTrails;
						}*/
						// Tile Palette is created initially in a window so need to close that first.
						var obj:DisplayObjectContainer = child.parent;
						while ( obj && !(obj is DockableWindow ) )
						{
							obj = obj.parent;
						}
						if ( obj )
						{
							(obj as DockableWindow).CloseWindow();
						}
					}
					if ( child )
					{
						parent.addChild( child );
						if ( !(parent is DockableTabNav) && ( !parent.parent || !(parent.parent is DockableTabNav) ) )
						{
							child.visible = true;
						}
					}
				}
			}
			
			function LoadDivider(xml:XML, divider:ExtendedDividedBox ):DividerInfo
			{
				divider.percentWidth = 100;
				divider.percentHeight = 100;
				divider.liveDragging = true;
				if ( xml.hasOwnProperty("@direction") )
				{
					divider.direction = xml.@direction;
				}
				var dividerData:DividerInfo = new DividerInfo( divider );
				LoadChildren( xml, divider, dividerData );
				divider.validateNow();	// Ensure that setting the position of the divider bar works.
				
				if ( xml.hasOwnProperty("@pos") && divider.numDividers )
				{
					dividerData.m_pos = xml.@pos;
				}
				return dividerData;
			}
			
			function LoadTabs(xml:XML, tabs:DockableTabNav):void
			{
				tabs.percentWidth = 100;
				tabs.percentHeight = 100;
				LoadChildren( xml, tabs, null );
			}
			
			function LoadChildren(xml:XML, container:Container, dividerData:DividerInfo ):void
			{
				for each( var child:XML in xml.pane )
				{
					LoadPane( child, container, dividerData );
				}
			}
		}
		
		static public function ResetOptions():void
		{
			AllowEditingTemplateLayerList = true;
			ForceAddingTemplatedMapsOnly = false;
			ForceAddingTemplatedLayersOnly = false;
			PreventEditingMapTileset = false;
			PreventEditingSprites = false;
			SaveSpritesSeparately = false;
			SavePropertyTypesSeparately = false;
			SaveLayerTemplatesSeparately = false;
			SaveTileMatrixSeparately = false;
			SaveTileBrushesSeparately = false;
			SaveGuidesSeparately = false;
		}
		
		static public function LoadOptions(options:XMLList, resetIfNotExist:Boolean = false):void
		{
			if ( options.hasOwnProperty("AllowEditingTemplateLayerList") )
			{
				AllowEditingTemplateLayerList = options.AllowEditingTemplateLayerList == true;
			}
			else if( resetIfNotExist )
				AllowEditingTemplateLayerList = true;
				
			if ( options.hasOwnProperty("ForceAddingTemplatedMapsOnly") )
			{
				ForceAddingTemplatedMapsOnly = options.ForceAddingTemplatedMapsOnly == true;
			}
			else if( resetIfNotExist )
				ForceAddingTemplatedMapsOnly = false;
				
			if ( options.hasOwnProperty("ForceAddingTemplatedLayersOnly") )
			{
				ForceAddingTemplatedLayersOnly = options.ForceAddingTemplatedLayersOnly == true;
			}
			else if( resetIfNotExist )
				ForceAddingTemplatedLayersOnly = false;
				
			if ( options.hasOwnProperty("PreventEditingMapTileset") )
			{
				PreventEditingMapTileset = options.PreventEditingMapTileset == true;
			}
			else if( resetIfNotExist )
				PreventEditingMapTileset = false;
				
			if ( options.hasOwnProperty("PreventEditingSprites") )
			{
				PreventEditingSprites = options.PreventEditingSprites == true;
			}
			else if( resetIfNotExist )
				PreventEditingSprites = false;
				
			if ( options.hasOwnProperty("SaveSpritesSeparately") )
			{
				SaveSpritesSeparately = options.SaveSpritesSeparately == true;
			}
			else if( resetIfNotExist )
				SaveSpritesSeparately = false;
				
			if ( options.hasOwnProperty("SavePropertyTypesSeparately") )
			{
				SavePropertyTypesSeparately = options.SavePropertyTypesSeparately == true;
			}
			else if( resetIfNotExist )
				SavePropertyTypesSeparately = false;
				
			if ( options.hasOwnProperty("SaveLayerTemplatesSeparately") )
			{
				SaveLayerTemplatesSeparately = options.SaveLayerTemplatesSeparately == true;
			}
			else if( resetIfNotExist )
				SaveLayerTemplatesSeparately = false;
				
			if ( options.hasOwnProperty("SaveTileMatrixSeparately") )
			{
				SaveTileMatrixSeparately = options.SaveTileMatrixSeparately == true;
			}
			else if( resetIfNotExist )
				SaveTileMatrixSeparately = false;
				
			if ( options.hasOwnProperty("SaveTileBrushesSeparately") )
			{
				SaveTileBrushesSeparately = options.SaveTileBrushesSeparately == true;
			}
			else if( resetIfNotExist )
				SaveTileBrushesSeparately = false;
				
			if ( options.hasOwnProperty("SaveGuidesSeparately") )
			{
				SaveGuidesSeparately = options.SaveGuidesSeparately == true;
			}
			else
				SaveGuidesSeparately = false;
		}
		
		static public function LoadColorGrid(xml:XML):void
		{
			if ( xml.hasOwnProperty("colourGrid") )
			{
				var i:int = 0;
				for each (var item:XML in xml.colourGrid.colour )
				{
					if ( i < colorGrid.length )
					{
						colorGrid[i] = (uint)(item);
						i++;
					}
				}
				Global.windowedApp.colorGrid.ResetColors();
			}
		}
		
		public static function LoadGridSettings(guides:XMLList):void
		{
			var app:App = App.getApp();
			
			GuideLayer.SnappingEnabled = app.snapToGridMenuItem.checked = ( guides.snap == true );
			app.guidesViewMenuItem.checked = GuideLayer.Visible = ( guides.visible == true );
			GuideLayer.XStart = guides.x;
			GuideLayer.YStart = guides.y;
			GuideLayer.XSpacing = guides.xspace;
			GuideLayer.YSpacing = guides.yspace;
			if ( guides.hasOwnProperty("minGridSpace") )
			{
				GuideLayer.MinGridSpace = guides.minGridSpace;
			}
			if ( guides.hasOwnProperty("showgameregion") )
			{
				GuideLayer.ShowGameRegion = guides.showgameregion == true;
				app.regionOverlayMenuItem.checked = GuideLayer.ShowGameRegion;
			}
			if ( guides.hasOwnProperty("gameregionwidth") )
			{
				GuideLayer.RegionWidth = guides.gameregionwidth;
			}
			if ( guides.hasOwnProperty("gameregionheight") )
			{
				GuideLayer.RegionHeight = guides.gameregionheight;
			}
			if ( guides.hasOwnProperty("gameregionopacity") )
			{
				GuideLayer.RegionOpacity = guides.gameregionopacity;
			}
			if ( guides.hasOwnProperty("gameregioncentered") )
			{
				GuideLayer.RegionCentered = guides.gameregioncentered == true;
			}
			if ( guides.hasOwnProperty("paintcontinuous") )
			{
				GuideLayer.PaintContinuouslyWhenSnapped = guides.paintcontinuous == true;
			}
			if ( guides.hasOwnProperty("showregiongrid") )
			{
				GuideLayer.ShowRegionGrid = guides.showregiongrid == true;
			}
			if ( guides.hasOwnProperty("regiongridx") )
			{
				GuideLayer.RegionGridXStart = guides.regiongridx;
			}
			if ( guides.hasOwnProperty("regiongridy") )
			{
				GuideLayer.RegionGridYStart = guides.regiongridy;
			}
			if ( guides.hasOwnProperty("regiongridcolour") )
			{
				RegionGridLineColour = (uint)(guides.regiongridcolour);
			}
			if ( guides.hasOwnProperty("gridcolour") )
			{
				GridLineColour = (uint)(guides.gridcolour);
			}
			else
			{
				GridLineColour = guides.colour;	// backwards compatibility.
			}
			var snapType:String = guides.snaptype;
			if( snapType == "TopLeft" )
			{
				GuideLayer.SnapPosType = GuideLayer.SnapPosType_TopLeft;
			}
			else if( snapType == "Center" )
			{
				GuideLayer.SnapPosType = GuideLayer.SnapPosType_Center;
			}
			else if( snapType == "BoundsTopLeft" )
			{
				GuideLayer.SnapPosType = GuideLayer.SnapPosType_BoundsTopLeft;
			}
			else
			{
				GuideLayer.SnapPosType = GuideLayer.SnapPosType_Anchor;
			}
		}
		
		
		
	}

}

import com.UI.ExtendedDividedBox;

internal class DividerInfo
{
	public var m_divider:ExtendedDividedBox;
	public var m_pos:int;
	public var m_children:Vector.<DividerInfo>;
	
	public function DividerInfo( divider:ExtendedDividedBox, pos:int = 0 )
	{
		m_divider = divider;
		m_pos = pos;
		m_children = new Vector.<DividerInfo>;
	}
}
