/*
 *	Temple Library for ActionScript 3.0
 *	Copyright © MediaMonks B.V.
 *	All rights reserved.
 *	
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are met:
 *	1. Redistributions of source code must retain the above copyright
 *	   notice, this list of conditions and the following disclaimer.
 *	2. Redistributions in binary form must reproduce the above copyright
 *	   notice, this list of conditions and the following disclaimer in the
 *	   documentation and/or other materials provided with the distribution.
 *	3. All advertising materials mentioning features or use of this software
 *	   must display the following acknowledgement:
 *	   This product includes software developed by MediaMonks B.V.
 *	4. Neither the name of MediaMonks B.V. nor the
 *	   names of its contributors may be used to endorse or promote products
 *	   derived from this software without specific prior written permission.
 *	
 *	THIS SOFTWARE IS PROVIDED BY MEDIAMONKS B.V. ''AS IS'' AND ANY
 *	EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *	DISCLAIMED. IN NO EVENT SHALL MEDIAMONKS B.V. BE LIABLE FOR ANY
 *	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 *	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *	
 *	
 *	Note: This license does not apply to 3rd party classes inside the Temple
 *	repository with their own license!
 */

package temple.core.debug.log 
{
	import flash.events.Event;
	import temple.core.events.CoreEvent;
	import temple.core.templelibrary;

	/**
	 * Event dispatched by the <code>Log</code> class when someting is logged. You can listen for this Event if you want
	 * to create your own Logger.
	 * 
	 * @see temple.core.debug.log.Log
	 * 
	 * @author Thijs Broerse
	 */
	public class LogEvent extends CoreEvent 
	{
		/**
		 * The current version of the Temple Library
		 */
		templelibrary static const VERSION:String = "3.6.0";
		
		/**
		 * Event type
		 */
		public static const EVENT:String = "LogEvent.Event";
		
		private var _level:String;
		private var _data:*;
		private var _sender:String;
		private var _senderId:uint;
		private var _stackTrace:String;
		private var _time:uint;
		private var _frame:uint;

		/**
		 * Creates a new LogEvent.
		 * @param level the level of the LogEvent.
		 * @param data data send with the Log message
		 * @param sender the 'toString' of the object that send the log message
		 * @param senderId the object id of the sender. The id is generated by the Registry.
		 */
		public function LogEvent(level:String, data:*, sender:String, senderId:uint, stackTrace:String = null, time:uint = 0, frame:uint = 0) 
		{
			super(LogEvent.EVENT);
			
			_level = level;
			_data = data;
			_sender = sender;
			_senderId = senderId;
			_stackTrace = stackTrace;
			_time = time;
			_frame = frame;
			
			toStringProps.length = 0;
			toStringProps.push('level', 'data', 'sender', 'objectId');
		}

		/**
		 * Returns the level of the Event.
		 * @see temple.core.debug.log.LogLevel
		 */
		public function get level():String
		{
			return _level;
		}
		
		/**
		 * The data send with the Log message
		 */
		public function get data():*
		{
			return _data;
		}
		
		/**
		 * The 'toString' of the object that send the log message
		 */
		public function get sender():String
		{
			return _sender;
		}
		
		/**
		 * The id of the object that send the log message. The id is generated by the Registry.
		 * With the id you can get the object at the Registry
		 * @see temple.core.debug.Registry#getObject()
		 */
		public function get objectId():uint
		{
			return _senderId;
		}
		
		/**
		 * The stack trace of the Log. To find the place where the message was logged.
		 * Only available if in debug players and if the this option is enabled in the Log.
		 */
		public function get stackTrace():String
		{
			return _stackTrace;
		}
		
		/**
		 * The total amount of milliseconds has passed since the application started.
		 */
		public function get time():uint
		{
			return _time;
		}
		
		/**
		 * The total amount of frames has passed since the application started.
		 */
		public function get frame():uint
		{
			return _frame;
		}
		
		/**
		 * Creates a copy of an existing LogEvent.
		 */
		override public function clone():Event 
		{
			return new LogEvent(_level, _data, _sender, _senderId, _stackTrace, _frame);
		}
	}
}
