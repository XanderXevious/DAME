package com.Game 
{
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class AvatarWrapper
	{
		private var _avatar:Avatar = null;
		private var _owner:IAvatarTracker;
		
		public function get avatar():Avatar
		{
			return _avatar;
		}
		protected function set avatar( newAvatar:Avatar ):void
		{
			if ( _avatar != null )
			{
				_avatar.RemoveReferenceCount( _owner );
			}
			_avatar = newAvatar;
			if ( _avatar )
			{
				_avatar.AddReferenceCount( _owner );
			}
		}
		
		public function AvatarWrapper( owner:IAvatarTracker, newAvatar:Avatar = null ) 
		{
			_owner = owner;
			avatar = newAvatar;
		}
		
	}

}