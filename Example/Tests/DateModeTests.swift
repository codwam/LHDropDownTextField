//
//  DateModeTests.swift
//  LHDropDownTextField
//
//  Created by LDKJ on 2017/7/20.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import XCTest
import LHDropDownTextField

class DateModeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testSelectedItemNil() {
        let textField = LHDropDownTextField(frame: .zero)
        textField.dropDownMode = .date
        
        XCTAssertTrue(textField.text == nil || textField.text!.isEmpty)
        XCTAssertTrue(textField.selectedItem == nil || textField.text!.isEmpty)
    }
    
}
