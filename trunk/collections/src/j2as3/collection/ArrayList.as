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

    public class ArrayList extends ArrayCollection {
        
        public function add(item:Object):ArrayList { 
            addItem(item);
            return this;
        }
        
        public function clear():ArrayList { 
            removeAll();
            return this;
        }
        
        /*public function clone():ArrayList {
            var clone:ArrayList = new ArrayList();
            for (var key:Object in this)
                clone.add(this[key]);
            return clone;
        }*/
        
        public function isEmpty():Boolean { return length==0; }
        
        public function remove(item:Object):ArrayList {
            var i:int = getItemIndex(item);
            if (i>=0)
                removeItemAt(i);
            return this;
        }
    }
}