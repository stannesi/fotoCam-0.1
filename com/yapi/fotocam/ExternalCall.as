package com.yapi.fotocam
{	
	import flash.external.ExternalInterface;
	
	public class ExternalCall
	{
		public function ExternalCall()
		{
			// constructor code
		}
		
		public static function simple(callback:String):void
		{
			ExternalInterface.call(callback);
		}

		public static function complex(callback:String, obj:Object):void
		{
			ExternalInterface.call(callback, escapeMessage(obj));
		}

		public static function byteProgress(callback:String, bytes_loaded:uint, bytes_total:uint):void
		{
			ExternalInterface.call(callback, escapeMessage(bytes_loaded), escapeMessage(bytes_total));
		}

		public static function uploadSuccess(callback:String, server_data:String):void
		{
			ExternalInterface.call(callback, escapeMessage(server_data));
		}

		public static function error(callback:String, msg:String):void
		{
			ExternalInterface.call(callback, escapeMessage(msg));
		}
		
		public static function debug(callback:String, msg:String):void
		{
			trace("JS Callback: " + callback + "\n" + "Message: " + msg + "\n");
			ExternalInterface.call(callback, escapeMessage(msg));
		}

		/* escapes all the backslashes which are not translated correctly in the Flash -> JavaScript Interface
		 * 
		 * These functions had to be developed because the ExternalInterface has a bug that simply places the
		 * value a string in quotes (except for a " which is escaped) in a JavaScript string literal which
		 * is executed by the browser.  These often results in improperly escaped string literals if your
		 * input string has any backslash characters. For example the string:
		 * 		"c:\Program Files\uploadtools\"
		 * is placed in a string literal (with quotes escaped) and becomes:
		 * 		var __flash__temp = "\"c:\Program Files\uploadtools\\"";
		 * This statement will cause errors when executed by the JavaScript interpreter:
		 * 	1) The first \" is succesfully transformed to a "
		 *  2) \P is translated to P and the \ is lost
		 *  3) \u is interpreted as a unicode character and causes an error in IE
		 *  4) \\ is translated to \
		 *  5) leaving an unescaped " which causes an error
		 * 
		 * I fixed this by escaping \ characters in all outgoing strings.  The above escaped string becomes:
		 * 		var __flash__temp = "\"c:\\Program Files\\uploadtools\\\"";
		 * which contains the correct string literal.
		 * 
		 * Note: The "var __flash__temp = " portion of the example is part of the ExternalInterface not part of
		 * my escaping routine.
		 */
		private static function escapeMessage(message:*):* {
			if (message is String) {
				message = escapeString(message);
			}
			else if (message is Array) {
				message = escapeArray(message);
			}
			else if (message is Object) {
				message = escapeObject(message);
			}
			
			return message;
		}
		
		private static function escapeString(message:String):String {
			var replacePattern:RegExp = /\\/g; //new RegExp("/\\/", "g");
			return message.replace(replacePattern, "\\\\");
		}
		private static function escapeArray(message_array:Array):Array {
			var length:uint = message_array.length;
			var i:uint = 0;
			for (i; i < length; i++) {
				message_array[i] = escapeMessage(message_array[i]);
			}
			return message_array;
		}
		private static function escapeObject(message_obj:Object):Object {
			for (var name:String in message_obj) {
				message_obj[name] = escapeMessage(message_obj[name]);
			}
			return message_obj;
		}
	}
}
