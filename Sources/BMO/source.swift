/*
 * source.swift
 * BMO
 *
 * Created by François Lamboley on 1/8/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public func doStuff() {
	if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
		/* Can do this stuff only on specific platform versions */
	}
	print("Hello world!")
}
