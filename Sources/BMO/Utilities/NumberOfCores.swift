/*
Copyright 2019 happn

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation
import os.log



var numberOfCores: Int? = {
	guard MemoryLayout<Int32>.size <= MemoryLayout<Int>.size else {
		if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {di.log.flatMap{ os_log("Int32 is bigger than Int (%d > %d). Cannot return the number of cores.", log: $0, type: .info, MemoryLayout<Int32>.size, MemoryLayout<Int>.size) }}
		else                                                          {NSLog("Int32 is bigger than Int (%d > %d). Cannot return the number of cores.", MemoryLayout<Int32>.size, MemoryLayout<Int>.size)}
		return nil
	}
	
	var ncpu: Int32 = 0
	var len = MemoryLayout.size(ofValue: ncpu)
	
	var mib = [CTL_HW, HW_NCPU]
	let namelen = u_int(mib.count)
	
	guard sysctl(&mib, namelen, &ncpu, &len, nil, 0) == 0 else {return nil}
	return Int(ncpu)
}()
