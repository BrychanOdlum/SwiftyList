//
//  SwiftyListView.swift
//  SwiftyList
//
//  Created by Brychan Bennett-Odlum on 29/01/2019.
//  Copyright © 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Foundation

class ChatViewController: NSViewController {
	
	var documentView: NSView!
	var scrollView: NSScrollView!
	
	override func loadView() {
		super.loadView()
		
		self.view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 500))
		self.view.wantsLayer = true
		
		let documentView = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: self.view.frame.height))
		documentView.wantsLayer = true
		documentView.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 1, alpha: 0.02)
		
		let scrollView = NSScrollView()
		scrollView.wantsLayer = true
		scrollView.backgroundColor = NSColor(red: 0, green: 1, blue: 0, alpha: 0.1)
		scrollView.drawsBackground = true
		scrollView.documentView = documentView
		scrollView.hasHorizontalRuler = false
		scrollView.hasHorizontalScroller = false
		scrollView.hasVerticalRuler = false
		scrollView.hasVerticalScroller = true
		
		
		self.documentView = documentView
		self.scrollView = scrollView
		
		self.view.addSubview(self.scrollView)
		
	}
	
}
