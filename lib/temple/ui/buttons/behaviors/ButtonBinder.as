/*
 *	 
 *	Temple Library for ActionScript 3.0
 *	Copyright © 2010 MediaMonks B.V.
 *	All rights reserved.
 *	
 *	http://code.google.com/p/templelibrary/
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

package temple.ui.buttons.behaviors 
{
	import temple.core.CoreObject;
	import temple.debug.errors.TempleArgumentError;
	import temple.debug.errors.throwError;
	import temple.destruction.DestructEvent;
	import temple.utils.types.ArrayUtils;

	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;

	/**
	 * The ButtonBinder binds to (or more) DisplayObjects together and pass their MouseEvents to eachother. 
	 * With the ButtonBinder you can set a TextField as a hitarea for a CheckBox
	 * 
	 * @author Thijs Broerse
	 */
	public class ButtonBinder extends CoreObject 
	{
		private static const _dictionary:Dictionary = new Dictionary(true);
		
		/**
		 * Returns a list of all ButtonBinders of a DisplayObject if the DisplayObject has ButtonBinders. Otherwise null is returned.
		 */
		public static function getInstances(target:DisplayObject):Array
		{
			return ButtonBinder._dictionary[target] as Array;
		}
		
		// List of Events to bind
		protected static const _EVENT_TYPES:Array = [	MouseEvent.CLICK,
												MouseEvent.DOUBLE_CLICK,
												MouseEvent.MOUSE_DOWN,
												MouseEvent.MOUSE_OUT,
												MouseEvent.MOUSE_OVER,
												MouseEvent.MOUSE_UP,
												MouseEvent.MOUSE_WHEEL,
												MouseEvent.ROLL_OUT,
												MouseEvent.ROLL_OVER];

		protected var _buttons:Dictionary;
		protected var _blockRequest:Boolean;
		
		/**
		 * Creates a new ButtonBinding
		 * @param button1 the first button to bind
		 * @param button2 the second button to bind
		 * @param weakReference indicates if weakReferences are used to bind the buttons
		 */
		public function ButtonBinder(button1:DisplayObject, button2:DisplayObject, useWeakReference:Boolean = true)
		{
			if(button1 == null) throwError(new TempleArgumentError(this, "button1 can not be null"));
			if(button2 == null) throwError(new TempleArgumentError(this, "button2 can not be null"));
			
			this._buttons = new Dictionary(useWeakReference);
			
			this.add(button1);
			this.add(button2);
		}
		
		/**
		 * Adds a new button to the binder. The 2 buttons in the constructor are automaticly added, so you do not need to call this method for those buttons
		 * @param button the button to add
		 * @param weakReference indicates if weakReference is used to bind the button
		 */
		public function add(button:DisplayObject, useWeakReference:Boolean = true):void
		{
			if (button == null) throwError(new TempleArgumentError(this, "Button can not be null"));
			
			if(ButtonBinder._dictionary[button] == null) ButtonBinder._dictionary[button] = new Array();
			(ButtonBinder._dictionary[button] as Array).push(this);
			
			this._buttons[button] = this;
			
			for each (var type : String in ButtonBinder._EVENT_TYPES) 
			{
				button.addEventListener(type, this.handleEvent, false, 0, useWeakReference);
			}
			button.addEventListener(DestructEvent.DESTRUCT, this.handleButtonDestructed, false, 0, useWeakReference);
		}
		
		/**
		 * Removes a button from the ButtonBinder
		 * @param button the button to be removed
		 */
		public function remove(button:DisplayObject):void
		{
			if (button == null) throwError(new TempleArgumentError(this, "Button can not be null"));
			
			button.removeEventListener(DestructEvent.DESTRUCT, this.handleButtonDestructed);
			
			if(ButtonBinder._dictionary && ButtonBinder._dictionary[button])
			{
				ArrayUtils.removeValueFromArray(ButtonBinder._dictionary[button], this);
			}
			
			if (this._buttons && this._buttons[button])
			{
				for each (var type : String in ButtonBinder._EVENT_TYPES) 
				{
					button.removeEventListener(type, this.handleEvent);
				}
				delete this._buttons[button];
			}
			else
			{
				this.logWarn("remove: ButtonBinder has no button '" + button + "'");
			}
		}

		protected function handleEvent(event:Event):void
		{
			if (this._blockRequest) return;
			this._blockRequest = true;
			
			for (var button:Object in this._buttons)
			{
				if (button != event.target) (button as DisplayObject).dispatchEvent(event.clone());
			}
			this._blockRequest = false;
		}
		
		protected function handleButtonDestructed(event:DestructEvent):void
		{
			this.remove(event.target as DisplayObject);
		}

		/**
		 * @inheritDoc
		 */
		override public function destruct():void
		{
			if (this._buttons)
			{
				for (var button:Object in this._buttons)
				{
					this.remove(button as DisplayObject);
				}
				this._buttons = null;
			}
			super.destruct();
		}
	}
}