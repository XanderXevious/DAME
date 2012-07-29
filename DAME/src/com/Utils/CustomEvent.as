package com.Utils 
{
	import flash.events.Event;
	/**
	* ...
	* @author Charles Goatley
	*/
	public class CustomEvent extends Event
	{
		public static const CUSTOM:String = "custom";
		public var arg:*;

		public function CustomEvent(type:String, customArg:*=null,bubbles:Boolean=false,cancelable:Boolean = false) 
		{
			super(type, bubbles, cancelable);
			this.arg = customArg;
		}

		public override function clone():Event 
		{
			return new CustomEvent(type, arg, bubbles, cancelable);
		}

		public override function toString():String 
		{
			return formatToString("CustomEvent", "type", "arg","bubbles", "cancelable", "eventPhase");
		}
	}

}