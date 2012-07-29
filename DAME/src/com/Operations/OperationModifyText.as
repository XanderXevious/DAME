package com.Operations 
{
	import com.Game.EditorAvatar;
	import com.Game.TextObject;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class OperationModifyText extends IOperation
	{
		private var avatar:TextObject;
		private var format:TextFormat;
		private var text:String;
		
		public function OperationModifyText( _avatar:TextObject ) 
		{
			avatar = _avatar;
			format = _avatar.text.getTextFormat();
			text = avatar.text.text;
		}
		
		override public function Undo():void
		{
			avatar.text.text = text;
			avatar.text.setFormat(format.font, Number(format.size), uint(format.color), format.align, avatar.text.shadow);
			avatar.text.Regen();
		}
		
	}

}
