//
//  SCDate.swift
//
//  Created by ame on 2025/06/07.
//

import SwiftUI

public struct SCDate: Identifiable, @unchecked Sendable {
    public var id: UUID = .init()
    public var year: Int
    public var month: Int
    public var day: Int
    public var date: Date?
    public var week: SCWeek?
    public var holidayName: String = ""
    /// 日付に持たせたいエンティティ
    public var entities: [SCDateEntity] = []
    public var isToday: Bool = false
    
    
    public init(id: UUID, year: Int, month: Int, day: Int, date: Date? = nil, week: SCWeek? = nil, holidayName: String, entities: [SCDateEntity], isToday: Bool) {
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
}


public extension SCDate {
    static let demo: SCDate = .init(year: 2024, month: 12, day: 25, isToday: true)
}
