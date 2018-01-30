/*
 * OperationError.swift
 * BMO
 *
 * Created by François Lamboley on 1/24/18.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



public enum OperationError : Swift.Error {
	
	/** BMO operations results are set to this error before being set to the
	actual operation result (when the operation ends) */
	case notFinished
	
	case cancelled
	
}
