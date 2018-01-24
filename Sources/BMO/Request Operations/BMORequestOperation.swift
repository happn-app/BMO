/*
 * BMORequestOperation.swift
 * BMO
 *
 * Created by François Lamboley on 1/30/17.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation

import AsyncOperationResult



public enum BMOError : Error {
	
	/** BMO operations results are set to this error before being set to the
	actual operation result (when the operation ends) */
	case notFinished
	
	case cancelled
	
}
