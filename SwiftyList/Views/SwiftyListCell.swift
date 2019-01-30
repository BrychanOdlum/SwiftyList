//
//  SwiftyListCell.swift
//  SwiftyList
//
//  Created by Brychan Bennett-Odlum on 29/01/2019.
//  Copyright © 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Cocoa

class SwiftyListCell: NSView {
	private var cachedHeight: CGFloat?
	
	internal var id: Int
	internal var isRendered = false
	
	internal var height: CGFloat {
		get {
			if let cachedHeight = self.cachedHeight {
				return cachedHeight
			}
			let cachedHeight = self.calculateHeight()
			self.cachedHeight = cachedHeight
			return cachedHeight
		}
	}
	
	init(id: Int, frame: NSRect) {
		self.id = id
		super.init(frame: frame)
	}
	
	required init?(coder decoder: NSCoder) {
		fatalError("init(coder:) has not been implemented"); // TODO: This.
	}
	
	open func calculateHeight() -> CGFloat {
		return 30
	}
	
	public func invalidateCache() {
		self.cachedHeight = nil
	}
}
