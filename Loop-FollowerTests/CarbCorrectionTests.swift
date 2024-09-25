//
//  CarbCorrectionTests.swift
//  Loop-FollowerTests
//
//  Created by Schömer, Jörg on 07.03.23.
//

import XCTest
@testable import Loop_Follower

final class CarbCorrectionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testCarbDescriptionWithoutFoodTypeHalfHour() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 30, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🍭 3,5g 0,5h", "Carb description not correct")
    }

    func testCarbDescriptionWithoutFoodType1Hour() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 60, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🍭 3,5g 1,0h", "Carb description not correct")
    }

    func testCarbDescriptionWithoutFoodType2Hours() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 120, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🌮 3,5g 2,0h", "Carb description not correct")
    }

    func testCarbDescriptionWithoutFoodType3Hours() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 180, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🌮 3,5g 3,0h", "Carb description not correct")
    }
    
    func testCarbDescriptionWithoutFoodType4Hours() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 240, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🌮 3,5g 4,0h", "Carb description not correct")
    }
    
    func testCarbDescriptionWithoutFoodType5Hours() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 300, carbs: 3.54, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🍕 3,5g 5,0h", "Carb description not correct")
    }
    
    func testCarbDescriptionWithoutFoodType6Hours() throws {
        let carbs = CarbCorrection(id: "", foodType: nil, absorptionTime: 360, carbs: 90.06, timestamp: "2023-03-07T09:11:00Z", created_at: "2023-03-07T09:11:00.000Z")
        
        XCTAssertEqual(carbs.description, "🥣 90,1g 6,0h", "Carb description not correct")
    }

}
