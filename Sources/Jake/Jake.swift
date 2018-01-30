/*
 * Jake.swift
 * BMO
 *
 * Created by François Lamboley on 1/29/18.
 * Copyright © 2018 happn. All rights reserved.
 */

/* A test to write an umbrella Framework to avoid importing all these each time
 * one wants to use BMO with REST and CoreData. Does not seem to work (at least
 * not in Xcode, not tested with anything else). */

@_exported import BMO
@_exported import RESTUtils
@_exported import BMO_FastImportRepresentation
@_exported import BMO_CoreData
@_exported import BMO_RESTCoreData
