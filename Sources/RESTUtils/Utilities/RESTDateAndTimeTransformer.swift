/*
 * RESTDateAndTimeTransformer.swift
 * BMO
 *
 * Created by François Lamboley on 29/05/2018.
 * Copyright © 2018 happn. All rights reserved.
 */

import Foundation



/** Transforms an object to a Date and vice-versa with a set of options to
customize how the conversion is attempted.

For the reverse transformation, depending on the options, the reversed value can
either be a `String` or an `NSNumber`. */
public final class RESTDateAndTimeTransformer : ValueTransformer {
	
	public enum DateConversionFormats {
		
		public enum NumericTimestampStyle {
			
			case posix /* From the epoch (1 January 1970) */
			case modern /* From the epoch (1 January 2001) */
			case custom(Date)
			
		}
		
		case numericTimestamp(style: NumericTimestampStyle)
		
		/** Useful for parsing birthdates for instance; expect a date with format
		yyyy-MM-dd. If match, will return the given date at 0:00 GMT. */
		case dateNoTime(locale: Locale?)
		
		/** If you want to mix dateNoTime and iso8601, put dateNoTime as iso8601
		will parse dateNoTime successfully, but with a (probably) wrong timezone. */
		@available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *)
		case iso8601(options: ISO8601DateFormatter.Options, timezone: TimeZone?)
		
		/** If you target a platform where the system ISO8601DateFormatter is not
		available, use this format. Under the hood, uses a DateFormatter with
		format "yyyy-MM-dd'T'HH:mm:ssZZZZZ" (with en_US_POSIX locale). */
		@available(OSX, obsoleted: 10.12, message: "Use iso8601 to get a real ISO8601 date formatter.")
		@available(tvOS, obsoleted: 10.0, message: "Use iso8601 to get a real ISO8601 date formatter.")
		@available(iOS, obsoleted: 10.0, message: "Use iso8601 to get a real ISO8601 date formatter.")
		@available(watchOS, obsoleted: 3.0, message: "Use iso8601 to get a real ISO8601 date formatter.")
		case fakeISO8601(timezone: TimeZone?)
		
		/** A DateFormatter with the given custom format. */
		case custom(formatter: DateFormatter)
		
	}
	
	/** Try and convert the given object with the given formats. Try the
	conversions in the order given for the formats. */
	public static func convertObjectToDate(_ obj: Any?, dateConversionFormats: [DateConversionFormats]) -> Date? {
		if let date = obj as? Date {return date}
		
		let strObj = obj as? String
		let numObj = RESTNumericTransformer.convertObjectToDouble(obj)
		
		for format in dateConversionFormats {
			switch format {
			case .numericTimestamp(style: let style):
				guard let numObj = numObj else {continue}
				switch style {
				case .posix:            return Date(timeIntervalSince1970:          numObj)
				case .modern:           return Date(timeIntervalSinceReferenceDate: numObj)
				case .custom(let date): return Date(timeInterval:                   numObj, since: date)
				}
				
			case .dateNoTime(let locale):
				guard let strObj = strObj else {continue}
				let dateFormatter = DateFormatter()
				dateFormatter.locale = locale
				dateFormatter.dateFormat = "yyyy-MM-dd"
				dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
				if let date = dateFormatter.date(from: strObj) {return date}
				
			case .iso8601(options: let options, timezone: let timeZone):
				guard #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) else {continue}
				guard let strObj = strObj else {continue}
				let isoDateFormatter = ISO8601DateFormatter()
				isoDateFormatter.formatOptions = options
				isoDateFormatter.timeZone = timeZone
				if let date = isoDateFormatter.date(from: strObj) {return date}
				
			case .fakeISO8601(let timezone):
				guard let strObj = strObj else {continue}
				let dateFormatter = DateFormatter()
				dateFormatter.timeZone = timezone
				dateFormatter.locale = Locale(identifier: "en_US_POSIX")
				dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
				if let date = dateFormatter.date(from: strObj) {return date}
				
			case .custom(formatter: let dateFormatter):
				guard let strObj = strObj else {continue}
				if let date = dateFormatter.date(from: strObj) {return date}
			}
		}
		
		return nil
	}
	
	override public class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	override public class func transformedValueClass() -> AnyClass {
		return NSDate.self
	}
	
	public let forwardConversionDateFormats: [DateConversionFormats]
	public let reverseConversionDateFormat: DateConversionFormats
	
	public convenience override init() {
		if #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) {
			let iso8601Formatter = DateConversionFormats.iso8601(options: [.withFullDate, .withFullTime], timezone: nil)
			self.init(forwardConversionDateFormats: [iso8601Formatter], reverseConversionDateFormat: iso8601Formatter)
		} else {
			let iso8601Formatter = DateConversionFormats.fakeISO8601(timezone: nil)
			self.init(forwardConversionDateFormats: [iso8601Formatter], reverseConversionDateFormat: iso8601Formatter)
		}
	}
	
	public init(forwardConversionDateFormats f: [DateConversionFormats], reverseConversionDateFormat r: DateConversionFormats) {
		reverseConversionDateFormat = r
		forwardConversionDateFormats = f
	}
	
	override public func transformedValue(_ value: Any?) -> Any? {
		return RESTDateAndTimeTransformer.convertObjectToDate(value, dateConversionFormats: forwardConversionDateFormats)
	}
	
	override public func reverseTransformedValue(_ value: Any?) -> Any? {
		guard let date = value as? Date else {return nil}
		
		switch reverseConversionDateFormat {
		case .numericTimestamp(style: let style):
			switch style {
			case .posix:            return date.timeIntervalSince1970
			case .modern:           return date.timeIntervalSinceReferenceDate
			case .custom(let date): return date.timeIntervalSince(date)
			}
			
		case .dateNoTime(let locale):
			let dateFormatter = DateFormatter()
			dateFormatter.locale = locale
			dateFormatter.dateFormat = "yyyy-MM-dd"
			dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
			return dateFormatter.string(from: date)
			
		case .iso8601(options: let options, timezone: let timeZone):
			guard #available(OSX 10.12, tvOS 10.0, iOS 10.0, watchOS 3.0, *) else {return nil}
			let isoDateFormatter = ISO8601DateFormatter()
			isoDateFormatter.formatOptions = options
			isoDateFormatter.timeZone = timeZone
			return isoDateFormatter.string(from: date)
			
		case .fakeISO8601(let timezone):
			let dateFormatter = DateFormatter()
			dateFormatter.timeZone = timezone
			dateFormatter.locale = Locale(identifier: "en_US_POSIX")
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
			return dateFormatter.string(from: date)
			
		case .custom(formatter: let dateFormatter):
			return dateFormatter.string(from: date)
		}
	}
	
}
