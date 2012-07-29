package com.Game 
{
	import com.EditorState;
	import com.Layers.LayerEntry;
	import com.Utils.DebugDraw;
	import com.Utils.Misc;
	import flash.display.Shape;
	import mx.collections.ArrayCollection;
	import org.flixel.FlxG;
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class AvatarLink
	{
		public var fromAvatar:EditorAvatar;
		public var toAvatar:EditorAvatar;
		
		public var properties:ArrayCollection = new ArrayCollection();
		
		private static var Links:Vector.<AvatarLink> = new Vector.<AvatarLink>;
		
		private static var pulseAlpha:Number = 1;
		private static var pulseDirection:Number = 1;
		private static var lineTimer:Number = 0;
		
		public static function GenerateLink(from:EditorAvatar, to:EditorAvatar):AvatarLink
		{
			// Only add the link if a link doesn't already exist containing these 2 avatars in either direction.
			var i:uint = Links.length;
			while (i--)
			{
				if ( Links[i].fromAvatar == from && Links[i].toAvatar == to )
				{
					return null;
				}
				if ( Links[i].fromAvatar == to && Links[i].toAvatar == from )
				{
					return null;
				}
			}
			return new AvatarLink(from, to );
		} 
		
		public function RegisterLink():void
		{
			// Only add the link if a link doesn't already exist containing these 2 avatars in either direction.
			var i:uint = Links.length;
			while (i--)
			{
				if ( Links[i].fromAvatar == fromAvatar && Links[i].toAvatar == toAvatar )
				{
					return;
				}
				if ( Links[i].fromAvatar == toAvatar && Links[i].toAvatar == fromAvatar )
				{
					return;
				}
			}
			toAvatar.linksFrom.push(this);
			fromAvatar.linksTo.push(this);
			Links.push(this);
		}
		
		public function AvatarLink( from:EditorAvatar, to:EditorAvatar, register:Boolean = true ) 
		{
			fromAvatar = from;
			toAvatar = to;
			if ( register )
			{
				toAvatar.linksFrom.push(this);
				fromAvatar.linksTo.push(this);
				Links.push(this);
			}
		}
		
		public function Clone():AvatarLink
		{
			var link:AvatarLink = new AvatarLink(fromAvatar, toAvatar, false);
			link.properties = properties;
			return link;
		}
		
		public static function RemoveLink(link:AvatarLink):void
		{
			var i:int = Links.indexOf(link);
			if ( i != -1 )
			{
				Links.splice(i, 1);
			}
			
			i = link.fromAvatar.linksTo.indexOf(link);
			if ( i != -1 )
			{
				link.fromAvatar.linksTo.splice(i,1);
			}
			
			i = link.toAvatar.linksFrom.indexOf(link);
			if ( i != -1 )
			{
				link.toAvatar.linksFrom.splice(i,1);
			}
		}
		
		public function DistanceFrom(screenPos:FlxPoint):Number
		{
			var fromPos:FlxPoint = EditorState.getScreenXYFromMapXY(fromAvatar.x + fromAvatar.width / 2, fromAvatar.y + fromAvatar.height / 2, fromAvatar.layer.xScroll, fromAvatar.layer.yScroll);
			var toPos:FlxPoint = EditorState.getScreenXYFromMapXY(toAvatar.x + toAvatar.width / 2, toAvatar.y + toAvatar.height / 2, toAvatar.layer.xScroll, toAvatar.layer.yScroll);
			var closest:FlxPoint = new FlxPoint;
			Misc.ClosestPointOnSegment(fromPos, toPos, screenPos, closest);
			return closest.distance_to(screenPos);
		}
		
		public static function DrawLinksForLayer(layer:LayerEntry, selectedLink:AvatarLink ):void
		{
			pulseAlpha += pulseDirection * FlxG.elapsed;
			if ( pulseDirection == 1 && pulseAlpha > 1)
			{
				pulseDirection = -1;
				pulseAlpha = 1;
			}
			else if ( pulseDirection == -1 && pulseAlpha < 0 )
			{
				pulseDirection = 1;
				pulseAlpha = 0;
			}
			lineTimer += FlxG.elapsed;
			if ( lineTimer > 1 )
			{
				lineTimer = 0;
			}
			var fromPos:FlxPoint = new FlxPoint;
			var toPos:FlxPoint = new FlxPoint;
			var scroll:FlxPoint = new FlxPoint(layer.xScroll, layer.yScroll);
			
			var arrow:Shape = new Shape;
			arrow.graphics.beginFill(0xffffff, 1);
			arrow.graphics.lineTo( -10, 0);
			arrow.graphics.lineTo( 0, -10 );
			arrow.graphics.lineTo( 0, 0 );
			arrow.graphics.endFill();
			
			var i:uint = Links.length;
			while (i--)
			{
				var link:AvatarLink = Links[i];
				if ( link.fromAvatar.layer == layer || link.toAvatar.layer == layer )
				{
					var fromAvatar:EditorAvatar = link.fromAvatar;
					var toAvatar:EditorAvatar = link.toAvatar;
					fromPos.create_from_points(fromAvatar.x + fromAvatar.width / 2, fromAvatar.y + fromAvatar.height / 2);
					toPos.create_from_points(toAvatar.x + toAvatar.width / 2, toAvatar.y + toAvatar.height / 2);
					
					if ( fromAvatar.layer != layer )
					{
						fromPos = EditorState.getScreenXYFromMapXY(fromPos.x, fromPos.y, fromAvatar.layer.xScroll, fromAvatar.layer.yScroll, false);
						fromPos = EditorState.getMapXYFromScreenXY(fromPos.x, fromPos.y, layer.xScroll, layer.yScroll);
					}
					if ( toAvatar.layer != layer )
					{
						toPos = EditorState.getScreenXYFromMapXY(toPos.x, toPos.y, toAvatar.layer.xScroll, toAvatar.layer.yScroll, false);
						toPos = EditorState.getMapXYFromScreenXY(toPos.x, toPos.y, layer.xScroll, layer.yScroll);
					}
					fromPos.multiplyBy(FlxG.extraZoom);
					toPos.multiplyBy(FlxG.extraZoom);
					var colour:uint = 0xffffffff;
					if ( selectedLink == link )
					{
						colour = Misc.blendARGB(0x55000000, 0xffffffff, pulseAlpha);
					}
					
					
					DebugDraw.DrawLine(fromPos.x, fromPos.y, toPos.x, toPos.y, scroll, false, colour, true, selectedLink != link);
					/*if ( selectedLink == link )
					{
						// Draw a little pulse from fromPos to toPos;
						colour = Misc.blendARGB(0xffffffff, 0xff000000, pulseAlpha);
						fromPos.x = Misc.lerp(lineTimer, fromPos.x, toPos.x);
						fromPos.y = Misc.lerp(lineTimer, fromPos.y, toPos.y);
						var endTime:Number = Math.min(lineTimer + 0.03, 1.01);
						var currentX:Number = Misc.lerp(endTime, fromPos.x, toPos.x);
						toPos.y = Misc.lerp(endTime, fromPos.y, toPos.y);
						
						DebugDraw.DrawLine(fromPos.x, fromPos.y, toPos.x, toPos.y, scroll, false, colour, true, false);
						DebugDraw.DrawBox(fromPos.x - 2, fromPos.y - 2, fromPos.x + 2, fromPos.y + 2, 0, scroll, false, colour, false);
						
					}*/
					var lineLength:Number = fromPos.distance_to(toPos);
					var drawnSize:Number = Misc.clamp(Math.sqrt(lineLength), 5, 15) * FlxG.extraZoom;
					if ( FlxG.zoomScale < 1 )
					{
						drawnSize /= FlxG.zoomScale;
					}
					DebugDraw.DrawArrow(fromPos.x, fromPos.y, toPos.x, toPos.y, scroll, colour, drawnSize);

					//DebugDraw.DrawBox(toPos.x - 2, toPos.y - 2,toPos.x + 2, toPos.y + 2, 0, new FlxPoint(layer.xScroll, layer.yScroll), false, 0xffffffff, true, false);
				}
			}
		}
		
		public static function GetLinks():Vector.<AvatarLink>
		{
			return Links;
		}
		
		public static function ClearAllLinks():void
		{
			Links.length = 0;
		}
		
	}

}