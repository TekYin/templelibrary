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
 *	
 *	Note: This license does not apply to 3rd party classes inside the Temple
 *	repository with their own license!
 *	
 */

package temple.debug 
{
	import temple.debug.log.Log;
	import temple.Temple;
	import temple.core.CoreObject;
	import temple.debug.errors.TempleArgumentError;
	import temple.debug.errors.TempleError;
	import temple.debug.errors.throwError;
	import temple.utils.BuildMode;
	import temple.utils.Environment;
	import temple.utils.StageProvider;
	import temple.utils.types.DateUtils;

	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.utils.Dictionary;

	/**
	 * This class is used to manage objects that can be debugged.
	 * <p>Object(-trees) can be added so they can be listed and managed by external tools.</p>
	 * <p>There also is a global setting to apply debugging to all added objects.</p>
	 * 
	 * @example
	 * <listing version="3.0">
	 * // open the file in the browser:
	 * // http://domain.com/index.html?debug=true
	 * 
	 * // add IDebuggable objects:
	 * DebugManager.add(this);
	 * // add IDebugable children:
	 * if (button is IDebuggable) DebugManager.addAsChild(button as IDebuggable, this);
	 * // debugging for this added objects are set to the value in the URL
	 * 
	 * // change the debugging value for an object:
	 * DebugManager.setDebugfor (12, false);
	 * 
	 * // set debugging globally ON
	 * DebugManager.debugMode = DebugManager.ALL;
	 * </listing>
	 * 
	 * @author Arjan van Wijk, Thijs Broerse
	 */
	public final class DebugManager extends CoreObject implements IDebuggable
	{
		private static var _instance:DebugManager;
		private static var _debugMode:String;

		// pool of debuggables with there Registry-id
		private var _debuggables:Dictionary;
		
		// pool of debuggable children with there parent Registry-id for quick lookup
		private var _debuggableChildren:Dictionary;
		
		// array of parentId's with there childId's
		private var _debuggableChildList:Array;
		
		// pool of debuggable children with there parent Registry-id for quick lookup
		private var _debuggableChildQueue:Dictionary;
		
		private static var _debug:Boolean = false;

		public function DebugManager() 
		{
			if (DebugManager._instance) throwError(new TempleError(this, "Singleton, use DebugManager.getInstance()"));
			
			this._debuggables = new Dictionary(true);
			this._debuggableChildren = new Dictionary(true);
			this._debuggableChildList = new Array();
			this._debuggableChildQueue = new Dictionary(true);
		}
		
		public static function getInstance():DebugManager
		{
			if (DebugManager._instance == null)
			{
				DebugManager._instance = new DebugManager();
				DebugManager.add(DebugManager._instance);
			}
			return DebugManager._instance;
		}
		
		/**
		 * Adds a IDebuggable object so it can be controlled by the DebugManager
		 * @param object The IDebuggable object to add
		 */
		public static function add(object:IDebuggable):void
		{
			if (DebugManager._debug) DebugManager.getInstance().logDebug("add: " + object);
			
			// check via javascript if debug is set in the url
			if (!DebugManager._debugMode && ExternalInterface.available)
			{
				try
				{
					var debugMode:String = ExternalInterface.call('function(){var arrParams = document.location.href.toString().split("?").pop().split("#").shift().split("&");var objParams = new Object();for (var i = 0; i < arrParams.length; ++i){var arrParam = arrParams[i].split("=");objParams[arrParam[0]] = arrParam[1];}return objParams["debug"];}');
					if (DebugManager.debug) DebugManager.getInstance().logInfo("debugMode from query string: '" + debugMode + "' (url='" + ExternalInterface.call('function(){ return document.location.href; }') + "')");
					if (debugMode) DebugManager.debugMode = debugMode; 
				}
				catch (e:SecurityError)
				{
					DebugManager.getInstance().logWarn("application is running in sandbox, or isn't running in a browser at all");
				}
			}
			
			// if no debugsetting in url, set to default
			if (!DebugManager._debugMode)
			{
				DebugManager.debugMode = Temple.defaultDebugMode;
			}
			
			var objectId:uint = Registry.getId(object);
			if (objectId == 0)
			{
				// If not in Registry, add it there
				objectId = Registry.add(object);
			}
			
			// store the object with their id
			DebugManager.getInstance()._debuggables[object] = objectId;
			
			// if _debugMode is set to ALL or NONE, apply it to the added object
			if (DebugManager._debugMode != DebugMode.CUSTOM) object.debug = (DebugManager._debugMode == DebugMode.ALL);
		}

		/**
		 * Add a IDebuggable object as child of a Debuggable 'group'
		 * <p>This function is only called in objects added with DebugManager.add(this);</p>
		 * <p>Using this construction a tree of Debuggables is created</p>
		 * <p>When the 'debug'-property of the parent is set via the DebugManager,
		 * the debugging for all children is also set to the same value</p>
		 * @param object The IDebuggable object to add
		 * @param parent The parent of the object (like a Form of an InputField)
		 * @example
		 * <listing version="3.0">
		 * if (button is IDebuggable) DebugManager.addAsChild(button as IDebuggable, this);
		 * </listing>
		 */
		public static function addAsChild(object:IDebuggable, parent:IDebuggable):void
		{
			if (DebugManager._debug) DebugManager.getInstance().logDebug("addAsChild: " + object + " (parent=" + parent + ")");
			
			var parentId:uint = Registry.getId(parent);
			var objectId:uint = Registry.getId(object);
			
			// if parent is not a debuggable
			if (!DebugManager.getInstance()._debuggables[parent])
			{
				// check if parent is a child itself
				if (DebugManager.getInstance()._debuggableChildren[parent])
				{
					// find parent recursively
					DebugManager.addAsChild(object, Registry.getObject(DebugManager.getInstance()._debuggableChildren[parent]));
				}
				else
				{
					// parent is not found, place in queue
					DebugManager.getInstance()._debuggableChildQueue[object] = parentId;
					
					// if no child for parent is added yet, create the array
					if (!DebugManager.getInstance()._debuggableChildList[parentId])
					{
						DebugManager.getInstance()._debuggableChildList[parentId] = new Array();
					}
					// add child in parent-array
					(DebugManager.getInstance()._debuggableChildList[parentId] as Array).push(objectId);
				}
			}
			else
			{
				// if no child for parent is added yet, create the array
				if (!DebugManager.getInstance()._debuggableChildList[parentId])
				{
					DebugManager.getInstance()._debuggableChildList[parentId] = new Array();
				}
				// add child in parent-array
				(DebugManager.getInstance()._debuggableChildList[parentId] as Array).push(objectId);
				
				// add child with its parentid
				// for quick lookup
				DebugManager.getInstance()._debuggableChildren[object] = parentId;
				
				object.debug = parent.debug;	
				
				
				// check for children in the queue
				for (var i:* in DebugManager.getInstance()._debuggableChildQueue)
				{
					// if parentid in list is equal to this objectid
					if (DebugManager.getInstance()._debuggableChildQueue[i] == objectId)
					{
						// add child in list to this object as parent
						//DebugManager.addAsChild(i as IDebuggable, Registry.getObject(DebugManager._INSTANCE._debuggableChildQueue[i]));
						
						// add child with its parentid
						// for quick lookup
						DebugManager.getInstance()._debuggableChildren[i as IDebuggable] = DebugManager.getInstance()._debuggableChildQueue[i];
						
						object.debug = parent.debug;	
						
						DebugManager.getInstance()._debuggableChildQueue[i] = null;
					}
				}
			}
		}

		/**
		 * Get a list of IDebuggable objects
		 * @return A list of IDebuggable objects as {object as String, children as Array, debug as Boolean, id as uint}
		 */
		public static function getDebuggables():Array
		{
			if (DebugManager._debug) DebugManager.getInstance().logDebug("getDebuggables");
			
			var list:Array = new Array();
			
			for (var object:* in DebugManager.getInstance()._debuggables)
			{
				list.push(new DebuggableData(String(String(object).split('::').pop()).split(',').shift(), getDebuggableChildren(DebugManager.getInstance()._debuggables[object]), IDebuggable(object).debug, DebugManager.getInstance()._debuggables[object]));
				
			}
			
			list.sortOn('id');
			
			return list;
		}
		
		/**
		 * Get a list of IDebuggable children from the IDebuggable objectsId
		 * @return A list of IDebuggable children as {object as String, children as Array, debug as Boolean, id as uint}
		 */
		private static function getDebuggableChildren(objectId:int):Array
		{
			var children:Array = getChildsOf(objectId);
			
			if (!children) return new Array();
			
			for (var i:int = 0; i < children.length; ++i)
			{
				var object:IDebuggable = Registry.getObject(children[i]);
				
				children[i] = new DebuggableData(String(String(object).split('::').pop()).split(',').shift(), getDebuggableChildren(children[i]), IDebuggable(object).debug, children[i]);
			}
			
			return children;
		}
		
		/**
		 * Gets a list of IDebuggable objects as XML
		 * This function uses getDebuggables for its data
		 */
		public static function getDebuggablesAsXml():XML
		{
			var xml:XML = new XML(<root></root>);
			
			var debuggables:Array = DebugManager.getDebuggables();
			
			var debuggableData:DebuggableData;
			var object:String;
			var children:String;
			var debug:String;
			var id:String;
			var label:String;
			
			for (var i:int = 0; i < debuggables.length; ++i)
			{
				debuggableData = debuggables[i] as DebuggableData;
				
				object = debuggableData.object;
				children = debuggableData.children.join(',');
				debug = debuggableData.debug ? 'true' : 'false';
				id = String(debuggableData.id);
				label =  id + ' | ' + object;
				
				var node:XML = <node object={object} children={children} debug={debug} id={id} label={label} usedebug="true" icon="iconFolder" />;
				
				var childNodes:XMLList = getDebuggableChildsAsXml(debuggableData.id);
				
				for (var j:int = 0; j < childNodes.length(); ++j)
				{
					node.appendChild(childNodes[j]);
				}
				
				xml.appendChild(node);
			}
			
			return xml;
		}
		
		/**
		 * Gets a list of IDebuggable children as XML. 
		 * This function uses getDebuggableChilds for its data
		 */
		private static function getDebuggableChildsAsXml(objectId:int):XMLList
		{
			var xml:XML = new XML(<root></root>);
			
			var debuggableData:DebuggableData;
			var object:String;
			var children:String;
			var id:String;
			var label:String;
			
			var debuggableChilds:Array = DebugManager.getDebuggableChildren(objectId);
			
			for (var i:int = 0; i < debuggableChilds.length; ++i)
			{
				debuggableData = debuggableChilds[i] as DebuggableData;
				object = debuggableData.object;
				children = debuggableData.children.join(',');
				id = String(debuggableData.id);
				label =  id + ' | ' + object;
				
				var node:XML = <node object={object} children={children} id={id} usedebug="false" label={label} />;
				
				var childNodes:XMLList = getDebuggableChildsAsXml(debuggableData.id);
				
				for (var j:int = 0; j < childNodes.length(); ++j)
				{
					node.appendChild(childNodes[j]);
				}
				
				xml.appendChild(node);
			}
			
			return xml.child('node');
		}
			
		/**
		 * Get a list of child id's of an IDebuggable object
		 * @param id The objectId of an IDebuggable object
		 * @return A list of child id's
		 */
		private static function getChildsOf(id:uint):Array
		{
			return DebugManager.getInstance()._debuggableChildList[id] ? (DebugManager.getInstance()._debuggableChildList[id] as Array).concat() : null;
		}

		/**
		 * Set the debug flag for an object by id
		 * @param id The id of the Debuggable object
		 * @param value The debug value
		 */
		public static function setDebugfor (objectId:uint, value:Boolean):void
		{
			var object:* = Registry.getObject(objectId);
			if (object && object is IDebuggable) IDebuggable(object).debug = value;
		}
		
		/**
		 * Set the debug flag for the children of an object.
		 * <p>This function will be called from an IDebuggable 'parent' in the 'set debug' most of the time, to updated it's children.</p>
		 * @param parentObjectId The id of the Debuggable parent object
		 * @param value The debug value
		 */
		public static function setDebugForChilds(parentObject:IDebuggable, value:Boolean):void
		{
			var children:Array = getChildsOf(Registry.getId(parentObject));
			
			if (!children) return;
			
			for (var i:int = 0; i < children.length; ++i)
			{
				var child:IDebuggable = Registry.getObject(children[i]) as IDebuggable;
				if (child) child.debug = value;
			}
		}
		
		
		/**
		 * <p>Enable debugging for all objects</p>
		 *	The debugMode can be set to:
		 *	<ul>
		 * 	<li>DebugManager.NONE: debug nothing</li>
		 * 	<li>DebugManager.CUSTOM: let the user decide what to debug</li>
		 * 	<li>DebugManager.ALL: debug everything</li>
		 * 	</ul>
		 */
		public static function set debugMode(value:String):void
		{
			switch (value)
			{
				case DebugMode.NONE:
				case DebugMode.CUSTOM:
				case DebugMode.ALL:
				{
					DebugManager._debugMode = value;
					break;
				}
				default:
				{
					throwError(new TempleArgumentError(DebugManager, "Invalid value for debugMode: " + value));
					break;
				}
			}
			if (DebugManager._debugMode != DebugMode.CUSTOM)
			{
				var debug:Boolean = (DebugManager._debugMode == DebugMode.ALL);
				
				if (debug) DebugManager.logInfo();
				
				for (var object:* in DebugManager.getInstance()._debuggables)
				{
					IDebuggable(object).debug = debug;
				}
			}
		}
		
		/**
		 * @private
		 */
		public static function get debugMode():String
		{
			return DebugManager._debugMode;
		}
		
		
		/**
		 *	Wrapper for DebugManager.getInstance().debug
		 */
		public static function get debug():Boolean
		{
			return DebugManager._debug;
		}
		
		/**
		 * @private
		 */
		public static function set debug(value:Boolean):void
		{
			if (value != DebugManager._debug)
			{
				DebugManager._debug = value;
				DebugManager.getInstance().logDebug("debug " + (DebugManager._debug ? "enabled" : "disabled"));
			}
		}

		/**
		 *	For the DebugManager itself
		 *	
		 *	@inheritDoc 
		 */
		public function get debug():Boolean
		{
			return DebugManager._debug;
		}
		
		/**
		 * @inheritDoc
		 */
		public function set debug(value:Boolean):void
		{
			DebugManager._debug = value;
		}
		
		/**
		 * Logs some debug info, like Temple version and current date
		 */
		public static function logInfo():String 
		{
			var info:String = "Debug info:";
			
			info += "\n\tTemple version: " + Temple.VERSION;
			info += "\n\tTemple date: " + Temple.DATE;
			info += "\n\tCurrent date: " + DateUtils.format("Y-m-d");
			info += "\n\tPlayer version: " + Capabilities.version;
			info += "\n\tEnvironment: " + Environment.getEnvironment();
			info += "\n\tOperation System: " + Capabilities.os;
			info += "\n\tManufacturer: " + Capabilities.manufacturer;
			info += "\n\tisDebugger: " + Capabilities.isDebugger;
			info += "\n\tBuildMode: " + (BuildMode.isDebugBuild() ? "debug" : "release");
			info += "\n\tDebugMode: " + DebugManager.debugMode;
			if (StageProvider.stage)
			{
				info += "\n\tURL: " + StageProvider.stage.loaderInfo.url;
			}
			Log.debug(info, DebugManager);
			
			return info;
		}

		/**
		 * @inheritDoc
		 */
		override public function destruct():void
		{
			DebugManager._instance = null;
			this._debuggables = null;
			this._debuggableChildren = null;
			this._debuggableChildList = null;
			this._debuggableChildQueue = null;
			
			super.destruct();
		}

		public static function toString():String 
		{
			return getClassName(DebugManager);
		}
	}
}

class DebuggableData
{
	public var object:String;
	public var children:Array;
	public var debug:Boolean;
	public var id:uint;
	
	public function DebuggableData(object:String, children:Array, debug:Boolean, id:uint)
	{
		this.object = object;
		this.children = children;
		this.debug = debug;
		this.id = id;
	}
}