package com.Game 
{
	import com.Tiles.SpriteEntry;
	import org.flixel.data.FlxAnim;
	import org.flixel.FlxPoint;
	import org.flixel.FlxSprite;
	import org.flixel.FlxG;
	import org.flixel.FlxU;
	import com.Utils.DebugDraw;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class Avatar extends FlxSprite implements IAvatarTracker
	{
		protected var _lastValidPos: FlxPoint = null;
		protected var _references:Vector.<AvatarTrackerReference> = new Vector.<AvatarTrackerReference>();
		
		// A temporary list of tile indices to ignore hits for in this update.
		public var ignoreTileHits: Vector.<uint> = new Vector.<uint>;
		
		public var z:Number = 0;
		
		public var isoTopLeft:FlxPoint = null;
		public var isoBottomRight:FlxPoint = null;
		
		protected static const roundingError:Number = 0.0000001;
		
		public function get realPos():FlxPoint
		{
			return new FlxPoint( realX, realY );
		}
		public function get realX():Number
		{
			return x + offset.x;
		}
		public function get realY():Number
		{
			return y + height;
		}
		
		public function get validPos():FlxPoint
		{
			return ( _lastValidPos ? _lastValidPos : realPos );
		}
		
		public var attachment:AvatarAttachment = null;
		
		public function Avatar(X:Number,Y:Number) 
		{
			super( X, Y );
		}
		
		public function GetCurrentAnim() :FlxAnim
		{
			return _curAnim;
		}
		
		override public function update():void
		{
			
			super.update();
			
			if ( attachment )
			{
				attachment.Update(this);
			}
			
		}
		
		override public function kill():void
		{
			super.kill();
			// Let all interested parties know that this avatar is removed from the game.
			for each( var ref:AvatarTrackerReference in _references )
			{
				if ( ref.tracker)
				{
					ref.tracker.RemoveReference( this );
				}
			}
			_references.length = 0;
			
			// Because the playstate will always have a reference, let it know too
			/*var playstate:PlayState = FlxG.state as PlayState;
			if ( playstate )
			{
				playstate.RemoveReference( this );
			}*/
		}
		
		public function AddReferenceCount( tracker:IAvatarTracker ):void
		{
			for each( var ref:AvatarTrackerReference in _references )
			{
				if ( ref.tracker == tracker )
				{
					ref.count++;
					return;
				}
			}
			_references.push( new AvatarTrackerReference(tracker) );
		}
		
		public function RemoveReferenceCount( tracker:IAvatarTracker ):void
		{
			var i:int;
			for ( i = 0; i < _references.length; i++ )
			{
				var ref:AvatarTrackerReference = _references[i];
				if ( ref.tracker == tracker )
				{
					ref.count--;
					if ( ref.count == 0 )
					{
						_references.splice( i, 1 );
					}
					return;
				}
			}
		}
		
		public function RemoveReference( avatar:Avatar ):void
		{
			var i:int;
			for ( i = 0; i < _references.length; i++ )
			{
				var ref:AvatarTrackerReference = _references[i];
				if ( ref.tracker == avatar )
				{
					_references.splice( i, 1 );
					return;
				}
			}
		}
		
		public function adjustHorizontalVelocity( reductionPerSecond:Number, minSpeed:Number = 0 ):void
		{
			if ( velocity.x == 0 )
			{
				return;
			}
			var sign: int = velocity.x >= 0 ? 1 : -1;
			var velDiff:Number = reductionPerSecond * FlxG.elapsed * sign;
			velocity.x -= velDiff;
			if ( ( sign == 1 && velocity.x < minSpeed )
				|| ( sign == -1 && velocity.x > -minSpeed ) )
			{
				velocity.x = minSpeed * sign;
			}
		}
		
		/**
		 * Returns the horizontal distance from the edges of the two avatars.
		 */
		public function GetHorizDistToAvatar( avatar:Avatar ):int
		{
			//TODO fix the dist functions to cope with the offset not necessarily being in the avatar centre.
			return Math.abs( avatar.realX - realX ) - ( (width/2) + (avatar.width/2) );
		}
		
		/**
		 * Returns the horizontal distance from the edges of the two avatars.
		 */
		public function GetHorizDistFromPointToAvatar( xpos:Number ):uint
		{
			return Math.abs( realX -  xpos ) - (width/2 );
		}
		
		/**
		 * Returns the vertical distance of the two avatars.
		 */
		public function GetVertDistToAvatar( avatar:Avatar ):uint
		{
			return Math.abs( y - avatar.y );
		}
		
		public function DrawBoundingBox( colour:uint, stepped:Boolean, showHandles:Boolean = false ):void
		{
			DebugDraw.DrawBox(left>>FlxG.zoomBitShifter, top>>FlxG.zoomBitShifter, right>>FlxG.zoomBitShifter, bottom>>FlxG.zoomBitShifter, angle, scrollFactor, stepped, colour, !stepped, showHandles);
		}
		
		public function GetAnimPercent():Number
		{
			if ( _curAnim == null || _curAnim.delay == 0)
			{
				return 0;
			}

			return ( _curFrame / _curAnim.frames.length ) + ( _frameTimer / _curAnim.delay );
		}
		
		// attach a child avatar to this.
		public function AttachAvatar( attached:Avatar ):void
		{
			if ( attachment == null && attached.attachment == null)
			{
				attachment = new AvatarAttachment(this, attached,null);
				attached.attachment = new AvatarAttachment(attached, null, this);
				RefreshAttachmentValues();
			}
			
		}
		
		public function DetachAvatar( ):void
		{
			if ( attachment )
			{
				if ( attachment.Parent && attachment.Parent.attachment )
				{
					attachment.Parent.attachment = null;
				}
				else if (attachment.Child && attachment.Child.attachment )
				{
					attachment.Child.attachment = null;
				}
				attachment = null;
				
			}
		}
		
		// This updates any info like attachment offsets if needed.
		public function RefreshAttachmentValues( ):void { }
		
		// This updates the position of the attachedAvatar based on offsets and scrollfactors.
		public function GetAttachmentPosition( attachedAvatar:Avatar ):void
		{
			if ( scrollFactor.equals(attachedAvatar.scrollFactor ) )
			{
				attachedAvatar.x = x + attachedAvatar.attachment.Offset.x;
				attachedAvatar.y = y + attachedAvatar.attachment.Offset.y;
			}
			else
			{
				// getScreenXY()
				var screenPos:FlxPoint = new FlxPoint();
				screenPos.x = FlxU.floor(x + roundingError)+FlxU.floor(FlxG.scroll.x*scrollFactor.x) + attachedAvatar.attachment.Offset.x;
				screenPos.y = FlxU.floor(y + roundingError)+FlxU.floor(FlxG.scroll.y*scrollFactor.y) + attachedAvatar.attachment.Offset.y;
				
				//getMapXYFromScreenXY (inverse of getScreenXY):
				attachedAvatar.x = FlxU.floor( screenPos.x + roundingError) - FlxU.floor(FlxG.scroll.x*attachedAvatar.scrollFactor.x);
				attachedAvatar.y = FlxU.floor( screenPos.y + roundingError) - FlxU.floor(FlxG.scroll.y*attachedAvatar.scrollFactor.y);
			}
		}
		
		public function UpdateAttachment():void {}
		
		public function OnResize( ):void
		{
			if ( attachment && attachment.Parent )
			{
				attachment.Parent.GetAttachmentPosition(this);
			}
			UpdateAttachment();
		}
		
		public function OnRotate():void
		{
			if ( attachment && attachment.Parent )
			{
				attachment.Parent.GetAttachmentPosition(this);
			}
			UpdateAttachment();
		}
		
	}

}