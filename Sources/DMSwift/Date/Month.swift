//
//  Month.swift
//  DataManager
//
//  Created by manager on 8/17/1 R.
//  Copyright © 1 Reiwa 四熊泰之. All rights reserved.
//

import Foundation

public struct Month: Hashable, Strideable, Codable {
    public var longYear: Int
    public var month: Int
    public var shortYear: Int { longYear % 100 }
    
    public init() {
        let date = Date()
        self.longYear = date.yearNumber
        self.month = date.monthNumber
    }

    public init(year: Int, month: Int) {
        self.init(year, month)
    }
    
    public init(_ day: Day) {
        self.init(day.year, day.month)
    }
    
    public init?<S: StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        if digs.count != 2 {
            let now = Date().day.year
            if let month = Month(fmDate: "\(now)/\(fmDate)") {
                self = month
                return
            } else {
                return nil
            }
        }
        guard let year = Int(digs[0]), let month = Int(digs[1]) else { return nil }
        self.longYear = year
        self.month = month
    }
    
    public init(_ year: Int, _ month: Int) {
        self.longYear = year
        self.month = month
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.longYear = try values.decode(Int.self, forKey: .year)
        self.month = try values.decodeIfPresent(Int.self, forKey: .month) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.longYear, forKey: .year)
        if self.month != 1 { try container.encode(self.month, forKey: .month) }
    }

    // MARK: -
    public var prevMonth: Month {
        var year = self.longYear
        var month = self.month-1
        if month < 1 {
            month = 12
            year -= 1
        }
        return Month(year: year, month: month)
    }
    
    public var nextMonth: Month {
        var year = self.longYear
        var month = self.month+1
        if month > 12 {
            month = 1
            year += 1
        }
        return Month(year, month)
    }
    
    public var shortYearMonthString: String {
        var yearString = "\(shortYear)"
        var monthString = "\(month)"
        if yearString.count == 1 { yearString = "0" + yearString }
        if monthString.count == 1 { monthString = "0" + monthString }
        return yearString + monthString
    }

    public var monthOrYearMonthString: String {
        var monthString = "\(month)"
        if Date().yearNumber == self.longYear {
            return monthString
        } else {
            if monthString.count == 1 { monthString = "0" + monthString }
            return "\(longYear)/\(monthString)"
        }
    }

    public var yearMonthJString: String { "\(longYear)年\(month)月" }
    /// ４桁年文字列
    public var longYearString: String { String(longYear) }
    public var shotYear2String: String {
        shortYear < 10 ? "0\(shortYear)" : String(shortYear)
    }
    /// 2桁固定の年文字列
    public var shortYear2String: String {
        shortYear < 10 ? "0\(shortYear)" : String(shortYear)
    }
    
    /// 2桁固定の月番号文字列
    public var month2String: String {
        month < 10 ? "0\(month)" : String(month)
    }
    
    public var firstDay: Day {
        return Day(self.longYear, self.month, 1)
    }
    
    
    public static func <(left: Month, right: Month) -> Bool {
        if left.longYear != right.longYear { return left.longYear < right.longYear }
        return left.month < right.month
    }
    
    // MARK: - <Strideable>
    public func distance(to other: Month) -> Int {
        if self > other { return -other.distance(to: self) }
        var count = 0
        var month = self
        while month < other {
            count += 1
            month = month.nextMonth
        }
        return count
    }
    
    public func advanced(by n: Int) -> Month {
        if n == 1 { return self.nextMonth }
        if n == -1 { return self.prevMonth }
        let cal = Calendar(identifier: .gregorian)
        let date = cal.date(byAdding: .month, value: n, to: Date(self))
        return date!.month
    }

}

extension Date {
    public var month: Month {
        let comp = cal.dateComponents([.year, .month], from: self)
        return Month(year: comp.year!, month: comp.month!)
    }

    public init(_ month: Month) {
        var comp = DateComponents()
        comp.year = month.longYear
        comp.month = month.month
        comp.day = 1
        let date = cal.date(from: comp)!
        self = date
    }

}

extension Date {
    public var nextDay: Date {
        return cal.date(byAdding: .day, value: 1, to: self)!
    }

    public var prevDay: Date {
        return cal.date(byAdding: .day, value: -1, to: self)!
    }

    public func date(ofHour hour: Int, minute: Int) -> Date {
        var coms = cal.dateComponents([.year, .month, .day, .hour, .minute], from: self)
        coms.hour = hour
        coms.minute = minute
        return cal.date(from: coms)!
    }
    
    public var dayNumber: Int {
        return cal.component(.day, from: self)
    }

    public var monthNumber: Int {
        return cal.component(.month, from: self)
    }

    public var yearNumber: Int {
        return cal.component(.year, from: self)
    }

    public var monthDayWeekString: String {
        return "\(monthNumber)/\(dayNumber) (\(week.description))"
    }
    
}
