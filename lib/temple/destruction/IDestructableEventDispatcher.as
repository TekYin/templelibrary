/*
 *	 
 *	Temple Library for ActionScript 3.0
 *	Copyright © 2009 MediaMonks B.V.
 *	All rights reserved.
 *	
 *	THIS LIBRARY IS IN PRIVATE BETA, THEREFORE THE SOURCES MAY NOT BE
 *	REDISTRIBUTED IN ANY WAY.
 *	
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are met:
 *	
 *	- Redistributions of source code must retain the above copyright notice,
 *	this list of conditions and the following disclaimer.
 *	
 *	- Redistributions in binary form must reproduce the above copyright notice,
 *	this list of conditions and the following disclaimer in the documentation
 *	and/or other materials provided with the distribution.
 *	
 *	- Neither the name of the Temple Library nor the names of its contributors
 *	may be used to endorse or promote products derived from this software
 *	without specific prior written permission.
 *	
 *	
 *	Temple Library is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU Lesser General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *	
 *	Temple Library is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU Lesser General Public License for more details.
 *	
 *	You should have received a copy of the GNU Lesser General Public License
 *	along with Temple Library.  If not, see <http://www.gnu.org/licenses/>.
 *	
 */

package temple.destruction 
{
	import flash.events.IEventDispatcher;
	
	/**
	 * Dispatched just before the object is destructed
	 * @eventType temple.destruction.DestructEvent.DESTRUCT
	 */
	[Event(name = "DestructEvent.destruct", type = "temple.destruction.DestructEvent")]

	/**
	 * IDestructableEventDispatcher will automatic removed all listeners on the object when it is destructed.
	 */
	public interface IDestructableEventDispatcher extends IEventDispatcher, IDestructable 
	{

		/**
		 * Removes all events of a specific type.
		 * 	
		 * @param type The type of event.
		 */
		function removeAllEventsForType(type:String):void;

		/**
		 * Removes all events that are handled by a specified listener.
		 * 	
		 * @param listener The listener function that processes the event.
		 */
		function removeAllEventsForListener(listener:Function):void;

		/**
		 * Removes all event listeners.
		 */
		function removeAllEventListeners():void;

		/**
		 * Returns a reference to the EventListenerManager of the IDestructableEventDispatcher
		 */
		function get eventListenerManager():EventListenerManager;
	}
}