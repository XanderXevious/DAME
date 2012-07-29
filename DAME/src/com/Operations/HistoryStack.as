package com.Operations 
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author Charles Goatley
	 */
	public class HistoryStack
	{
		private static const MAX_HISTORY:uint = 60;
		private static var history:Vector.<IOperation> = new Vector.<IOperation>();
		private static var operationAtLastSave:IOperation = null;
		private static var totalOperationsMadeSinceSave:int = 0;
		
		private static function getClass(obj:Object):Class
		{
			return Class(getDefinitionByName(getQualifiedClassName(obj)));
		}
		
		public static function BeginOperation( operation:IOperation ):void
		{
			/*if ( !allowConsecutive )
			{
				if ( history.length && getClass(history[history.length - 1]) is getClass(operation) )
				{
					return;
				}
			}*/
			history.push(operation);
			totalOperationsMadeSinceSave++;
			if ( history.length >= MAX_HISTORY )
			{
				history.shift().Removed();
			}
			
			App.getApp().UndoMenuItem.enabled = true;
		}
		
		public static function GetLastOperation( ):IOperation
		{
			return history.length ? history[history.length - 1] : null;
		}
		
		public static function CancelLastOperation( lastOperation:IOperation ):void
		{
			if ( history.length > 0 && history[history.length - 1] == lastOperation )
			{
				if ( operationAtLastSave == lastOperation )
				{
					operationAtLastSave = null;
				}
				history.pop().Removed();
				totalOperationsMadeSinceSave--;
			}
			App.getApp().UndoMenuItem.enabled = history.length > 0;
		}
		
		public static function Undo():void
		{
			if ( history.length )
			{
				var operation:IOperation = history.pop();
				operation.Undo();
				operation.Removed();
				if ( totalOperationsMadeSinceSave > 0)
				{
					totalOperationsMadeSinceSave--;
				}
			}
			
			if ( history.length == 0 )
			{
				App.getApp().UndoMenuItem.enabled = false;
			}
		}
		
		public static function Clear():void
		{
			var i:uint = history.length;
			while ( i-- )
			{
				history[i].Removed();
			}
			history.length = 0;
			operationAtLastSave = null;
			totalOperationsMadeSinceSave = 0;
			App.getApp().UndoMenuItem.enabled = false;
		}
		
		public static function RecordSave():void
		{
			if ( history.length )
			{
				operationAtLastSave = history[history.length - 1];
			}
			totalOperationsMadeSinceSave = 0;
		}
		
		public static function IsEmpty():Boolean
		{
			return history.length == 0;
		}
		
		public static function IsFull():Boolean
		{
			return history.length >= MAX_HISTORY - 1;
		}
		
		public static function HasChangedSinceSave():Boolean
		{
			if ( history.length == 0 && operationAtLastSave == null && totalOperationsMadeSinceSave==0)
			{
				return false;
			}
			else if ( history.length && history[history.length - 1] == operationAtLastSave )
			{
				return false;
			}
			return true;
		}
		
	}

}