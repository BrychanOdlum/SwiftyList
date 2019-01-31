//
//  SwiftyListView.swift
//  SwiftyList
//
//  Created by Brychan Bennett-Odlum on 29/01/2019.
//  Copyright © 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Cocoa
import SnapKit

let BUFFER_SPACING: CGFloat = 400.0

class SwiftyListView: NSViewController {

	// Internal views
	var documentView: NSView!
	var scrollView: NSScrollView!

	var dataSource: SwiftyListViewDataSource!


	// Internal row data
	var rows = [SwiftyListCell]()
	var topIndex: Int?
	var bottomIndex: Int?
	var topRow: SwiftyListCell? {
		guard let topIndex = self.topIndex else {
			return nil
		}
		return rows[topIndex]
	}
	var bottomRow: SwiftyListCell? {
		guard let bottomIndex = self.bottomIndex else {
			return nil
		}
		return rows[bottomIndex]
	}
	

	// Scroll data
	var currentHeight: CGFloat = 0.0
	var offsetYTop: CGFloat = 0.0
	var offsetYBottom: CGFloat = 0.0
	var contentBounds: NSRect {
		let debugRect = self.scrollView.contentView.bounds
		return NSRect(x: debugRect.origin.x, y: debugRect.origin.y + 0, width: debugRect.width, height: debugRect.height - 0)
	}

	// Temporary debug only
	var debug_meta_highlightView: NSView!



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------
	// MARK: Initialisation
	
	override func loadView() {
		self.view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 500))
		self.view.wantsLayer = true
		
		self.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: currentHeight-100))
		self.documentView.wantsLayer = true
		self.documentView.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 1, alpha: 0.02)
		
		self.scrollView = NSScrollView()
		self.scrollView.wantsLayer = true
		self.scrollView.backgroundColor = NSColor(red: 0, green: 1, blue: 0, alpha: 0.1)
		self.scrollView.drawsBackground = true
		self.scrollView.documentView = self.documentView
		self.scrollView.hasHorizontalRuler = false
		self.scrollView.hasHorizontalScroller = false
		self.scrollView.hasVerticalRuler = false
		self.scrollView.hasVerticalScroller = true
		
		self.view.addSubview(self.scrollView)
		
		self.debug_meta_highlightView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 100))
		self.debug_meta_highlightView.wantsLayer = true
		self.debug_meta_highlightView.layer?.backgroundColor = CGColor(red: 1, green: 0, blue: 0, alpha: 0.2)
		self.documentView.addSubview(self.debug_meta_highlightView)
		
		self.scrollView.contentView.postsBoundsChangedNotifications = true
		NotificationCenter.default.addObserver(self, selector: #selector(handleScroll(notification:)), name: NSView.boundsDidChangeNotification, object: self.scrollView.contentView)
	}
	
	override func viewDidAppear() {
		self.scrollView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		self.documentView.snp.makeConstraints { make in
			make.left.right.equalToSuperview()
			make.height.equalTo(currentHeight)
		}
		self.debug_meta_highlightView.snp.makeConstraints { make in
			make.left.right.equalToSuperview()
			make.bottom.equalTo(0)
			make.height.equalTo(100)
		}
		updateViews()
	}



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------
	// MARK: Public functions

	public func reloadData() {

	}



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------

	// MARK: Internal functions + logic


	@objc private func handleScroll(notification: NSNotification) {
		self.updateViews()
	}
	
	private func addRow(_ row: SwiftyListCell) {
		currentHeight += row.calculateHeight()
		rows.append(row)
	}
	
	private func updateViews() {
		debug_move_metaView()
		
		
		self.documentView.snp.updateConstraints { make in
			make.height.equalTo(currentHeight)
		}
	}
	
	private func isRowInBounds(_ index: Int) {
		
	}





	// ---------------------------------------------------------------
	// ---------------------------------------------------------------
	// MARK: Debug logic

	private func debug_move_metaView() {
		self.debug_meta_highlightView.snp.updateConstraints { make in
			make.bottom.equalTo(-self.contentBounds.origin.y)
			make.height.equalTo(self.contentBounds.height)
		}
	}

}
