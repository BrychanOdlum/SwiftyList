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
	var contentHeight: CGFloat = 0.0
	var documentHeight: CGFloat {
		return (contentHeight < self.scrollView.frame.height ? self.scrollView.frame.height : self.contentHeight) + 30000000;
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

	private func renderRow(withIndex index: Int, at originY: CGFloat) {
		guard let cell = self.generateRow(withIndex: index) else {
			print("Could not generate cell for index \(index)")
			return
		}
		cell.frame.origin.y = originY
		self.documentView.addSubview(cell)
		// self.contentHeight += cell.frame.height
	}
	
	private func generateCells(fromIndex index: Int, toFillHeight maxHeight: CGFloat, direction: SwiftyListCellDirection) -> [SwiftyListCell] {
		var usedHeight: CGFloat = 0
		var index = index
		var cells = [SwiftyListCell]()
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
					self.renderRow(withIndex: self.cellLimit, at: self.contentBounds.minY)
					self.topIndex = self.cellLimit
					self.bottomIndex = self.cellLimit
				}

				// Around previous
				if let topIndex = self.topIndex {
					// let topCell = self.cachedCells[topCellIndex]
					self.renderFrom(topIndex, upwards: true, downwards: true)
				}
				
				// Cleanup at top
				if var previousIndex = self.topIndex {
					var previousRow = self.cachedCells[previousIndex]
					while previousRow != nil, previousRow!.frame.minY > self.contentBounds.maxY + BUFFER_SPACING {
						previousRow!.removeFromSuperview()
						previousRow = nil
						previousIndex = previousIndex + 1
						
						previousRow = self.cachedCells[previousIndex]
						if previousRow == nil {
							break
						} else {
							self.offsetYTop = previousRow!.bounds.maxY
						}
					}
					self.topIndex = previousIndex
				}
				
				// Cleanup at bottom
				if var previousIndex = self.bottomIndex {
					var previousRow = self.cachedCells[previousIndex]
					while previousRow != nil, previousRow!.frame.maxY < self.contentBounds.minY - BUFFER_SPACING {
						previousRow!.removeFromSuperview()
						previousRow = nil
						previousIndex = previousIndex - 1
						
						previousRow = self.cachedCells[previousIndex]
						if previousRow == nil {
							break
						} else {
							self.offsetYBottom = previousRow!.bounds.minY
						}
					}
					self.bottomIndex = previousIndex
				}

				// Release task
				self.dwiTest?.cancel()
				self.dwiTest = nil
			}
			DispatchQueue.main.async(execute: dwiTest!)
		}


		// Update documentview height
		self.documentView.snp.updateConstraints { make in
			make.height.equalTo(self.documentHeight)
		}
	}

	private func renderFrom(_ index: Int, upwards: Bool, downwards: Bool, limit: Int? = nil) {
		// If either top or bottom hasn't been set yet then we probably want to be loading our initial row.
		if self.topCell == nil {
			let lastIndex = self.cachedCells.count - 1
			let bottomOrigin = self.contentBounds.origin.y
			self.renderRow(withIndex: lastIndex, at: bottomOrigin)
			self.topIndex = lastIndex
			self.bottomIndex = lastIndex
		}

		// Insert new at top
		if upwards, var previousIndex = self.topIndex {
			guard var previousRow = self.cachedCells[previousIndex] else {
				return
			}

			print("rednering above")
			var count = 0

			while previousIndex > 0 && previousRow.frame.maxY < self.contentBounds.maxY + BUFFER_SPACING {
				let newIndex = previousIndex - 1
				
				print("while...")

				self.renderRow(withIndex: newIndex, at: previousRow.frame.maxY)

				self.topIndex = newIndex
				previousIndex = newIndex
				previousRow = self.cachedCells[previousIndex]!

				count += 1
				if let limit = limit, count <= limit {
					break
				}
			}
		}

		// Insert new at bottom
		if downwards, var previousIndex = self.bottomIndex {
			guard var previousRow = self.cachedCells[previousIndex] else {
				return
			}

			print("rednering below")
			var count = 0

			while previousIndex < self.cellLimit && previousRow.frame.minY > self.contentBounds.minY - BUFFER_SPACING {
				let newIndex = previousIndex
					+ 1

				self.renderRow(withIndex: newIndex, at: previousRow.frame.minY - previousRow.frame.height)

				self.bottomIndex = newIndex
				previousIndex = newIndex
				previousRow = self.cachedCells[previousIndex]!

				count += 1
				if let limit = limit, count <= limit {
					break
				}
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
