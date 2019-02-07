//
//  SwiftyListView.swift
//  SwiftyList
//
//  Created by Brychan Bennett-Odlum on 29/01/2019.
//  Copyright © 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Cocoa
import SnapKit

let BUFFER_SPACING: CGFloat = 0.0

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
	var documentHeight: CGFloat = 0.0

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

		self.cellLimit = self.dataSource.numberOfRows(in: self)

		self.updateViews()
	}



	// ---------------------------------------------------------------
	// ---------------------------------------------------------------

	// MARK: Internal functions + logic


	@objc private func handleScroll(notification: NSNotification) {
		self.updateViews()
	}

	private func isRowInBounds(_ index: Int) {

	}
	
	private func generateRow(withIndex index: Int) -> SwiftyListCell? {
		var cell = self.cachedCells[index]
		
		if cell == nil {
			cell = self.dataSource.cellForRow(in: self, at: index, width: self.view.frame.width)
			self.cachedCells[index] = cell
		}
		
		return cell
	}

	private func renderRow(_ cell: SwiftyListCell, at originY: CGFloat? = nil) {
		var originY2 = originY

		// Identify correct y origin
		if originY2 == nil {
			if let topCell = self.topCell, cell.id < topCell.id {
				originY2 = topCell.frame.maxY
			} else if let bottomCell = self.bottomCell, cell.id > bottomCell.id {
				originY2 = bottomCell.frame.minY - bottomCell.frame.height
			}
		}

		guard let originY = originY2 else {
			return
		}

		// Update cachedIndexes
		if self.bottomIndex == nil || cell.id > self.bottomIndex! {
			self.bottomIndex = cell.id
		}
		if self.topIndex == nil || cell.id < self.topIndex! {
			self.topIndex = cell.id
		}

		// Set origin
		cell.frame.origin.y = originY

		// Update document view
		self.documentView.addSubview(cell)
	}
	
	private func generateCells(fromIndex index: Int, toFillHeight maxHeight: CGFloat, direction: SwiftyListCellDirection) -> [SwiftyListCell] {
		var usedHeight: CGFloat = 0
		var index = index
		var cells = [SwiftyListCell]()

		while usedHeight < maxHeight {
			guard let cell = self.generateRow(withIndex: index) else {
				break
			}
			
			if (direction == .upwards && index < 0) || (direction == .downwards && index >= self.cellLimit) {
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

	private func updateDocumentHeight() {
		let contentHeight = renderedContentHeight + self.calculateVirtualizedSpace(.downwards) + self.calculateVirtualizedSpace(.upwards)
		let scrollViewHeight = self.scrollView.frame.height
		self.documentHeight = contentHeight > scrollViewHeight ? contentHeight : scrollViewHeight
	}

	private func calculateVirtualizedSpace(_ direction: SwiftyListCellDirection) -> CGFloat {
		guard let bottomIndex = self.bottomIndex, let topIndex = self.topIndex else {
			return 0
		}

		var renderedCount = abs(topIndex - bottomIndex)
		renderedCount = renderedCount != 0 ? renderedCount : 1
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
				// Remove cells which are out of view
				self.cleanup()

				// Render initial row if empty (is empty when topIndex is nil)
				if self.topIndex == nil {
					print()


					func initialIndex() -> Int {
						let scrollPos = self.contentBounds.minY
						if (scrollPos <= 0) {
							return self.cellLimit
						}
						let scrollMax = self.documentView.frame.height
						var progress = Float(scrollPos / scrollMax)
						return self.cellLimit - Int(Float(self.cellLimit) * Float(progress))
					}
					let initialCell = self.generateRow(withIndex: initialIndex())!
					self.renderRow(initialCell, at: self.contentBounds.minY)
				}

				// Around previous
				if let topIndex = self.topIndex {
					self.renderFrom(topIndex, upwards: true, downwards: false)
				}
				if let bottomIndex = self.bottomIndex {
					self.renderFrom(bottomIndex, upwards: false, downwards: true)
				}

				// Release task
				self.dwiTest?.cancel()
				self.dwiTest = nil
			}
			DispatchQueue.main.async(execute: dwiTest!)
		}

		self.updateContentHeight()
		self.updateDocumentHeight()


		// Update document view's height
		self.documentView.snp.updateConstraints { make in
			make.height.equalTo(self.documentHeight)
		}
	}
	
	private func cleanup() {
		// Cleanup at top
		if var previousIndex = self.topIndex {
			var previousRow = self.cachedCells[previousIndex]
			while let row = previousRow, row.frame.minY > self.contentBounds.maxY + BUFFER_SPACING {
				row.removeFromSuperview()
				self.cachedCells.removeValue(forKey: previousIndex)

				previousRow = nil

				previousIndex = previousIndex + 1
				previousRow = self.cachedCells[previousIndex]
			}
			self.topIndex = previousIndex
		}
		
		// Cleanup at bottom
		if var previousIndex = self.bottomIndex {
			var previousRow = self.cachedCells[previousIndex]
			while let row = previousRow, row.frame.maxY < self.contentBounds.minY - BUFFER_SPACING {
				row.removeFromSuperview()
				self.cachedCells.removeValue(forKey: previousIndex)
				
				previousRow = nil
				
				previousIndex = previousIndex - 1
				previousRow = self.cachedCells[previousIndex]
			}
			self.bottomIndex = previousIndex
		}
		
		if self.topCell == nil || self.bottomCell == nil {
			self.topIndex = nil
			self.bottomIndex = nil
		}
	}

	private func renderFrom(_ index: Int, upwards: Bool, downwards: Bool, limit: Int? = nil) {
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
				toFillHeight: (self.contentBounds.minY + BUFFER_SPACING) - previousRow.frame.minY,
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
