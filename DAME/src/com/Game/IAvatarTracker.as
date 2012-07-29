package com.Game 
{
	
	/**
	 * Tracks references to avatars so messages like kill() can be dispatched to all
	 * classes that have a reference to an avatar.
	 * @author Charles Goatley
	 */
	public interface IAvatarTracker 
	{
		function RemoveReference( avatar:Avatar ):void;
	}
	
}