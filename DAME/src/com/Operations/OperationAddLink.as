package com.Operations 
{
	import com.Game.AvatarLink;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationAddLink extends IOperation
	{
		private var _link:AvatarLink;
		
		public function OperationAddLink( link:AvatarLink) 
		{
			_link = link;
		}
		
		override public function Undo():void
		{
			AvatarLink.RemoveLink(_link);
		}
		
	}

}