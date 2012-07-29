package com.Game 
{
	import org.flixel.FlxPoint;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class AvatarAttachment
	{
		private var _parent:Avatar = null;
		public function get Parent():Avatar { return _parent; }
		private var _child:Avatar = null;
		public function get Child():Avatar { return _child; }
		
		private var storedPos:FlxPoint = new FlxPoint();
		private var storedScreenPos:FlxPoint = new FlxPoint();
		
		public var Offset:FlxPoint = new FlxPoint();

		public var percentInSegment:Number = 0;	// the object is this far through (0-1) segmentNumber
		public var segmentNumber:Number = 0;
		
		public function AvatarAttachment( thisAvatar:Avatar, child:Avatar, parent:Avatar, makeEmpty:Boolean = false ) 
		{
			if ( makeEmpty )
				return;
			if ( child && parent )
			{
				throw new Error("AvatarAttachment: Cannot have both child and parent attached");
			}
			else if ( child ==null && parent == null )
			{
				throw new Error("AvatarAttachment: Must set child or parent");
			}
			_child = child;
			_parent = parent;
			
			storedPos = FlxPoint.CreateObject(thisAvatar);
			thisAvatar.getScreenXY( storedScreenPos );
		}
		
		public function Update( thisAvatar:Avatar ):void
		{
			// If I'm at a new screenpos then child must move with me by same amount.
			// If the child is at a new screenpos then child must move to closest pos on parent.
			if ( _parent )
			{
				
			}
			else if ( _child )
			{
				thisAvatar.GetAttachmentPosition(_child);
			}
		}
		
		public function Clone():AvatarAttachment
		{
			var attach:AvatarAttachment = new AvatarAttachment(null, null, null, true );
			attach._child = _child;
			attach._parent = _parent;
			attach.storedPos = storedPos.copy();
			attach.storedScreenPos = storedScreenPos.copy();
			attach.Offset = Offset.copy();
			attach.percentInSegment = percentInSegment;
			attach.segmentNumber = segmentNumber;
			return attach;
		}
		
	}

}