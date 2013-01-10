package
{
	
import com.Editor.Bookmark;
import com.Editor.EditorType;
import com.Editor.EditorTypeDraw;
import com.Editor.EditorTypeSprites;
import com.Editor.EditorTypeTiles;
import com.Editor.GuideLayer;
import com.EditorState;
import com.Game.AvatarLink;
import com.Layers.LayerSprites;
import com.Tiles.TileMatrixData;
import com.UI.Docking.DockManager;
import com.UI.Docking.DockableWindow;
import com.Utils.ExporterData;
import com.Utils.Global;
import com.Utils.LuaInterface;
import com.FileHandling.Serialize;
import com.Layers.LayerGroup;
import com.Layers.LayerMap;
import com.Operations.HistoryStack;
import com.Tiles.FlxTilemapExt;
import com.Tiles.ImageBank;
import com.Tiles.SpriteEntry;
import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.NativeWindowInitOptions;
import flash.display.NativeWindowSystemChrome;
import flash.display.StageDisplayState;
import flash.display.StageScaleMode;
import flash.events.IEventDispatcher;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.net.FileFilter;
import flash.net.navigateToURL;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.system.Capabilities;
import flash.system.LoaderContext;
import flash.system.System;
import flash.ui.Keyboard;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.setInterval;
import flash.utils.setTimeout;
import minimalcomps.bit101.components.Style;
import mx.containers.Canvas;
import mx.controls.Alert;
import flash.display.Sprite;
import mx.controls.Tree;
import mx.collections.ArrayCollection;
import flash.events.Event;
import com.Layers.LayerEntry;
import com.MainGame;
import mx.containers.HDividedBox;
import mx.core.Container;
import mx.core.IFlexModuleFactory;
import mx.core.UIComponent;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.events.ModuleEvent;
import mx.events.SandboxMouseEvent;
import mx.events.StyleEvent;
import mx.styles.CSSStyleDeclaration;
import org.flixel.FlxG;
import mx.managers.PopUpManager;
import com.UI.*;
import com.UI.Tiles.TileList;
import flash.desktop.NativeApplication;
import flash.events.InvokeEvent;
import org.flixel.FlxPoint;

import cmodule.lua_wrapper.CLibInit;
import luaAlchemy.LuaAlchemy;

import flash.net.URLLoaderDataFormat;
import mx.controls.FlexNativeMenu;
import mx.containers.VBox;
import mx.styles.StyleManager;

public class App extends Canvas
{	
	public var layerTree:Tree;
	public var spriteList:Tree;
	public var layerTemplates:ArrayCollection;
	public var layerGroups:ArrayCollection;
	private var game:MainGame;
	private var divider:VBox;
	public var gamePanel:Canvas;
	public var myTileList:TileList = null;
	public var tileMatrix:TileMatrixGrid = null;
	public var tileMatrixWindow:TileMatrix = null;
	[Bindable]
	public var tileMatrices:ArrayCollection = new ArrayCollection;	// of TileMatrixData
	public var tilePalette:TilePalette = null;
	public var spriteTrailWindow:SpriteTrailWindow = null;
	
	public var brushesWindow:TileBrushesWindow = null;
	public var helpPopup:HelpWindow = null;
	public var animEditor:AnimEditor = null;
	
	[Bindable]
	public var spriteData:ArrayCollection;
	public var layerChangedCallback:Function;
	private var layerToSelect:LayerEntry = null;
	
	private static var theApp:App;
	public static function getApp():App { return theApp; } 
	
	public function get CurrentLayer():LayerEntry { return layerTree.selectedItem as LayerEntry; }
	public function get CurrentEditSprite():SpriteEntry { return spriteList.selectedItem as SpriteEntry; }

	public function get StageWidth():int { return gamePanel.width; }
	public function get StageHeight():int { return height; }	// For some reason gamePanel.height and stage.height are too small????
	
	public var StatusBarText:String = "";
	public static var currentDir:String;
	
	public var Created:Boolean = false;
	
	
	public var UndoMenuItem:NativeMenuItem = null;
	public var SaveMenuItem:NativeMenuItem = null;
	public var SaveAsMenuItem:NativeMenuItem = null;
	public var exportMenuItem:NativeMenuItem = null;
	public var projectExportMenuItem:NativeMenuItem = null;
	public var recentFilesMenu:NativeMenu = null;
	public var SelectFromCurrentLayerMenuItem:NativeMenuItem = null;
	public var guidesViewMenuItem:NativeMenuItem = null;
	public var statusBarMenuItem:NativeMenuItem;
	public var DisableAutoUpdates:NativeMenuItem;
	public var snapToGridMenuItem:NativeMenuItem;
	public var onionSkinMenuItem:NativeMenuItem;
	public var firstLayersTopMenuItem:NativeMenuItem;
	public var tileBrushesMenuItem:NativeMenuItem;
	public var marqueesMenuItem:NativeMenuItem;
	public var allowZoomOutMenuItem:NativeMenuItem = null;
	public var regionOverlayMenuItem:NativeMenuItem = null;
	public var drawTilesWithoutHeightMenuItem:NativeMenuItem = null;
	public var drawCurrentTileAboveMenuItem:NativeMenuItem = null;
	public var playAnimsMenuItem:NativeMenuItem = null;
	public var showSpriteTrailSettingsMenuItem:NativeMenuItem = null;
	public var InfiniteStackingMenuItem:NativeMenuItem = null;
	public var findNextMenuItem:NativeMenuItem = null;
	public var findPreviousMenuItem:NativeMenuItem = null;
	public var fullScreenMenuItem:NativeMenuItem = null;
	public var themesMenu:NativeMenu = null;
	public var zoomOutMenuItem:NativeMenuItem = null;
	public var zoomInMenuItem:NativeMenuItem = null;
	public var themeList:Dictionary = new Dictionary;
	
	private var currentFile:File = null;
	public function GetCurrentFile():File { return currentFile; }
	
	public static var VersionString:String;
	
	private var initFileToOpen:String = "";
	private var pauseMinimize:Boolean = false;
	
	public var bookmarks:Vector.<Bookmark> = new Vector.<Bookmark>(9);
	public static var CurrentTemplateLayer:LayerEntry = null;
	
	public function onInvokeEvent(invocation:InvokeEvent):void
	{
		if ( layerGroups )
		{
			// Clicked to open a file from desktop once DAME was already started.
			if (invocation.arguments.length)
			{
				if ( !HistoryStack.HasChangedSinceSave() )
				{
					OpenFromDesktop(null);
				}
				else
				{
					AlertBox.Show("You have unsaved changes. Do you wish to continue?", "Overwrite file?", AlertBox.YES | AlertBox.CANCEL, null, OpenFromDesktop, AlertBox.CANCEL);
				}
				
				function OpenFromDesktop(closeEvent:CloseEvent):void
				{
					if (!closeEvent || closeEvent.detail == AlertBox.YES)
					{
						currentFile = new File( invocation.arguments[0] as String );
						Serialize.OpenProject(currentFile, LoadComplete );
					}
				}
			}
			return;
		}
		//currentDir = invocation.currentDirectory.nativePath;
		currentDir = File.applicationDirectory.nativePath;
		// The dir uses \ but files won't load unless they use / so replace all instances of that.
		var pattern:RegExp = /\\/g;
		currentDir = currentDir.replace(pattern, "/" );
		// This is just for my debug version...
		currentDir = currentDir.replace("DAME/bin", "DAME");
		
		
		if (invocation.arguments.length)
		{
			initFileToOpen = invocation.arguments[0] as String;
		}
		

		layerGroups = new ArrayCollection();
		layerTemplates = new ArrayCollection();
	}
	
	public function App()
	{
		var appXML:XML = NativeApplication.nativeApplication.applicationDescriptor;
		// Define the Namespace (there is only one by default in the application descriptor file)
		var air:Namespace = appXML.namespaceDeclarations()[0];
		VersionString = appXML.air::version;
				
		NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);

		theApp = this;
		
		game = new MainGame( 150, 100);
		
		addEventListener(Event.ADDED_TO_STAGE, gotStage);
		addEventListener(Event.ENTER_FRAME, update);
	}
	
	public function update(event:Event):void
	{
		if ( stage && !stage.nativeWindow.closed)
		{
			if (stage.nativeWindow.displayState == "minimized" )
			{
				FlxG.pause = true;
				pauseMinimize = true;
			}
			else if ( pauseMinimize )
			{
				pauseMinimize = false;
				FlxG.pause = false;
			}
		}
	}
	
	public function assignLayerChangedCallback( cb:Function):void
	{
		layerChangedCallback = cb;
	}
	
	public function initUIComponents( _mainDiv:VBox, _layerTree:Tree, _gamePanel:Canvas, _spriteList:Tree):void
	{
		divider = _mainDiv;
		
		gamePanel = _gamePanel;
		var uiref:UIComponent = new UIComponent;
		gamePanel.addChild(uiref);
		uiref.addChild(game);
		
		layerTree = _layerTree;
		layerTree.dataProvider = layerGroups;
		
		spriteData = new ArrayCollection( );
		spriteData.addItem( new SpriteEntry( "Sprites", new ArrayCollection() ) );
		_spriteList.dataProvider = spriteData;
		
		spriteList = _spriteList;
	}
	
	public function gotStage(event:Event):void
	{
		//CreatePopupWindow(LogWindow, false);
		removeEventListener(Event.ADDED_TO_STAGE, gotStage);
		stage.addEventListener(Event.RESIZE, stageResizeHandler);
		
		divider.height = stage.stageHeight;
		divider.width = stage.stageWidth;	
		
		layerTree.validateNow();
		if ( layerGroups.length )
		{
			layerTree.expandChildrenOf( layerGroups[0], true );
			layerTree.selectedItem = layerGroups[0].children[0];
		}
		
		//tilePanel.y = stage.height / 2;
		
		layerChangedCallback();
		
		//if ( NativeWindow.supportsMenu )
		var menu:NativeMenu = new NativeMenu();
		// File Menu
		var fileMenu:NativeMenu = addSubMenu(menu, "File");
		fileMenu.addEventListener(Event.DISPLAYING, fileMenuActivated);
		addNewMenuItem(fileMenu, "New", 'n', menuFileItemSelected);
		addNewMenuItem(fileMenu, "Open...", 'o', menuFileItemSelected);
		recentFilesMenu = addSubMenu(fileMenu, "Recent Files");
		addSeparator(fileMenu);
		SaveMenuItem = addNewMenuItem(fileMenu, "Save", 's', menuFileItemSelected);
		SaveAsMenuItem = addNewMenuItem(fileMenu, "Save As...", 'S', menuFileItemSelected);
		addSeparator(fileMenu);
		addNewMenuItem(fileMenu, "Import...", '', menuFileItemSelected);
		exportMenuItem = addNewMenuItem(fileMenu, "Export...", 'e', menuFileItemSelected);
		projectExportMenuItem = addNewMenuItem(fileMenu, "Export Using Project Exporter...", 'E', menuFileItemSelected);
		addNewMenuItem(fileMenu, "Export to Image", '', menuFileItemSelected);
		addNewMenuItem(fileMenu, "Specify Custom Exporters Path...", '', menuFileItemSelected);
		addSeparator(fileMenu);
		addNewMenuItem(fileMenu, "Quit", 'q', menuFileItemSelected);
		// Edit Menu
		var editMenu:NativeMenu = addSubMenu(menu, "Edit");
		UndoMenuItem = addNewMenuItem(editMenu, "Undo", 'z', menuEditItemSelected);
		UndoMenuItem.enabled = false;
		addNewMenuItem(editMenu, "Cut", 'x', menuEditItemSelected);
		addNewMenuItem(editMenu, "Copy", 'c', menuEditItemSelected);
		addNewMenuItem(editMenu, "Paste", 'v', menuEditItemSelected);
		addNewMenuItem(editMenu, "Select All", "a", menuEditItemSelected);
		addNewMenuItem(editMenu, "Select None", 'd', menuEditItemSelected);
		InfiniteStackingMenuItem = addNewMenuItem(editMenu, "Allow Infinite Tile Stacking", '', menuEditItemSelected);
		SelectFromCurrentLayerMenuItem = addNewMenuItem( editMenu, "Select From Current Layer Only", '', menuEditItemSelected );
		SelectFromCurrentLayerMenuItem.checked = Global.SelectFromCurrentLayerOnly;
		
		// View Menu
		var viewMenu:NativeMenu = addSubMenu(menu, "View");
		guidesViewMenuItem = addNewMenuItem(viewMenu, "Grid", 'g', menuGuidesItemSelected);
		snapToGridMenuItem = addNewMenuItem(viewMenu, "Snap To Grid", 'G', menuGuidesItemSelected);
		addNewMenuItem(viewMenu, "Change Grid Settings...", '', menuGuidesItemSelected);
		addNewMenuItem(viewMenu, "Align Grids To Current Layer", '', menuGuidesItemSelected);
		addSeparator(viewMenu);
		addNewMenuItem(viewMenu, "Center layer", 'l', menuViewItemSelected);
		// There is an issue with having a menu shortcut with Function keys so place the shortcut in the label directly
		// and handle the keypress in EditorState instead.
		findNextMenuItem = addNewMenuItem(viewMenu, "Find Next\tF3", '', menuViewItemSelected);
		findPreviousMenuItem = addNewMenuItem(viewMenu, "Find Previous\tF2", '', menuViewItemSelected);
		var addBookmarksMenu:NativeMenu = addSubMenu(viewMenu, "Add Bookmark");
		var gotoBookmarksMenu:NativeMenu = addSubMenu(viewMenu, "Goto Bookmark");
		for ( var i:uint = 0; i < 9; i++ )
		{
			bookmarks[i] = new Bookmark();
			bookmarks[i].addMenu = addNewMenuItem(addBookmarksMenu, "Bookmark " + i + "\tCtrl+" + (i+1), '', bookmarks[i].addBookmarkSelected);
			bookmarks[i].gotoMenu = addNewMenuItem(gotoBookmarksMenu, "Bookmark " + i + "\tCtrl+Shift+" + (i+1), '',  bookmarks[i].gotoBookmarkSelected );
			bookmarks[i].gotoMenu.enabled = false;
		}
		addSeparator(viewMenu);
		playAnimsMenuItem = addNewMenuItem(viewMenu, "Play Anims", 'p', menuViewItemSelected );
		playAnimsMenuItem.checked = Global.PlayAnims;
		drawTilesWithoutHeightMenuItem = addNewMenuItem(viewMenu, "Draw Tiles Without Height", 'i', menuViewItemSelected );
		drawCurrentTileAboveMenuItem = addNewMenuItem(viewMenu, "Draw Highlighted Tile In Front", 'D', menuViewItemSelected );
		onionSkinMenuItem = addNewMenuItem(viewMenu, "Onion Skin", '', menuViewItemSelected );
		firstLayersTopMenuItem = addNewMenuItem(viewMenu, "Show Top Layers First", '', menuViewItemSelected );
		addNewMenuItem(viewMenu, "Show Layer Templates", '', menuViewItemSelected );
		firstLayersTopMenuItem.checked = Global.DisplayLayersFirstOnTop;
		marqueesMenuItem = addNewMenuItem(viewMenu, "Rotation/Scaling Marquees", 'm', menuViewItemSelected);
		marqueesMenuItem.checked = Global.MarqueesVisible;
		zoomInMenuItem = addNewMenuItem(viewMenu, "Zoom In", '+', menuViewItemSelected);
		zoomOutMenuItem = addNewMenuItem(viewMenu, "Zoom Out", '-', menuViewItemSelected);
		allowZoomOutMenuItem = addNewMenuItem(viewMenu, "Allow Zoom Out (use at risk!)", '', menuViewItemSelected);
		allowZoomOutMenuItem.checked = Global.AllowZoomOut;
		addSeparator(viewMenu);
		addNewMenuItem(viewMenu, "Restore Lost Tool Windows", '', menuViewItemSelected);
		statusBarMenuItem = addNewMenuItem(viewMenu, "Status Bar", '', menuViewItemSelected);
		fullScreenMenuItem = addNewMenuItem(viewMenu, "Full Screen\tF11", '', menuViewItemSelected);
		
		statusBarMenuItem.checked = true;
		if ( NativeWindow.supportsMenu )
		{
			stage.nativeWindow.menu = menu;
		}
		else if (NativeApplication.supportsMenu )
		{
			NativeApplication.nativeApplication.menu = menu;
		}
		
		// Modify menu
		var modifyMenu:NativeMenu = addSubMenu(menu, "Modify");
		addNewMenuItem(modifyMenu, "Remove Scaling and Rotation From Selected Objects", 'r', menuModifyItemSelected);
		addNewMenuItem(modifyMenu, "Set Sprite Coords And Orientation...", 't', menuModifyItemSelected);
		addNewMenuItem(modifyMenu, "Flip Sprites", 'f', menuModifyItemSelected);
		
		// Tools menu
		var toolsMenu:NativeMenu = addSubMenu(menu, "Tools");
		tileBrushesMenuItem = addNewMenuItem(toolsMenu, "Tile Brushes", "b", menuToolsItemSelected);
		regionOverlayMenuItem = addNewMenuItem(toolsMenu, "Show Game Region Overlay", "y", menuToolsItemSelected );
		addNewMenuItem(toolsMenu, "Color Settings...", '', menuToolsItemSelected);
		addNewMenuItem(toolsMenu, "Options", '', menuToolsItemSelected);
		addNewMenuItem(toolsMenu, "Highlight Collidable Tiles", 'h', menuToolsItemSelected);
		showSpriteTrailSettingsMenuItem = addNewMenuItem(toolsMenu, "Show Sprite Trail Settings", '', menuToolsItemSelected );
		addSeparator(toolsMenu);
		themesMenu = addSubMenu(toolsMenu, "Change Theme...");
		PopulateThemesMenu();
		
		// Help menu
		var helpMenu:NativeMenu = addSubMenu(menu, "Help");
		addNewMenuItem(helpMenu, "About", '', menuHelpItemSelected );
		addNewMenuItem(helpMenu, "Help Contents", '', menuHelpItemSelected );
		//addNewMenuItem(helpMenu, "Online Wiki", '', menuHelpItemSelected );
		addNewMenuItem(helpMenu, "Keyboard Shortcuts", '', menuHelpItemSelected );
		addNewMenuItem(helpMenu, "Check For Updates", '', menuHelpItemSelected );
		DisableAutoUpdates = addNewMenuItem(helpMenu, "Disable Auto Updates", '', menuHelpItemSelected );
		/*var samplesMenu:NativeMenu = addSubMenu(helpMenu, "Samples");
		addNewMenuItem(samplesMenu, "Load Sample 1 (Flixel simple)", '', menuHelpItemSelected );
		addNewMenuItem(samplesMenu, "Load Sample 2 (Flixel complex)", '', menuHelpItemSelected );
		addNewMenuItem(samplesMenu, "Load Sample 3 (FlashPunk)", '', menuHelpItemSelected );*/
		
		Global.LoadSettings( stage.nativeWindow );
		
		//AddWindowMouseCallbacks( popupModalPreventMouseHandler, true, 0, true );
		
		tilePalette = new TilePalette();
		DockManager.CreateWindow(tilePalette, "Tiles" );
		
		tileMatrixWindow = Global.windowedApp.tileMatrix = CreatePopupWindow(TileMatrix, false) as TileMatrix;
		tileMatrix = Global.windowedApp.tileMatrix.tiles;
		Global.windowedApp.showTileMatrix(false);

		if ( initFileToOpen.length )
		{
			setTimeout(loadInitFile, 1000);
		}

		Created = true;
	}
	
	public function ShowAnimEditor():void
	{
		if ( animEditor == null )
		{
			animEditor = CreatePopupWindow(AnimEditor, false) as AnimEditor;
		}
		else
		{
			animEditor.ChangeVisibility( true );
		}
	}
	
	public function HideAnimEditor():void
	{
		if ( animEditor )
		{
			animEditor.ChangeVisibility( false );
		}
	}
	
	public function CreateSpriteTrailWindow():void
	{
		if ( !spriteTrailWindow )
		{
			//spriteTrailWindow = new SpriteTrailWindow();
			spriteTrailWindow = CreatePopupWindow(SpriteTrailWindow, false) as SpriteTrailWindow;
			//var win:DockableWindow = DockManager.CreateWindow(spriteTrailWindow, "Sprite Trails");
			//win.ScaleWindowToFit();
			//return spriteTrailWindow;
		}
		else
		{
			spriteTrailWindow.ChangeVisibility( true );
		}
		//return null;
	}
	
	private function loadInitFile():void
	{
		currentFile = new File( initFileToOpen );
		Serialize.OpenProject(currentFile, LoadComplete );
	}
	
	public function RefreshRecentFiles():void
	{
		recentFilesMenu.removeAllItems();
		var i:uint = Global.RecentFiles.length;
		while( i-- )
		{
			if ( Global.RecentFiles.indexOf(Global.RecentFiles[i]) < i )
			{
				Global.RecentFiles.splice( i, 1);
			}
			else
			{
				addNewMenuItem(recentFilesMenu, Global.RecentFiles[i], '', menuRecentFilesItemSelected);
			}
		}
		
	}
	
	public function LayerTreeItemChanged( layer:LayerEntry ):void
	{
		/*if ( tilePalette != null )
		{
			if ( layer == null )
			{
				tilePalette.Active = false;
				return;
			}
			tilePalette.Active = ( layer is LayerMap );
		}*/
	}
	
	private function addSubMenu( menu:NativeMenu, text:String):NativeMenu
	{
		var subMenu:NativeMenu = new NativeMenu();
		menu.addSubmenu(subMenu, text );
		return subMenu;
	}
	
	private function addNewMenuItem( menu:NativeMenu, text:String, keyEquivalent:String, handler:Function ):NativeMenuItem
	{
		var item:NativeMenuItem = new NativeMenuItem(text);
		item.keyEquivalent = keyEquivalent;
		menu.addItem(item);
		item.addEventListener(Event.SELECT, handler,false,0,true);
		return item;
	}
	
	private function addSeparator( menu:NativeMenu ):void
	{
		menu.addItem( new NativeMenuItem("",true) );
	}
	
	private function PopulateThemesMenu():void
	{
		var defaultMenu:NativeMenuItem = addNewMenuItem(themesMenu, "Silver (default)", '', menuThemeSelected);
		themeList[ defaultMenu ] = "silverStyle.swf";
		defaultMenu.checked = true;
		defaultMenu.enabled = false;
		themeList[addNewMenuItem(themesMenu, "Black", '', menuThemeSelected)] = "blackStyle.swf";
		themeList[addNewMenuItem(themesMenu, "Orange", '', menuThemeSelected)] = "orangeStyle.swf";
		themeList[addNewMenuItem(themesMenu, "Blue", '', menuThemeSelected)] = "blueStyle.swf";
		themeList[addNewMenuItem(themesMenu, "Rainbow", '', menuThemeSelected)] = "rainbowStyle.swf";
	}
	
	public function selectTheme(themeName:String):void
	{
		if ( themeName != "" )
		{
			for (var key:Object in themeList)
			{
				var menuItem:NativeMenuItem = key as NativeMenuItem;
				if ( themeList[key] == themeName )
				{
					menuItem.checked = true;
					menuItem.enabled = false;
				}
				else
				{
					menuItem.checked = false;
					menuItem.enabled = true;
				}
			}
			if ( themeName != "Silver (default)" )
			{
				var myEvent:IEventDispatcher = StyleManager.loadStyleDeclarations(themeName);
				Global.currentTheme = themeName;
				myEvent.addEventListener(StyleEvent.COMPLETE, stylesLoaded);
			}
			else
			{
				StyleManager.unloadStyleDeclarations(themeName);
				Global.currentTheme = themeName;
			}
			
		}
		else
		{
			stylesLoaded(null);
		}
	}

	private function stylesLoaded(event:StyleEvent):void
	{
		var styleDec:CSSStyleDeclaration = StyleManager.getStyleDeclaration(".minComps");
		if ( styleDec )
		{
			var col:uint = styleDec.getStyle("buttonFace");
			if ( col )
			{
				Style.BUTTON_FACE = col;
			}
			col = styleDec.getStyle("buttonDown");
			if ( col )
			{
				Style.BUTTON_DOWN = col;
			}
		}
	}      
	
	private function menuThemeSelected(event:Event):void
	{
		selectTheme(themeList[event.target]);
	}
	
	private function fileMenuActivated(event:Event):void
	{
		projectExportMenuItem.enabled = ( App.getApp().GetCurrentFile() && App.getApp().GetCurrentFile().parent );
		if ( projectExportMenuItem.enabled && ExporterData.useProjectExporterOnly )
		{
			exportMenuItem.enabled = false;
		}
		else
		{
			exportMenuItem.enabled = true;
		}
	}
	
	private function menuFileItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		if ( event.target.label == "New" )
		{
			if ( !HistoryStack.HasChangedSinceSave() )
			{
				NewFile(null);
			}
			else
			{
				AlertBox.Show("You have unsaved changes. Do you wish to continue?", "Overwrite file?", AlertBox.YES | AlertBox.CANCEL, null, NewFile, AlertBox.CANCEL);
			}
			
			function NewFile(closeEvent:CloseEvent):void
			{
				if (!closeEvent || closeEvent.detail == AlertBox.YES)
				{
					currentFile = null;
					Global.windowedApp.title = "DAME - Untitled project";
					EditorState.recordSave();
					ImageBank.Clear();
					Global.ProjectExporterSettings.settings.length = 0;
					
					
					AvatarLink.ClearAllLinks();
					
					spriteData[0].children.removeAll();
					spriteData.itemUpdated( spriteData[0] );

					layerGroups.removeAll();
					layerGroups = new ArrayCollection();
					layerTemplates.removeAll();
					layerTemplates = new ArrayCollection();
					layerTree.dataProvider = layerGroups;
					layerGroups.itemUpdated( layerGroups );
					var currentState:EditorState = FlxG.state as EditorState;
					if ( currentState )
					{
						currentState.UpdateMapList();
						currentState.UpdateCurrentTileList( CurrentLayer );
						currentState.drawEditor.ClearSelectedSprites();
					}
					TileBrushesWindow.brushes.removeAll();
					if ( brushesWindow )
					{
						brushesWindow.ListBrushes.validateNow();
					}
					
					for each( var bookmark:Bookmark in bookmarks )
					{
						bookmark.gotoMenu.enabled = false;
						bookmark.location = null;
					}
					Global.CurrentSettingsFile = null;
					Global.SaveSpritesSeparately = false;
					FlxTilemapExt.ResetSharedData();
					HistoryStack.Clear();
					ExporterData.useProjectExporterOnly = false;
				}
			}
		}
		else if ( event.target.label == "Save" )
		{
			Save();
		}
		else if ( event.target.label == "Save As..." )
		{
			SaveAs();
		}
		else if ( event.target.label == "Open..." )
		{
			Open();
		}
		else if ( event.target.label == "Import..." )
		{
			CreatePopupWindow(ImportWindow, true);
		}
		else if (event.target == exportMenuItem )
		{
			Export(false);
		}
		else if ( event.target == projectExportMenuItem )
		{
			Export(true);
		}
		else if ( event.target.label == "Specify Custom Exporters Path..." )
		{
			BrowseForExporterPath();
		}
		else if ( event.target.label == "Quit" )
		{
			onClose(event);
		}
		else if ( event.target.label == "Export to Image" )
		{
			ExportToImage();
		}
	}	
	
	private function menuEditItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		var state:EditorState = FlxG.state as EditorState;
		var editor:EditorType = state.getCurrentEditor(this);
		
		if ( event.target.label == "Undo" )
		{
			HistoryStack.Undo();
		}
		else if ( event.target.label == "Copy" )
		{
			if ( editor )
			{
				editor.CopyData();
			}
		}
		else if ( event.target.label == "Paste" )
		{
			if ( editor )
			{
				editor.PasteData();
			}
		}
		else if ( event.target.label == "Cut" )
		{
			if ( editor )
			{
				editor.CutData();
			}
		}
		else if ( event.target.label == "Select All" )
		{
			if ( editor )
			{
				editor.SelectAll();
			}
		}
		else if ( event.target.label == "Select None" )
		{
			if ( editor )
			{
				state.tileEditor.SelectNone();
				state.pathEditor.SelectNone();
				state.shapeEditor.SelectNone();
				state.spriteEditor.SelectNone();
			}
		}
		else if ( event.target == InfiniteStackingMenuItem )
		{
			InfiniteStackingMenuItem.checked = !InfiniteStackingMenuItem.checked;
			EditorTypeTiles.InfiniteStacking = InfiniteStackingMenuItem.checked;
		}
		else if ( event.target == SelectFromCurrentLayerMenuItem )
		{
			SelectFromCurrentLayerMenuItem.checked = !SelectFromCurrentLayerMenuItem.checked;
			Global.SelectFromCurrentLayerOnly = SelectFromCurrentLayerMenuItem.checked;
		}
	}
	
	private function menuGuidesItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		if ( event.target.label == "Grid" )
		{
			event.target.checked = !event.target.checked;
			GuideLayer.Visible = event.target.checked;
		}
		else if ( event.target.label == "Align Grids To Current Layer" )
		{
			var mapLayer:LayerMap = layerTree.selectedItem as LayerMap;
			if ( mapLayer )
			{
				GuideLayer.XStart = mapLayer.map.x;
				GuideLayer.YStart = mapLayer.map.y;
				GuideLayer.XSpacing = mapLayer.map.tileSpacingX;
				GuideLayer.YSpacing = mapLayer.map.tileSpacingY;
				if ( mapLayer.tilemapType == LayerMap.TileTypeDiamond)
				{
					GuideLayer.YStart += ( mapLayer.map.tileHeight - ( mapLayer.map.tileSpacingY * 2 ) );
				}
				else
				{
					GuideLayer.YStart += ( mapLayer.map.tileHeight - mapLayer.map.tileSpacingY );
				}
			}
		}
		else if ( event.target.label == "Change Grid Settings..." )
		{
			CreatePopupWindow(GuidesPopup, true);
		}
		else if ( event.target.label == "Snap To Grid" )
		{
			event.target.checked = !event.target.checked;
			GuideLayer.SnappingEnabled = event.target.checked;
		}
		
	}
	
	private function menuModifyItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		var state:EditorState = FlxG.state as EditorState;
		var editor:EditorType = state.getCurrentEditor(this);
		if ( event.target.label == "Remove Scaling and Rotation From Selected Objects" )
		{
			var editorSprites:EditorTypeSprites = editor as EditorTypeSprites;
			if ( editorSprites )
			{
				editorSprites.RestoreSpritesToDefault();
			}
		}
		else if ( event.target.label == "Set Sprite Coords And Orientation...")
		{
			editorSprites = editor as EditorTypeSprites;
			if ( editorSprites && editorSprites.GetSelection().length>0 )
			{
				CreatePopupWindow( SetObjectCoordsPopup, true );
			}
		}
		else if ( event.target.label == "Flip Sprites" )
		{
			editorSprites = editor as EditorTypeSprites;
			if ( editorSprites )
			{
				editorSprites.FlipSprites();
			}
			else
			{
				var editorDraw:EditorTypeDraw = editor as EditorTypeDraw;
				if ( editorDraw )
				{
					editorDraw.FlipSelection();
				}
			}
		}
	}
	
	private function menuToolsItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		var state:EditorState = FlxG.state as EditorState;
		if ( event.target == tileBrushesMenuItem )
		{
			if ( brushesWindow == null )
			{
				brushesWindow = CreatePopupWindow( TileBrushesWindow, false ) as TileBrushesWindow;
				event.target.checked = true;
			}
			else
			{
				brushesWindow.ChangeVisibility( !brushesWindow.Active );
				event.target.checked = brushesWindow.Active;
			}
		}
		else if ( event.target == regionOverlayMenuItem )
		{
			GuideLayer.ShowGameRegion = !GuideLayer.ShowGameRegion;
			regionOverlayMenuItem.checked = GuideLayer.ShowGameRegion;
		}
		else if ( event.target.label == "Color Settings..." )
		{
			CreatePopupWindow( ColoursPopup, true );
		}
		else if ( event.target.label == "Highlight Collidable Tiles" )
		{
			event.target.checked = !FlxTilemapExt.highlightCollidableTiles;
			FlxTilemapExt.highlightCollidableTiles = event.target.checked;
		}
		else if ( event.target == showSpriteTrailSettingsMenuItem )
		{
			showSpriteTrailSettingsMenuItem.checked = !showSpriteTrailSettingsMenuItem.checked;
			if ( showSpriteTrailSettingsMenuItem.checked )
			{
				CreateSpriteTrailWindow();
			}
			else
			{
				spriteTrailWindow.ChangeVisibility( false );
			}
		}
		else if ( event.target.label == "Options" )
		{
			CreatePopupWindow( OptionsPopup, true );
		}

	}
	
	private function menuViewItemSelected(event:Event):void
	{
		game.restoreFocus();	// Just in case focus was lost.
		var state:EditorState = FlxG.state as EditorState;
		if ( event.target == marqueesMenuItem )
		{
			Global.MarqueesVisible = !Global.MarqueesVisible;
			event.target.checked = Global.MarqueesVisible;
		}
		else if ( event.target == drawTilesWithoutHeightMenuItem )
		{
			Global.DrawTilesWithoutHeight = !Global.DrawTilesWithoutHeight;
			drawTilesWithoutHeightMenuItem.checked = Global.DrawTilesWithoutHeight;
		}
		else if ( event.target == drawCurrentTileAboveMenuItem )
		{
			Global.DrawCurrentTileAbove = !Global.DrawCurrentTileAbove;
			drawCurrentTileAboveMenuItem.checked = Global.DrawCurrentTileAbove;
		}
		else if ( event.target == allowZoomOutMenuItem )
		{
			Global.AllowZoomOut = !Global.AllowZoomOut;
			event.target.checked = Global.AllowZoomOut;
		}
		else if ( event.target == playAnimsMenuItem )
		{
			Global.PlayAnims = !Global.PlayAnims;
			event.target.checked = Global.PlayAnims;
		}
		else if ( event.target == zoomOutMenuItem )
		{
			state.zoomView(false);
		}
		else if ( event.target == zoomInMenuItem )
		{
			state.zoomView(true);
		}
		else if ( event.target.label == "Status Bar" )
		{
			Global.StatusBarVisible = !Global.StatusBarVisible;
			event.target.checked = Global.StatusBarVisible;
		}
		else if ( event.target.label == "Center layer" )
		{
			if ( CurrentLayer )
			{
				var centre:FlxPoint = CurrentLayer.GetLayerCenter();
				if ( centre )
				{
					state.MoveCameraToLocation( centre, CurrentLayer.xScroll, CurrentLayer.yScroll );
				}
			}
		}
		else if ( event.target == findNextMenuItem )
		{
			state.FindNextItem();
		}
		else if ( event.target == findPreviousMenuItem )
		{
			state.FindPreviousItem();
		}
		else if ( event.target == onionSkinMenuItem )
		{
			Global.OnionSkinEnabled = !Global.OnionSkinEnabled;
			onionSkinMenuItem.checked = Global.OnionSkinEnabled;
			// Need to do this so that the onion skin gets applied.
			state.UpdateCurrentTileList(CurrentLayer);
		}
		else if ( event.target == firstLayersTopMenuItem )
		{
			Global.DisplayLayersFirstOnTop = !Global.DisplayLayersFirstOnTop;
			firstLayersTopMenuItem.checked = Global.DisplayLayersFirstOnTop;
			state.UpdateMapList();
		}
		else if ( event.target == fullScreenMenuItem )
		{
			if ( stage.displayState != StageDisplayState.NORMAL )
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			else
			{
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
			//event.target.checked = !event.target.checked;
		}
		else if ( event.target.label == "Restore Lost Tool Windows" )
		{
			PopupWindowManager.RecenterAllWindows();
		}
		else if ( event.target.label == "Show Layer Templates" )
		{
			var templatesPopup:LayerTemplateViewer = App.CreatePopupWindow(LayerTemplateViewer, true) as LayerTemplateViewer;
		}
	}
	
	public static function CreatePopupWindow( classType:Class, modal:Boolean, parent:Object = null ):Object
	{
		if ( parent == null )
		{
			parent = App.getApp().stage.nativeWindow;
		}
		var newWindow:PopupWindow = new classType();
		newWindow.systemChrome = NativeWindowSystemChrome.NONE;
		if ( modal )
		{
			newWindow.SetModal();
		}
		newWindow.Owner = parent;
		newWindow.CenterWindow();
		newWindow.open(true);

		PopupWindowManager.RegisterPopup(newWindow, modal ? PopupWindowManager.MODAL : PopupWindowManager.TOOL);
		return newWindow;
	}

	private function menuHelpItemSelected(event:Event):void
	{
		if ( event.target.label == "About" )
		{
			CreatePopupWindow(AboutBox, true);
		}
		else if ( event.target.label == "Help Contents" )
		{
			//if( helpPopup == null )
			//	helpPopup = CreatePopupWindow(HelpWindow, false) as HelpWindow;
			navigateToURL(new URLRequest(currentDir + "/help/index.html"));
		}
		/*else if ( event.target.label == "Online Wiki" )
		{
			navigateToURL( new URLRequest("http://damehelp.dambots.com"));
		}*/
		else if ( event.target.label == "Keyboard Shortcuts" )
		{
			CreatePopupWindow(KeyboardShortcutsPopup, true);
		}
		else if ( event.target.label == "Disable Auto Updates" )
		{
			Global.DisableAutoUpdates = !Global.DisableAutoUpdates;
			event.target.checked = Global.DisableAutoUpdates;
		}
		else if ( event.target.label == "Check For Updates" )
		{
			Global.windowedApp.checkForUpdate();
		}
		/*else if ( event.target.label == "Load Sample 1 (Flixel simple)" )
		{
			currentFile = new File(currentDir + "/samples/SimpleClaws/SimpleClaws.dam");
			Serialize.OpenProject(currentFile, LoadComplete );
		}
		else if ( event.target.label == "Load Sample 2 (Flixel complex)" )
		{
			currentFile = new File(currentDir + "/samples/ComplexClaws/ComplexClaws.dam");
			Serialize.OpenProject(currentFile, LoadComplete );
		}
		else if ( event.target.label == "Load Sample 3 (FlashPunk)" )
		{
			currentFile = new File(currentDir + "/samples/FlashpunkDemo/FlashpunkDemo.dam");
			Serialize.OpenProject(currentFile, LoadComplete );
		}*/
	}
	
	public function stageResizeHandler(event:Event):void
	{
		if ( stage )
		{
			divider.height = stage.stageHeight;
			divider.width = stage.stageWidth;
		}
	}
	
	public function onClose(event:Event):void
	{
		event.preventDefault();
		if ( !HistoryStack.HasChangedSinceSave() )
		{
			Global.SaveSettings(stage.nativeWindow, true);
			//NativeApplication.nativeApplication.exit(); // closes child windows as well.
		}
		else
		{
			AlertBox.Show("Do you want to save your changes before exiting?", "Save project changes.", AlertBox.YES | AlertBox.NO | AlertBox.CANCEL, null, closer, AlertBox.CANCEL);
		}
	}
	
	private function closer(event:CloseEvent):void
	{
		if(event.detail == AlertBox.YES)
		{
			Save();
			Global.SaveSettings(stage.nativeWindow, true);
			//NativeApplication.nativeApplication.exit();
		}
		else if(event.detail == AlertBox.NO)
		{
			Global.SaveSettings(stage.nativeWindow, true);
			//NativeApplication.nativeApplication.exit();
		}
	} 
	
	//{ region Files
	
	private function ExportToImage():void
	{
		CreatePopupWindow(ImageExporter, true);
	}
	
	private function BrowseForExporterPath():void
	{
		var fileChooser:File = new File( Global.CustomExporterPath ? Global.CustomExporterPath.url: null );
		fileChooser.browseForDirectory("Select Exporter Path");
		fileChooser.addEventListener(Event.SELECT, SelectExporterPath);
	}
	
	private function SelectExporterPath(event:Event):void 
	{
		Global.CustomExporterPath = event.target as File;
		Global.CustomExporterPath.removeEventListener(Event.SELECT, SelectExporterPath);
	}
	
	private var doingSaveAs:Boolean;
	
	private function Save():void
	{
		doingSaveAs = false;
		if ( Global.SaveSpritesSeparately )
		{
			if ( Global.CurrentSettingsFile == null )
			{
				SaveSpriteEntriesAs();
			}
			else
			{
				SaveSpritesAsChosenFile(Global.CurrentSettingsFile);
			}
		}
		else if ( currentFile == null )
		{
			Global.CurrentSettingsFile = null;
			SaveAs();
		}
		else
		{
			Global.CurrentSettingsFile = null;
			SaveAsChosenFile(currentFile);
		}
	}
	
	
	private function SaveAs():void
	{
		doingSaveAs = true;
		if ( Global.SaveSpritesSeparately )
		{
			SaveSpriteEntriesAs();
		}
		else
		{
			SaveMainProjectAs();
		}
	}
	
	// Normal files
	
	private function SaveMainProjectAs():void
	{
		var fileChooser:File;
		if (currentFile)
		{
			fileChooser = currentFile;
		}
		else
		{
			fileChooser = File.documentsDirectory.resolvePath('NewProject.dam');
		}
		fileChooser.browseForSave("Save Project As || Don't forget to put .dam at the end!");
		fileChooser.addEventListener(Event.SELECT, CheckSaveAsChosenFile);
	}
	
	private var tempSaveFile:File = null;
	private function CheckSaveAsChosenFile(event:Event):void
	{
		tempSaveFile = event.target as File;
		tempSaveFile.removeEventListener(Event.SELECT, CheckSaveAsChosenFile);
		if ( !tempSaveFile.extension )
		{
			tempSaveFile.nativePath += ".dam";
		}
		else if ( tempSaveFile.extension.toLowerCase() != "dam" )
		{
			AlertBox.Show("You are about to save without the .dam extension. Change to .dam?", "Save As Warning.", AlertBox.YES | AlertBox.NO | AlertBox.CANCEL, null, confirmDamAdd, AlertBox.YES);
			return;
		}
		SaveAsChosenFile(tempSaveFile);
	}
	
	private function confirmDamAdd(event:CloseEvent):void
	{
		if(event.detail == AlertBox.YES)
		{
			tempSaveFile.nativePath = tempSaveFile.nativePath.replace("." + tempSaveFile.extension, ".dam");
			SaveAsChosenFile(tempSaveFile);
		}
		else if ( event.detail == AlertBox.NO)
		{
			SaveAsChosenFile(tempSaveFile);
		}
	}
	
	private function SaveAsChosenFile(file:File):void 
	{
		currentFile = file;
		if ( Global.SaveSpritesSeparately )
		{
			if ( !Global.CurrentSettingsFile )
			{
				AlertBox.Show("No valid location found to save sprite entries to", "Save Warning.", AlertBox.OK);
			}
			else
			{
				Serialize.SaveProject(currentFile, Global.CurrentSettingsFile);
			}
		}
		else
		{
			Serialize.SaveProject(currentFile);
		}
		currentFile.removeEventListener(Event.SELECT, SaveAsChosenFile);
	}
	
	// Sprite entries
	
	private function SaveSpriteEntriesAs():void
	{
		var fileChooser:File;
		if (Global.CurrentSettingsFile)
		{
			fileChooser = Global.CurrentSettingsFile;
		}
		else if ( currentFile )
		{
			fileChooser = currentFile.clone();
		}
		else
		{
			fileChooser = File.documentsDirectory.resolvePath('NewSprites.dsf');
		}
		fileChooser.browseForSave("Save Sprites As || Don't forget to put .dsf at the end!");
		fileChooser.addEventListener(Event.SELECT, CheckSaveSpritesAsChosenFile);
	}
	
	private function CheckSaveSpritesAsChosenFile(event:Event):void
	{
		tempSaveFile = event.target as File;
		tempSaveFile.removeEventListener(Event.SELECT, CheckSaveSpritesAsChosenFile);
		if ( !tempSaveFile.extension )
		{
			tempSaveFile.nativePath += ".dsf";
		}
		else if ( tempSaveFile.extension.toLowerCase() != "dsf" )
		{
			AlertBox.Show("You are about to save sprites without the .dsf extension. Change to .dsf?", "Save As Warning.", AlertBox.YES | AlertBox.NO | AlertBox.CANCEL, null, confirmSpritesDamAdd, AlertBox.YES);
			return;
		}
		SaveSpritesAsChosenFile(tempSaveFile);
	}
	
	private function confirmSpritesDamAdd(event:CloseEvent):void
	{
		if(event.detail == AlertBox.YES)
		{
			tempSaveFile.nativePath = tempSaveFile.nativePath.replace("." + tempSaveFile.extension, ".dsf");
			SaveSpritesAsChosenFile(tempSaveFile);
		}
		else if ( event.detail == AlertBox.NO)
		{
			SaveSpritesAsChosenFile(tempSaveFile);
		}
	}
	
	private function SaveSpritesAsChosenFile(file:File ):void 
	{
		Global.CurrentSettingsFile = file;
		Global.CurrentSettingsFile.removeEventListener(Event.SELECT, SaveSpritesAsChosenFile);
		if ( doingSaveAs || !currentFile )
		{
			SaveMainProjectAs();
		}
		else
		{
			SaveAsChosenFile( currentFile )
		}
	}
	
	// End saving
	
	private function menuRecentFilesItemSelected(event:Event ):void
	{
		if ( !HistoryStack.HasChangedSinceSave() )
		{
			OpenRecent(null);
		}
		else
		{
			AlertBox.Show("You have unsaved changes. Do you wish to continue?", "Overwrite file?", AlertBox.YES | AlertBox.CANCEL, null, OpenRecent, AlertBox.CANCEL);
		}
		
		function OpenRecent(closeEvent:CloseEvent):void
		{
			if (!closeEvent || closeEvent.detail == AlertBox.YES)
			{
				game.restoreFocus();	// Just in case focus was lost.
				currentFile = new File(event.target.label);
				Serialize.OpenProject(currentFile, LoadComplete );
			}
		}
	}
	
	private function TryOpen(event:CloseEvent):void
	{
		if (!event || event.detail == AlertBox.YES)
		{
			var fileChooser:File;
			if (currentFile)
			{
				  fileChooser = currentFile;
			}
			else
			{
				  fileChooser = File.documentsDirectory.resolvePath('NewProject.dam');
			}
			var filter:FileFilter = new FileFilter("DAM project files", "*.dam");
			fileChooser.browseForOpen("Open Project", [filter]);
			fileChooser.addEventListener(Event.SELECT, OpenChosenFile);
		}
	}
	
	private function Open():void
	{
		if ( !HistoryStack.HasChangedSinceSave() )
		{
			TryOpen(null);
		}
		else
		{
			AlertBox.Show("You have unsaved changes. Do you wish to continue?", "Overwrite file?", AlertBox.YES | AlertBox.CANCEL, null, TryOpen, AlertBox.CANCEL);
		}
	}
	
	private function OpenChosenFile(event:Event):void 
	{
		currentFile = event.target as File;
		Serialize.OpenProject(currentFile, LoadComplete );
		//SaveMenuItem.enabled = SaveAsMenuItem.enabled = true;
		currentFile.removeEventListener(Event.SELECT, OpenChosenFile);
	}
	
	
	private function LoadComplete():void
	{
		layerChangedCallback();
	}
	
	private function Export( projectOnly:Boolean ):void
	{
		var exporterWindow:ExporterPopup = CreatePopupWindow(ExporterPopup, true) as ExporterPopup;
		if ( exporterWindow )
		{
			exporterWindow.UseProjectExporters = projectOnly;
		}
		return;
		
	}
	
	public function ShowTilemapImageViewer():void
	{
		if ( CurrentLayer && CurrentLayer.map )
		{
			var viewer:TilemapImageViewer = CreatePopupWindow( TilemapImageViewer, true ) as TilemapImageViewer;
			if ( viewer )
			{
				viewer.layer = CurrentLayer as LayerMap;
			}
		}
		else if ( CurrentLayer is LayerSprites )
		{
			var state:EditorState = FlxG.state as EditorState;
			var drawEditor:EditorTypeDraw = state.getCurrentEditor(this) as EditorTypeDraw;
			if ( drawEditor && drawEditor.CanModifySpriteFrames() && drawEditor.GetSelectedSprite() )
			{
				viewer = CreatePopupWindow( TilemapImageViewer, true ) as TilemapImageViewer;
				if ( viewer )
				{
					viewer.sprite = drawEditor.GetSelectedSprite().spriteEntry;
				}
			}
			else
			{
				var spriteEditor:EditorTypeSprites = state.getCurrentEditor(this) as EditorTypeSprites;
				if ( spriteEditor && spriteEditor.CurrentTileListSpriteEntry )
				{
					viewer = CreatePopupWindow( TilemapImageViewer, true ) as TilemapImageViewer;
					if ( viewer )
					{
						viewer.sprite = spriteEditor.CurrentTileListSpriteEntry;
					}
				}
			}
		}
	}
	
	//} endregion
	
}
}

