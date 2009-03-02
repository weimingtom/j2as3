/* Mimics the behavior of the Java 1.4 Collection class of the same name.
 *
 * Copyright 2008 Mike Slinn (mslinn@mslinn.com)
 * 
 * Mike Slinn licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * $Id$ */

package j2as3.collection {
    import mx.collections.ArrayCollection;
    
    
    [Bindable] public dynamic class HashMap extends Object {
        protected var count:int = 0;
        
        public function clear():Object {
            for (var key:String in this)
                this[key] = null;
            count = 0;
            return this;
        }
        
        /*public function clone():HashMap {
            var clone:HashMap = new HashMap();
            for (var key:String in this)
                clone[key] = this[key];
            return clone;
        }*/
        
        /** 'get' is an ActionScript reserved word */
        public function getIndex(index:int):* {
            var i:int = 0;
            for (var key:String in this) {
                if (i++==index)
                    return this[key];
            }
            return null; 
        }
        
        /** ActionScript cannot overload functions so a unique function name was chosen */
        public function getItem(key:String):* { 
            if (hasOwnProperty(key))
                return this[key];
            return null; 
        }
        
        public function get keys():ArrayCollection { 
            var keys:ArrayCollection = new ArrayCollection();
            for (var key:String in this)
                keys.addItem(key);
            return keys;
        }
        
        private var bogusData:ArrayCollection;
        
        public function set keys(ignored:ArrayCollection):void { }
        
        public function put(key:String, value:Object):void { 
            this[key] = value; 
            count++;
            keys = bogusData;
        }
        
        public function putAll(map:HashMap):void {
        	for (var key:String in map)
                put(key, map.getItem(key)); 
        }
        
        public function remove(key:String):Object {
            delete this[key];
            count--;
            return this;
        }
        
        public function size():int { return count; }
        
        public function toString():String {
            var str:String = "HashMap with " + count + " entries; ";
            for (var key:String in this)
                str += "\n   " + key + ": " + this[key];
            return str;
        }
        
        public function values():ArrayCollection {
            var values:ArrayCollection = new ArrayCollection();
            for (var key:String in this)
                values.addItem(this[key]);
            return values;
        }
    }
}