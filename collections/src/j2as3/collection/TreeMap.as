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
    
    [Bindable] public dynamic class TreeMap extends HashMap {
        
        override public function get keys():ArrayCollection {
            super.keys.source.sort();
            return super.keys;
        }
         
        override public function set keys(ignored:ArrayCollection):void { }
        
        override public function toString():String {
            var str:String = "TreeMap with " + count + " entries; ";
            var array:Array = new Array();
            for (var key:String in this)
                array.push(key);
            array.sort();    
            for (var key2:String in array)
                str += "\n   " + key2 + ": " + this[key2];
            return str;
        }
        
        /** Return a sorted list of values (which do not correspond to the sorted list of keys) 
        * because the sort orderings don't match */
        override public function values():ArrayCollection {
            var values:ArrayCollection = new ArrayCollection();
            for (var index:String in keys.source) {
                var i:int = int(index);
                var key:String = keys[i];
                values.addItem(this[key]);
            }
            return values;
        }
    }
}