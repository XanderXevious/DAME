package com.Game 
{
	/**
	 * Counts references to instances of IAvatarTracker
	 * @author Charles Goatley
	 */
	public class AvatarTrackerReference
	{
		private var _tracker:IAvatarTracker = null;
		public function get tracker():IAvatarTracker { return _tracker };
		public var count:uint = 0;
		
		public function AvatarTrackerReference( newTracker:IAvatarTracker ) 
		{
			_tracker = newTracker;
		}
		
	}

}