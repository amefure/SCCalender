//
//  SCDate.swift
//
//  Created by ame on 2025/06/07.
//

import SwiftUI

public struct SCDate: Identifiable, @unchecked Sendable {
    var id: UUID = .init()
    var year: Int
    var month: Int
    var day: Int
    var date: Date?
    var week: SCWeek?
    var holidayName: String = ""
    /// 日付に持たせたいエンティティ
    var entities: [SCDateEntity] = []
    var isToday: Bool = false

    func dayColor(defaultColor: Color = .gray) -> Color {
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
