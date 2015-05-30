//
//  DragonLog.swift
//  DragonLog
//
//  Created by George Green on 31/05/2015.
//  Copyright (c) 2015 George Green. All rights reserved.
//

import Foundation

public let DRLogger = _DRLogger()

public class _DRLogger {
	
	// MARK: - Private Instance Variables
	
	private let stdOutFileHandle = NSFileHandle.fileHandleWithStandardOutput()
	
	// MARK: - Public Instance Variables
	
	private var disabledTags = Set<String>()
	private var soloTags: [String]? = nil
	
	// MARK: - Object Lifecycle Methods
	
	init() {
		
	}
	
	// MARK: - Public Methods - Logging to standard out
	
	/**
	Print an object to standard out. This function prints the printable object with the tag "DRLog", you may need to know this if you want to 'disable' or 'solo' these logs.
	
	:param: printableObject The object to be printed to standard out.
	*/
	public func logIt(printableObject: Printable) {
		logIt(printableObject, tag: "DRLog")
	}
	
	/**
		Print an object to standard out, with a tag for identifying a group of logs.
		
		:param: printableObject The object to be printed to standard out.
		:param: tag The tag to identify a group of logs.
	*/
	public func logIt(printableObject: Printable, tag: String) {
		log(printableObject, tag: tag, fileHandle: stdOutFileHandle)
	}
	
	// MARK: - Public Methods - Logging to standard error
	
	// MARK: - Public Methods - Generic logging
	
	/**
		Print an object to a specified file handle with a tag for identifying a group of logs.
	
		:param: printableObject The object to be printed to `fileHandle`.
		:param: tag The tag to identify a group of logs.
		:param: fileHandle The file handle to write the printable object to.
	*/
	public func log(printableObject: Printable, tag: String, fileHandle: NSFileHandle) {
		if _isTagEnabled(tag) {
			if let data = "\(tag): \(printableObject.description)\n".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
				fileHandle.writeData(data)
			} else {
				let data = "Unable to convert string!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
				fileHandle.writeData(data)
			}
		}
	}
	
	// MARK: - Public Methods - Managing tag status
	
	/**
		Change the enabled status of a given tag. If a tag is set to disabled then any attempts to log with that tag will be ignored.
		To disable all tags except one (or a few) see `public func soloTags(tags: [String])`.
		Note: Enabling or disabling any tag will override any previous call to `soloTags`.
	
		:param: tag The tag to change the state of.
		:param: enabled The new state of the tag.
	*/
	public func setTag(tag: String, enabled: Bool) {
		if enabled { disabledTags.remove(tag) }
		else { disabledTags.insert(tag) }
		self.soloTags = nil
	}
	
	/**
		Set that only the tags passed to this method are to be enabled, all other tags will be disabled.
		Note: Solo tags overrides the state of any previously enabled/disabled tags.
	
		:param: tags The list of tags that are still allowed to be printed. All others will now be ignored.
	*/
	public func soloTags(tags: [String]) {
		self.soloTags = tags
		self.disabledTags.removeAll(keepCapacity: false)
	}
	
	/**
		All tags will be ignored after calling this.
	*/
	public func mute() {
		self.soloTags = []
		self.disabledTags.removeAll(keepCapacity: false)
	}
	
	// MARK: - Private Methods
	
	private func _isTagEnabled(tag: String) -> Bool {
		if let tags = self.soloTags {
			// If solo tags have been set, then look in it for the tag
			return contains(tags, tag)
		} else {
			// Else, check that the tag has not been disabled
			return !contains(disabledTags, tag)
		}
	}
	
}