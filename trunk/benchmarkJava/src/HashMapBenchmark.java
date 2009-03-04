/* Copyright 2008 Mike Slinn (mslinn@mslinn.com)
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

import j2as3.utility.*;
import java.text.NumberFormat;
import java.util.HashMap;

/** Test of Java 1.4 style collection performance.
 * Meant to mirror the ActionScript benchmark, not to be terribly useful. */
public class HashMapBenchmark {
    private StopWatch stopWatch = new StopWatch();
	private HashMap hashMap = new HashMap();
    private NumberFormat numberFormat = NumberFormat.getNumberInstance();

    /** Might be a better test if it read six to ten values */
    public void reads(int readCount) {
        hashMap.put("key", "value");
        stopWatch.startTimer();
        for (int i=0; i<readCount; i++)
            hashMap.get("key");
        stopWatch.reportElapsedTime(numberFormat.format(readCount) + " reads");
    }

    /** Might be a better test if it wrote six to ten values */
    public void writes(int writeCount) {
        stopWatch.startTimer();
        for (int i=0; i<writeCount; i++) {
            hashMap.put("key", new Integer(i).toString());
        }
        stopWatch.reportElapsedTime(numberFormat.format(writeCount) + " writes");
    }

    public static void main(String[] args) {
    	HashMapBenchmark benchmark = new HashMapBenchmark();
    	benchmark.reads(50000);
    	benchmark.writes(50000);
    }
}
