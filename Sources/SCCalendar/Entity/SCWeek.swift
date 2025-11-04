//
//  SCWeek.swift
//
//  Created by ame on 2025/06/07.
//

import SwiftUI
import UIKit

public enum SCWeek: Int, CaseIterable, Sendable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6

    var fullSymbols: String {
        switch self {
        case .sunday: "日曜日"
        case .monday: "月曜日"
        case .tuesday: "火曜日"
        case .wednesday: "水曜日"
        case .thursday: "木曜日"
        case .friday: "金曜日"
        case .saturday: "土曜日"
        }
    }

    var shortSymbols: String {
        switch self {
        case .sunday: "日"
        case .monday: "月"
        case .tuesday: "火"
        case .wednesday: "水"
        case .thursday: "木"
        case .friday: "金"
        case .saturday: "土"
        }
    }

    var color: Color? {
        switch self {
        case .sunday: .red
        case .saturday: .blue
        default: nil
       }
    }

    static let INITAL_LIST: [SCWeek] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
}

public extension [SCWeek] {
    mutating func moveWeekToFront(_ week: SCWeek) {
        guard let index = firstIndex(of: week) else { return }
        self = Array(self[index...] + self[..<index])
    }
}
