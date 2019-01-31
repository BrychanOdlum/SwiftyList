//
// Created by Brychan Bennett-Odlum on 30/01/2019.
// Copyright (c) 2019 Brychan Bennett-Odlum. All rights reserved.
//

import Cocoa

protocol SwiftyListViewDataSource {
	// Asks the data source to return the number of rows in the given list view.
	func swiftyList(_: SwiftyListView, numberOfRows: Int) -> Int;

	// Asks the data source to provide a SwiftyListCell for a given list view and index.
	func swiftyList(_: SwiftyListView, cellForRow: Int) -> SwiftyListCell;
}