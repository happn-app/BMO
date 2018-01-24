/*
 * NumberOfCores.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

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
