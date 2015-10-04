//
//  GGLog.swift
//  GGLog
//
//  Created by George Green on 31/05/2015.
//  Copyright (c) 2015 George Green. All rights reserved.
//  http://georgegreen.london/gglog
//

import UIKit

/// The default global logging instance.
public let GGLog = _GGLogger()

/// The main logging class used to perform all of the logging functionality.
/// For a full rundown of what, how and why you might need to use this checkout
/// http://georgegreen.london/gglog
public class _GGLogger: NSObject {
	
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
			let logString = "\(tag): \(printableObject.description)\n"
			if let data = logString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
				fileHandle.writeData(data)
			} else {
				let data = "Unable to convert string!".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
				stdErrFileHandle.writeData(data)
			}
			addToRecentLogs(logString)
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
		if let handle = scheme.errorFileHandle { self.stdErrFileHandle = handle }
	}
	
	// MARK: - Private Methods
	
	/// Internal method for checking if a tag is enabled and should be able to be logged.
	///
	/// - parameter tag: The tag fow which the status will be checked.
	private func _isTagEnabled(tag: String) -> Bool {
		if let tags = self.soloTags {
			// If solo tags have been set, then look in it for the tag
			return tags.contains(tag)
		} else {
			// Else, check that the tag has not been disabled
			return !disabledTags.contains(tag)
		}
	}
	
	// MARK: - User Interface Logs
	
	/// Used to check if visual logging has been enabled in the receiver.
	/// If visual logging is enabled, the user is able to perform a gesture
	/// (by default a quadruple tap) to present a window that shows the
	/// the logs on the device screen.
	private (set) var visualLogsEnabled: Bool = false
	
	/// An array used to keep `historyLength` of the last logged items in a cache
	/// to be accssible programatically or via the visual interface.
	/// These logs are not persisted across application launches.
	private (set) var recentLogs = [String]()
	
	/// A gesture recogniser that will be added to the `rootView` on calling `enableVisualLogs`
	/// to allow the user activate the visual log overlay.
	/// Defaults to a quadruple tap gesture recogniser, but may be set to a custom gesture
	/// recogniser.
	var visualLogGestureRecogniser: UIGestureRecognizer = {
		let rec = UITapGestureRecognizer(target: nil, action: "")
		rec.numberOfTapsRequired = 4
		return rec
	}()
	
	/// The maximum number of items to be stored in the `recentLogs` array.
	var historyLength: Int = 300
	
	/// An instance of a UIView, that must conform to `GGLogOverlayViewProtocol` that
	/// will be added to the `rootView` after the `visualLogGestureRecogniser` has
	/// successfully fired`.
	/// By default this is set to an instance of `GGLogOverlayView`.
	var logOverlayView: GGLogOverlayViewProtocol = GGLogOverlayView(frame: CGRectZero)
	
	/// The root view to which the `visualLogGestureRecogniser` will be added when
	/// visual logs are enabled. If nil, the root window for the application will
	/// be used.
	var rootView: UIView?
	private var _rootView: UIView! {
		if let rv = rootView { return rv }
		let windows = UIApplication.sharedApplication().windows
		if windows.count != 0 {
			return windows[0]
		}
		return nil
	}
	
	/// A boolean indicating if the visual logs are currently being displayed.
	private (set) var showingOverlayView: Bool = false
	
	/// Calling this method will enable the extra functionality to allow the user of
	/// the app the ability to perform a gesture to view the `recentLogs` on the device.
	func enableVisualLogs() {
		if visualLogsEnabled { return }
		visualLogsEnabled = true
		// Add the recogniser to the window
		visualLogGestureRecogniser.addTarget(self, action: "visualLogRecogniserFired:")
		if let rootView = self._rootView {
			rootView.addGestureRecognizer(visualLogGestureRecogniser)
		}
	}
	
	/// Calling this will disable the ability to allow a user to view the `recentLogs`
	/// on the device.
	func disableVisualLogs() {
		if !visualLogsEnabled { return }
		visualLogsEnabled = false
		// Remove the recogniser from the root view
		visualLogGestureRecogniser.removeTarget(self, action: "visualLogRecogniserFired:")
		if let rootView = self._rootView {
			rootView.removeGestureRecognizer(visualLogGestureRecogniser)
		}
	}
	
	/// Internal helper used when the `visualLogGestureRecogniser` fires.
	func visualLogRecogniserFired(recogniser: UIGestureRecognizer) {
		if recogniser.state == .Recognized {
			// Display or hide the log overlay view depending on the
			if showingOverlayView {
				removeOverlayView()
			} else {
				addOverlayView()
			}
		}
	}
	
	/// Internal helper used to add the overlay view when required.
	private func addOverlayView() {
		// Check that we have a valid root view and overlay view to add to it
		guard let rootView = _rootView else { return }
		guard logOverlayView is UIView else { return }
		// Add the overlay view
		(logOverlayView as! UIView).frame = rootView.bounds
		rootView.addSubview(logOverlayView as! UIView)
		// Set that we are now showing the overlay view
		showingOverlayView = true
		// Update the text in the overlay view
		updateLogOverlayView()
	}
	
	/// Internal helper used to remove the overlay view when required.
	private func removeOverlayView() {
		// Check that we have an overlay view to remove and are showing the overlay
		guard logOverlayView is UIView else { return }
		guard showingOverlayView == true else { return }
		// Remove the view
		(logOverlayView as! UIView).removeFromSuperview()
		// Set that we are no longer showing the overlay view
		showingOverlayView = false
	}
	
	/// Internal helper to update the logs in the log overlay view if it
	/// is being displated. Call whenever a new log is made.
	private func updateLogOverlayView() {
		if showingOverlayView {
			logOverlayView.textView.text = recentLogsAsFormattedString()
		}
	}
	
	/// Returns a representation of the `recentLogs` array as a `String`
	/// to be used in the `logOverlayViews` text field
	private func recentLogsAsFormattedString() -> String {
		var string = ""
		for log in recentLogs {
			string += log
		}
		return string
	}
	
	/// Internal helper function to add a string to the `recentLogs` array making
	/// sure that the array does not exceed `historyLength`.
	private func addToRecentLogs(logString: String) {
		// Add the string to the array
		recentLogs.append(logString)
		// If the array is now too long, remove the top item
		if recentLogs.count > historyLength {
			recentLogs.removeAtIndex(0)
		}
		// Update the log overlay view if it is visible
		updateLogOverlayView()
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
	/// If set to a non-nil value, when loaded into a logger the logger will use
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
	/// - parameter disabledTags: The tags that will be exclusively enabled in
	/// the logger if this scheme is loaded.
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

/// A protocol to which UIView subclasses must conform if they are to be used
/// as the overlay view for visual logs.
protocol GGLogOverlayViewProtocol {
	/// The text view in which the logs will be placed.
	var textView: UITextView { get }
}

/// A custom UIView subclass that is the default class used as an overlay view
/// for visual logs.
class GGLogOverlayView: UIView, GGLogOverlayViewProtocol {
	
	// MARK: - Instance Variables
	
	var textView: UITextView = UITextView(frame: CGRectZero)
	
	// MARK: - Object Lifecycle Methods
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override init(frame: CGRect) {
		// Call super
		super.init(frame: frame)
		// Set the background colour
		backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.8)
		// Configure and add the text view
		textView.backgroundColor = UIColor.clearColor()
		textView.editable = false
		textView.selectable = false
		textView.frame = self.bounds
		textView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		textView.textColor = UIColor.whiteColor()
		textView.font = UIFont(name: "Courier", size: 14)
		textView.contentInset.top = 20
		addSubview(textView)
	}
	
}
