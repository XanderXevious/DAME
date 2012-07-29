package com.Editor 
{
	import com.EditorState;
	import com.Game.EditorAvatar;
	import com.Game.ShapeObject;
	import com.Game.TextObject;
	import com.Layers.LayerEntry;
	import com.Operations.HistoryStack;
	import com.Operations.OperationAddAvatar;
	import com.Operations.OperationPasteAvatars;
	import com.Properties.PropertyData;
	import com.Properties.PropertyType;
	import com.Utils.Global;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	import com.Layers.LayerShapes;
	import com.UI.TextEditor;
	import com.UI.advancedColorPicker;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class EditorTypeShapes extends EditorTypeSprites
	{
		public static const DRAW_SQUARES:uint = 0;
		public static const DRAW_CIRCLES:uint = 1;
		public static const DRAW_TEXT:uint = 2;
		
		public static var DrawType:uint = DRAW_SQUARES;
		
		protected static var _isActive:Boolean = false;
		public static function IsActiveEditor():Boolean { return _isActive; };
		
		private var editTextMenuItem:NativeMenuItem = null;
		
		public function EditorTypeShapes( editor:EditorState ) 
		{
			super( editor );
			layerClassType = LayerShapes;
			dontDrawSprites = true;
			
			editTextMenuItem = addNewContextMenuItem(contextMenu, "Edit Text", contextMenuHandler );
			addNewContextMenuItem(contextMenu, "Change Colour", contextMenuHandler );
			
			contextMenu.removeItem(attachMenuItem);
			contextMenu.removeItem(detachMenuItem);
		}
		
		override public function Update(isActive:Boolean, isSelecting:Boolean, leftMouseDown:Boolean, rightMouseDown:Boolean ):void
		{
			super.Update(isActive, isSelecting, leftMouseDown, rightMouseDown );
			
			_isActive = isActive;
		}
		
		override protected function Paint( layer:LayerEntry ):void
		{
			var shapeLayer:LayerShapes = App.getApp().CurrentLayer as LayerShapes;
			
			if ( shapeLayer == null )
			{
				return;
			}
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			modifiedMousePos.multiplyBy(FlxG.invExtraZoom);
			
			var newShape:ShapeObject;
			if ( DrawType == DRAW_TEXT )
			{
				newShape = new TextObject( modifiedMousePos.x, modifiedMousePos.y, "Right click to edit text.", shapeLayer );
				newShape.width = 100;
			}
			else
			{
				newShape = new ShapeObject( modifiedMousePos.x, modifiedMousePos.y, DrawType == DRAW_CIRCLES, shapeLayer );
			}

			newShape.GetSnappedPos( modifiedMousePos, modifiedMousePos, true);
			newShape.x = modifiedMousePos.x;
			newShape.y = modifiedMousePos.y;
			
			newShape.CreateGUID();
			
			HistoryStack.BeginOperation( new OperationAddAvatar( this, shapeLayer, newShape ) );
				
			shapeLayer.sprites.add(newShape, true);
			selectedSprites.length = 0;
			selectionChanged = true;
			selectedSprites.push(newShape);
		}
		
		override public function CopyData():void
		{
			if ( selectedSprites.length == 0 )
			{
				return;
			}
			
			var data:ShapeClipboardData = new ShapeClipboardData();
			var i:uint = selectedSprites.length;
			while ( i-- )
			{
				data.avatars.push( selectedSprites[i].CreateClipboardCopy() );
			}
			Clipboard.SetData( data );
		}
		
		override public function PasteData():void
		{
			var data:ShapeClipboardData = Clipboard.GetData( ) as ShapeClipboardData;
			
			if ( data == null )
			{
				return;
			}
			
			var shapeLayer:LayerShapes = App.getApp().CurrentLayer as LayerShapes;
			
			if ( shapeLayer == null || !shapeLayer.IsVisible() || shapeLayer.Locked())
			{
				return;
			}
			
			centerMousePosToScreen( shapeLayer );
			
			var modifiedMousePos:FlxPoint = FlxPoint.CreateObject(mousePos);
			
			selectionChanged = true;
			selectedSprites.length = 0;
			
			var i:uint = data.avatars.length;
			
			data.avatars[0].GetSnappedPos(mousePos, modifiedMousePos, false);
			var xOffset:Number = data.avatars[0].x - modifiedMousePos.x;
			var yOffset:Number = data.avatars[0].y - modifiedMousePos.y;
			
			var newAvatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>;
			while ( i-- )
			{
				var newSprite:EditorAvatar = data.avatars[i].CreateClipboardCopy();
				newSprite.x -= xOffset;
				newSprite.y -= yOffset;
				newSprite.layer = shapeLayer;
				shapeLayer.sprites.add(newSprite, true);
				shapeLayer.UpdateMinMax( newSprite );
				selectedSprites.push(newSprite);
				newAvatars.push(newSprite);
			}
			
			HistoryStack.BeginOperation( new OperationPasteAvatars(this, shapeLayer, newAvatars) );
		}
		
		override protected function DecideContextMenuActivation( ):void
		{
			selectionChanged = true;
			selectedSprites.length = 0;
			// If we click down on an already selected sprite then we initiate move mode.

			var shapeLayer:LayerShapes = App.getApp().CurrentLayer as LayerShapes;
			if ( shapeLayer && shapeLayer.IsVisible() )
			{
				for each( var avatar:ShapeObject in shapeLayer.sprites.members )
				{
					if ( avatar.IsOverScreenPos( mouseScreenPos, false ) )
					{
						selectedSprites.push( avatar );
						editTextMenuItem.enabled = (avatar is TextObject);
						contextMenu.display( FlxG.stage, FlxG.stage.mouseX, FlxG.stage.mouseY );
						// Only select the first one.
						return;
					}
				}
			}
		}
		
		override protected function contextMenuHandler(event:Event):void
		{			
			switch( event.target.label )
			{
				case "Edit Text":
				if ( selectedSprites.length )
				{
					var text:TextObject = selectedSprites[0] as TextObject;
					var editor:TextEditor = App.CreatePopupWindow(TextEditor, true) as TextEditor;
					editor.textObject = text;
				}
				break;
				
				case "Change Colour":
				if ( selectedSprites.length )
				{
					var shape:ShapeObject = selectedSprites[0] as ShapeObject;
					var pop1:* = App.CreatePopupWindow(advancedColorPicker, true);
					if ( pop1 )
					{
						pop1.EnableAlpha( shape.colourOverriden ? shape.alphaValue : Global.ShapeAlpha );
						pop1.setColorRGB( shape.colourOverriden ? shape.fillColour : Global.ShapeColour );
						pop1.addEventListener(MouseEvent.CLICK, setColor);
			
						function setColor():void
						{
							var color:uint = pop1.getColorRGB();
							for each( var sprite:EditorAvatar in selectedSprites )
							{
								shape = sprite as ShapeObject;
								if ( shape )
								{
									shape.colourOverriden = true;
									shape.fillColour = color;
									shape.forceRedraw = true;
									shape.alphaValue = pop1.Alpha.value;
								}
							}
						}
					}
				}
				break;
				
				default:
				super.contextMenuHandler(event);
				break;
			}
		}
		
	}

}

import com.Game.EditorAvatar;

internal class ShapeClipboardData
{
	public var avatars:Vector.<EditorAvatar> = new Vector.<EditorAvatar>();
}