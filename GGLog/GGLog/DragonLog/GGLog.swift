//
//  GGLog.swift
//  GGLog
//
//  Created by George Green on 31/05/2015.
//  Copyright (c) 2015 George Green. All rights reserved.
//

import Foundation

/// The default global logging instance.
public let GGLogger = _GGLogger()

public class _GGLogger {
	
	// MARK: - Private Instance Variables
	
	private var stdOutFileHandle = NSFileHandle.fileHandleWithStandardOutput()
	private var stdErrFileHandle = NSFileHandle.fileHandleWithStandardError()
	private var disabledTags = Set<String>()
	private var soloTags: [String]? = nil
	
	// MARK: - Public Instance Variables
	
	/// The tag to be used when using the most simple logging method
	/// Change this to change the tag used when logging, or use this
	/// to enable/disable the default logs.
	public var defaultLogTag = "GGLog"
	/// The tag to be used when using the most simple error logging
	/// method. Change this to change the tag used when error logging,
	/// or use this to enable/disable the default logs.
	public var defaultErrLogTag = "GGLogErr"
	
	// MARK: - Object Lifecycle Methods
	
	init() {
		
	}
	
	// MARK: - Public Methods - Logging to standard out
	
	/// Print an object to standard out. This function prints the printable
	/// object with the tag specified in `defaultLogTag`, you may need to
	/// know this if you want to 'disable' or 'solo' these logs.
	///
	/// - parameter printableObject: The object to be printed to standard out.
	public func log(printableObject: CustomStringConvertible) {
		log(printableObject, tag: defaultLogTag)
	}
	
	/// Print an object to standard out, with a tag for identifying a group of logs.
	///
	/// - parameter printableObject: The object to be printed to standard out.
	/// - parameter tag: The tag to identify a group of logs.
	public func log(printableObject: CustomStringConvertible, tag: String) {
		log(printableObject, tag: tag, fileHandle: stdOutFileHandle)
	}
	
	// MARK: - Public Methods - Logging to standard error
	
	/// Print an object to standard error. This function prints the printable
	/// object with the tag specified in `defaultErrLogTag`, you may need to
	/// know this if you want to 'disable' or 'solo' these logs.
	///
	/// - parameter printableObject: The object to be printed to standard error.
	public func logErr(printableObject: CustomStringConvertible) {
		logErr(printableObject, tag: defaultErrLogTag)
	}
	
	/// Print an object to standard error, with a tag for identifying a group of logs.
	///
	/// - parameter printableObject: The object to be printed to standard error.
	/// - parameter tag: The tag to identify a group of logs.
	public func logErr(printableObject: CustomStringConvertible, tag: String) {
		log(printableObject, tag: tag, fileHandle: stdErrFileHandle)
	}
	
	// MARK: - Public Methods - Generic logging
	
	/// Print an object to a specified file handle with a tag for identifying a group
	/// of logs.
	///
	/// - parameter printableObject: The object to be printed to `fileHandle`.
	/// - parameter tag: The tag to identify a group of logs.
	/// - parameter fileHandle: The file handle to write the printable object to.
	public func log(printableObject: CustomStringConvertible, tag: String, fileHandle: NSFileHandle) {
		if _isTagEnabled(tag) {
			if let data = "\(tag): \(printableObject.description)\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
				fileHandle.writeData(data)
			} else {
				let data = "Unable to convert string!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
				stdErrFileHandle.writeData(data)
			}
		}
	}
	
	// MARK: - Public Methods - Managing tag status
	
	/// Change the enabled status of a given tag. If a tag is set to disabled then
	/// any attempts to log with that tag will be ignored.
	/// To disable all tags except one (or a few) see `public func soloTags(tags: [String])`.
	///
	/// - note: Enabling or disabling any tag will override any previous call to `soloTags`
	///
	/// - parameter tag: The tag to change the state of.
	/// - parameter enabled: The new state of the tag.
	public func setTag(tag: String, enabled: Bool) {
		if enabled { disabledTags.remove(tag) }
		else { disabledTags.insert(tag) }
		self.soloTags = nil
	}
	
	/// Set that only the tags passed to this method are to be enabled, all other tags
	/// will be disabled.
	/// - Note: Solo tags overrides the state of any previously enabled/disabled tags.
	///
	/// parameter tags: The list of tags that are still allowed to be printed. All
	///					others will now be ignored.
	public func soloTags(tags: [String]) {
		self.soloTags = tags
		self.disabledTags.removeAll(keepCapacity: false)
	}
	
	/// All tags will be ignored after calling this.
	public func mute() {
		self.soloTags = []
		self.disabledTags.removeAll(keepCapacity: false)
	}
	
	// MARK: - Public Methods - Tag Schemes
	
	/// Load a tag scheme into the logger. This will override any previous calls to
	/// configure the tag status, and the logger will take the state as defined by the
	/// loaded log scheme. This will also override any previous calls to this method.
	/// The scheme may also specify instances of `NSFileHandle` to be used as the default
	/// file handle to send log output to when logging or when logging errors.
	///
	/// - parameter scheme: The log scheme to be loaded.
	public func loadLogScheme(scheme: GGLogScheme) {
		self.disabledTags = scheme.disabledTags
		self.soloTags = scheme.soloTags
		if let handle = scheme.logFileHandle { self.stdOutFileHandle = handle }
		if let handle = scheme.errorFileHandle { self.errorFileHandle = handle }
	}
	
	// MARK: - Private Methods
	
	private func _isTagEnabled(tag: String) -> Bool {
		if let tags = self.soloTags {
			// If solo tags have been set, then look in it for the tag
			return tags.contains(tag)
		} else {
			// Else, check that the tag has not been disabled
			return !disabledTags.contains(tag)
		}
	}
	
}

/// Use this class to configure a scheme that can then be loaded into the logger
/// object to configure which tags it should print and which to ignore.
/// You can use log schemes to tie in with your build schemes to enable/disable
/// log tags for debug/release builds, or just to make life easier when debugging.
public class GGLogScheme {
	
	// MARK: - Instance Variables
	
	private var disabledTags = Set<String>()
	private var soloTags: [String]? = nil
	
	/// If set to a non-nil value, when loaded into a logger the logger will use
	/// this file handle to write the log data to instead of standard out.
	var logFileHandle: NSFileHandle? = nil
	/// If set to a non-nil value, when loaded into a logger the logher will user
	/// this file handle to write error logs to instead of standard error.
	var errorFileHandle: NSFileHandle? = nil
	
	// MARK: - Class Methods
	
	/// Create a tag scheme with a list of tags to be disabled. This scheme can then
	/// be loaded into the logger object to configure it.
	///
	/// - parameter disabledTags: The tags that will be disabled in the logger if this
	///							  scheme is loaded.
	class func disabledTagsScheme(disabledTags: [String]) -> GGLogScheme {
		return GGLogScheme(disabledTags: disabledTags)
	}
	
	/// Create a tag scheme with a list of tags to be exclusively enabled. This scheme
	/// can then be loaded into the logger object to configure it.
	///
	/// - parameter disabledTags: The tags that will be exclusively enabled in the logger if this scheme is loaded.
	class func soloTagsScheme(soloTags: [String]) -> GGLogScheme {
		return GGLogScheme(soloTags: soloTags)
	}
	
	/// Create a tag scheme with all tags muted. This scheme can then be loaded
	/// into the logger object to configure it.
	class func muteScheme() -> GGLogScheme {
		return GGLogScheme(soloTags: [])
	}
	
	// MARK: - Object Lifecycle Methods
	
	private init(disabledTags: [String]) {
		// Add all of the passed in tags to the disabled tags set
		for tag in disabledTags {
			self.disabledTags.insert(tag)
		}
	}
	
	private init(soloTags: [String]) {
		// Keep hold of the array of solo tags
		self.soloTags = soloTags
	}
	
}