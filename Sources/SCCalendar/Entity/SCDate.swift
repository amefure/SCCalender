//
//  SCDate.swift
//
//  Created by ame on 2025/06/07.
//

import SwiftUI
import UIKit

public struct SCDate: Identifiable, @unchecked Sendable, Equatable, Hashable {
    
    public var id: UUID = .init()
    public var year: Int
    public var month: Int
    public var day: Int
    public var date: Date?
    public var week: SCWeek?
    public var holidayName: String = ""
    /// 日付に持たせたいエンティティ
    public var entities: [any SCDateEntity] = []
    public var isToday: Bool = false
    
    
    public init(
        id: UUID = UUID(),
        year: Int,
        month: Int,
        day: Int,
        date: Date? = nil,
        week: SCWeek? = nil,
        holidayName: String = "",
        entities: [any SCDateEntity] = [],
        isToday: Bool = false
    ) {
        self.id = id
        self.year = year
        self.month = month
        self.day = day
        self.date = date
        self.week = week
        self.holidayName = holidayName
        self.entities = entities
        self.isToday = isToday
    }

    public func dayColor(defaultColor: Color = .gray) -> Color {
        guard let week else { return defaultColor }
        if !holidayName.isEmpty { return .red }
        if week == .saturday {
            return .blue
        } else if week == .sunday {
            return .red
        } else {
            return defaultColor
        }
    }
    
    public static func == (lhs: SCDate, rhs: SCDate) -> Bool {
        lhs.year == rhs.year &&
        lhs.month == rhs.month &&
        lhs.day == rhs.day &&
        lhs.isToday == rhs.isToday &&
        lhs.holidayName == rhs.holidayName &&
        lhs.entities.count == rhs.entities.count
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(year)
        hasher.combine(month)
        hasher.combine(day)
        hasher.combine(isToday)
        hasher.combine(holidayName)
        hasher.combine(entities.count) // countだけを利用
    }
}


public extension SCDate {
    static let demo: SCDate = .init(year: 2024, month: 12, day: 25, isToday: true)
}
