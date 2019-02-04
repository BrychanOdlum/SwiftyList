//
//  SwiftyListView.swift
//  SwiftyList
//
//  Created by Brychan Bennett-Odlum on 29/01/2019.
//  Copyright © 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Cocoa
import SnapKit

let BUFFER_SPACING: CGFloat = 100.0

class SwiftyListView: NSViewController {

	// Internal views
	var documentView: NSView!
	var scrollView: NSScrollView!

	var dataSource: SwiftyListViewDataSource!


	// Internal row data
	var cellLimit = 0
	var cachedCells = [Int: SwiftyListCell]()
	var topIndex: Int?
	var bottomIndex: Int?
	var topCell: SwiftyListCell? {
		guard let topIndex = self.topIndex else {
			return nil
		}
		return cachedCells[topIndex]
	}
	var bottomCell: SwiftyListCell? {
		guard let bottomIndex = self.bottomIndex else {
			return nil
		}
		return cachedCells[bottomIndex]
	}
	

	// Scroll data
	var renderedContentHeight: CGFloat = 0.0
	var documentHeight: CGFloat {
		return renderedContentHeight + self.calculateVirtualizedSpace(.downwards) + self.calculateVirtualizedSpace(.upwards)
	}

	var offsetYTop: CGFloat = 0.0
	var offsetYBottom: CGFloat = 0.0
	var contentBounds: NSRect {
		let debugRect = self.scrollView.contentView.bounds
		return NSRect(x: debugRect.origin.x, y: debugRect.origin.y + BUFFER_SPACING, width: debugRect.width, height: debugRect.height - (BUFFER_SPACING * 2))
	}

	// Temporary debug only
	var debug_meta_highlightView: NSView!


	// ---------------------------------------------------------------
	// ---------------------------------------------------------------
	// MARK: Initialisation
	
	override func loadView() {
		self.view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 500))
		self.view.wantsLayer = true

		// Setup document view
		self.documentView = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 3000))
		self.documentView.wantsLayer = true
		self.documentView.layer?.backgroundColor = CGColor(red: 1, green: 0.2, blue: 0, alpha: 0.5)

		// Setup scroll view and add document view
		self.scrollView = NSScrollView()
		self.scrollView.wantsLayer = true
		self.scrollView.backgroundColor = NSColor(red: 0, green: 1, blue: 0, alpha: 0.5)
		self.scrollView.drawsBackground = true
		self.scrollView.documentView = self.documentView
		self.scrollView.hasHorizontalRuler = false
		self.scrollView.hasHorizontalScroller = false
		self.scrollView.hasVerticalRuler = false
		self.scrollView.hasVerticalScroller = true
		self.view.addSubview(self.scrollView)

		// Add temporary debug highlight view
		self.debug_meta_highlightView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: 100))
		self.debug_meta_highlightView.wantsLayer = true
		self.debug_meta_highlightView.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 1, alpha: 0.1)
		self.documentView.addSubview(self.debug_meta_highlightView)

		// Add scroll handler
		self.scrollView.contentView.postsBoundsChangedNotifications = true
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleScroll(notification:)),
			name: NSView.boundsDidChangeNotification,
			object: self.scrollView.contentView
		)
	}
	
	override func viewDidAppear() {
		self.scrollView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		self.documentView.snp.makeConstraints { make in
			make.left.right.equalToSuperview()
			make.height.equalTo(self.documentHeight)
		}
		self.debug_meta_highlightView.snp.makeConstraints { make in
			make.left.right.equalToSuperview()
			make.bottom.equalTo(0)
			make.height.equalTo(100)
		}

		self.reloadData()
	}



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------
	// MARK: Public functions

	public func reloadData() {
		print("Reloading data in SwiftyListView...")

		self.cellLimit = self.dataSource.numberOfRows(in: self)

		self.updateViews()
	}



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------

	// MARK: Internal functions + logic


	@objc private func handleScroll(notification: NSNotification) {
		print("handle scroll")
		self.updateViews()
	}

	private func isRowInBounds(_ index: Int) {

	}
	
	private func generateRow(withIndex index: Int) -> SwiftyListCell? {
		var cell = self.cachedCells[index]

		print("generating list cell")
		
		if cell == nil {
			cell = self.dataSource.cellForRow(in: self, at: index, width: self.view.frame.width)
			self.cachedCells[index] = cell
		}
		
		return cell
	}

	private func renderRow(_ cell: SwiftyListCell, at originY: CGFloat? = nil) {
		var originY2 = originY

		print("render multiple times")

		// Identify correct y origin
		if originY2 == nil {
			if let topCell = self.topCell, cell.id < topCell.id {
				originY2 = topCell.frame.maxY
			} else if let bottomCell = self.bottomCell, cell.id > bottomCell.id {
				originY2 = bottomCell.frame.minY - bottomCell.frame.height
			}
		}

		guard let originY = originY2 else {
			print("Something went wrong when attempting to discover a ")
			return
		}

		// Update cachedIndexes
		if self.bottomIndex == nil || cell.id > self.bottomIndex! {
			print("update bottom index")
			self.bottomIndex = cell.id
		}
		if self.topIndex == nil || cell.id < self.topIndex! {
			print("update top index")
			self.topIndex = cell.id
		}

		// Set origin
		cell.frame.origin.y = originY

		print("rendered")

		// Update document view
		self.documentView.addSubview(cell)
		self.updateContentHeight()
	}
	
	private func generateCells(fromIndex index: Int, toFillHeight maxHeight: CGFloat, direction: SwiftyListCellDirection) -> [SwiftyListCell] {
		var usedHeight: CGFloat = 0
		var index = index
		var cells = [SwiftyListCell]()
		print("generate for \(index) to fill \(maxHeight)")
		while usedHeight < maxHeight {
			guard let cell = self.generateRow(withIndex: index) else {
				break
			}
			cells.append(cell)
			usedHeight += cell.frame.height
			index += direction == SwiftyListCellDirection.upwards ? -1 : 1
		}
		return cells
	}
	
	private func updateContentHeight() {
		guard let topIndex = self.topIndex, let bottomIndex = self.bottomIndex else {
			return
		}
		
		var height: CGFloat = 0
		
		for index in topIndex...bottomIndex {
			height += self.cachedCells[index]?.frame.height ?? 0 // TODO: Should we use generateCell(...) here?
		}
		
		self.renderedContentHeight = height
	}

	private func calculateVirtualizedSpace(_ direction: SwiftyListCellDirection) -> CGFloat {
		guard let bottomIndex = self.bottomIndex, let topIndex = self.topIndex else {
			return 0
		}

		let renderedCount = abs(topIndex - bottomIndex)
		let averageCellHeight = self.renderedContentHeight / CGFloat(renderedCount)

		switch (direction) {
		case .downwards:
			let cellsInDir = self.cellLimit - bottomIndex
			return averageCellHeight * CGFloat(cellsInDir)
		case .upwards:
			let cellsInDir = topIndex
			return averageCellHeight * CGFloat(cellsInDir)
		}
	}

	var dwiTest: DispatchWorkItem?
	private func updateViews() {
		debug_move_metaView()

		if self.dwiTest == nil {
			self.dwiTest = DispatchWorkItem {

				var isEmpty = true
				
				if self.topIndex != nil {
					isEmpty = false
				}
				

				// Render new row
				if isEmpty {
					// From current location
					print(" is empty! ")
					var initialCell = self.generateRow(withIndex: self.cellLimit - 1)!
					print(" is empty! : generated initial")
					self.renderRow(initialCell, at: self.contentBounds.minY)
					print(" is empty! : rendered initial")
				}

				print("... go around previous.")

				// Around previous
				if let topIndex = self.topIndex {
					print("around previous: \(topIndex)")
					self.renderFrom(topIndex, upwards: true, downwards: true)
				}

				print("... went around previous.")

				// Release task
				self.dwiTest?.cancel()
				self.dwiTest = nil
			}
			DispatchQueue.main.async(execute: dwiTest!)
		}


		// Update document view's height
		self.documentView.snp.updateConstraints { make in
			make.height.equalTo(self.documentHeight)
		}
	}

	private func renderFrom(_ index: Int, upwards: Bool, downwards: Bool, limit: Int? = nil) {
		// If either top or bottom hasn't been set yet then we probably want to be loading our initial row.
		print("render from: \(index)")

		print("abc: \(upwards) \(downwards)")

		// Insert new at top
		if upwards {
			guard let previousRow = self.cachedCells[index] else {
				return
			}

			let newCells = self.generateCells(
				fromIndex: index - 1,
				toFillHeight: (self.contentBounds.maxY + BUFFER_SPACING) - previousRow.frame.maxY,
				direction: .upwards
			)
			
			for cell in newCells {
				self.renderRow(self.generateRow(withIndex: cell.id)!)
			}
		}

		// Insert new at bottom
		
		if downwards {
			guard let previousRow = self.cachedCells[index] else {
				return
			}
			
			let newCells = self.generateCells(
				fromIndex: index + 1,
				toFillHeight: (self.contentBounds.maxY + BUFFER_SPACING) - previousRow.frame.maxY,
				direction: .downwards
			)
			
			for cell in newCells {
				self.renderRow(self.generateRow(withIndex: cell.id)!)
			}
		}
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
