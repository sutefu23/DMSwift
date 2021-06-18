//
//  Day.swift
//  DataManager
//
//  Created by manager on 2019/01/30.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation

public struct Day: Hashable, Comparable, Codable {

    public var year: Int
    public var month: Int
    public var day: Int
    
    public var fmString: String {
        return "\(make2dig(month))/\(make2dig(day))/\(make4dig(year))"
    }
    
    public init() {
        let date = Date()
        self.year = date.yearNumber
        self.month = date.monthNumber
        self.day = date.dayNumber
    }
    
    public init(year: Int, month: Int, day: Int) {
        self.init(year, month, day)
    }

    public init(month: Int, day: Int) {
        self.init(month, day)
    }

    public init(_ month: Int, _ day: Int) {
        let date = Date()
        let year = date.yearNumber
        self.init(year, month, day)
    }

    public init(_ year: Int, _ month: Int, _ day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }
    
    public init?(fmJSONDay: String) {
        let parts = fmJSONDay.split(separator: "/")
        guard parts.count == 3 else { return nil }
        guard let day0 = Int(parts[0]) else { return nil }
        guard let day1 = Int(parts[1]) else { return nil }
        guard let day2 = Int(parts[2]) else { return nil }
        
        if day0 > day2 {
            self.year = day0
            self.month = day1
            self.day = day2
        } else {
            self.year = day2
            self.month = day0
            self.day = day1
        }
    }

    // FileMakerの日付
    public init?<S: StringProtocol>(fmDate2: S?) {
        guard let fmDate = fmDate2 else { return nil }
        self.init(fmDate: fmDate)
    }

    /// 4桁の数字mmddまたは6桁の数字yymmddから初期化
    public init?<S: StringProtocol>(numbers: S?) {
        guard let numbers = numbers, let value = Int(numbers), value > 0 else { return nil }
        self.year = value <= 100_00 ? Day().year : 2000 + (value / 100_00)
        self.month = (value % 100_00) / 100
        self.day = value % 100
        guard year >= 2000 && year <= 2200 && month >= 1 && month <= 12 && day >= 1 && day <= 31 else { return nil }
    }

    public init?<S: StringProtocol>(fmDate: S) {
        if fmDate.isEmpty { return nil }
        let digs = fmDate.split(separator: "/")
        switch digs.count {
        case 2:
            guard let month = Int(digs[0]), let day = Int(digs[1]) else { return nil }
            self.year = Day().year
            self.month = month
            self.day = day
        case 3:
            guard let year = Int(digs[0]), let month = Int(digs[1]), let day = Int(digs[2]) else { return nil }
            self.year = year
            self.month = month
            self.day = day
        default:
            return nil
        }
    }
    // MARK: - <Codable>
    enum CodingKeys: String, CodingKey {
        case year = "Year"
        case month = "Month"
        case day = "Day"
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.year = try values.decode(Int.self, forKey: .year)
        self.month = try values.decodeIfPresent(Int.self, forKey: .month) ?? 1
        self.day = try values.decodeIfPresent(Int.self, forKey: .day) ?? 1
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.year, forKey: .year)
        if self.month != 1 { try container.encode(self.month, forKey: .month) }
        if self.day != 1 { try container.encode(self.day, forKey: .day) }
    }

    // MARK: -
    public var isToday: Bool {
        return Day() == self
    }

    public static func <(left: Day, right: Day) -> Bool {
        if left.year != right.year { return left.year < right.year }
        if left.month != right.month { return left.month < right.month }
        return left.day < right.day
    }
    
    public var week: 週型 {
        return weekCache[self]
    }
    
    public mutating func normalize() {
        self = Date(self).day
    }
}

// MARK: -
class WeekCache {
    subscript(day: Day) -> 週型 {
        lock.lock()
        defer { lock.unlock() }
        if let week = cache[day] {
            return week
        } else {
            let week = Date(day).week
            cache[day] = week
            return week
        }
    }
    private var cache: [Day:週型] = [:]
    private let lock = NSLock()
}
private let weekCache = WeekCache()

extension Date {
    /// 日付
    public var day: Day {
        let comp = cal.dateComponents([.year, .month, .day], from: self)
        return Day(year: comp.year!, month: comp.month!, day: comp.day!)
    }
    
    public init(_ day: Day) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        let date = cal.date(from: comp)!
        self = date
    }
    
    public init(_ day: Day, _ time: Time) {
        var comp = DateComponents()
        comp.year = day.year
        comp.month = day.month
        comp.day = day.day
        comp.hour = time.hour
        comp.minute = time.minute
        comp.second = time.second
        let date = cal.date(from: comp)!
        self = date
    }
}

