package com.Operations 
{
	import com.Game.AvatarLink;
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationDeleteLink extends IOperation
	{
		private var _link:AvatarLink;
		
		public function OperationDeleteLink( link:AvatarLink) 
		{
			_link = link;
		}
		
		override public function Undo():void
		{
			_link.RegisterLink();
		}
		
	}

}