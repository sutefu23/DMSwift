//
//  TestDay.swift
//  DataManagerTests
//
//  Created by 四熊泰之 on R 2/01/16.
//  Copyright © Reiwa 2 四熊泰之. All rights reserved.
//

import XCTest
@testable import DMSwift

class TestDay: XCTestCase {

    func testInitNumber() {
        XCTAssertEqual(Day(numbers: "0310"), Day(Day().year, 3, 10))
        XCTAssertEqual(Day(numbers: "211201"), Day(2021, 12, 1))
    }
}
