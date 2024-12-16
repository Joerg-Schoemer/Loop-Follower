//
//  TimeInRange.swift
//  Loop-FollowerTests
//
//  Created by Jörg Schömer on 15.12.24.
//

import Testing
import Foundation


@testable import Loop_Follower

struct TimeInRange {
    
    @Test func oneHundret() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!
        let minValue = 100
        let maxValue = 120
        
        let entries = generateData(startDate, minValue, maxValue)
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 1000)
    }
    
    @Test func test() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!
        
        let entries = generateData(
            startDate,
            by: { (i: Int) -> Int in Int(sin(Double(i) * .pi / 60) * 100) + 100 }
        )
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 416)
    }
    
    @Test func onlyTheFirst() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!
        
        let entries = generateData(
            startDate,
            by: { (i: Int) -> Int in if i == 0 { 181 } else { 100 } }
        )
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 996)
    }
    
    @Test func onlyTheLast() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!
        
        let entries = generateData(
            startDate,
            by: { (i: Int) -> Int in if i == 1435 { 181 } else { 100 } }
        )
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 996)
    }
    
    @Test func all() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0
        
        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!
        
        let entries = generateData(
            startDate,
            by: { (i: Int) -> Int in 181 }
        )
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 0)
    }
    
    @Test func fromHighToLow() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 15
        dateComponents.timeZone = TimeZone(abbreviation: "CET")
        dateComponents.hour = 0
        dateComponents.minute = 0

        // Create date from components
        let startDate = Calendar.current.date(from: dateComponents)!

        let entries = generateData(
            startDate,
            by: { (i: Int) -> Int in if i == 0 { 181 } else if i == 5 { 69 } else { 100 } }
        )
        
        let tir = calcTimeInRange(entries, min: 70, max: 180)
        #expect(tir == 993)
    }
}

fileprivate let iso8601 = ISO8601DateFormatter(.withFractionalSeconds)

func generateData(_ startDate: Date, _ minValue: Int, _ maxValue: Int) -> [Entry] {
    var entries: [Entry] = []
    
    
    for i in 0...23 {
        let hour = Calendar.current.date(byAdding: .hour, value: i, to: startDate)!

        for minutes in stride(from: 0, to: 60, by: 5) {
            let minutes = Calendar.current.date(byAdding: .minute, value: minutes, to: hour)!
            entries.append(Entry(sgv: Int.random(in: minValue...maxValue), id: "egal", dateString: iso8601.string(from: minutes)))
        }
    }

    return entries
}

func generateData(_ startDate: Date, by: (Int) -> Int) -> [Entry] {
    var entries: [Entry] = []
    
    for minutes in stride(from: 0, to: 1440, by: 5) {
        let date = Calendar.current.date(byAdding: .minute, value: minutes, to: startDate)!
        entries.append(Entry(sgv: by(minutes), id: "egal", dateString: iso8601.string(from: date)))
    }
    
    return entries
}
