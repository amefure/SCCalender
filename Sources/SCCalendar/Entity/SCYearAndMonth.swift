//
//  SCYearAndMonth.swift
//
//  Created by ame on 2025/06/07.
//

import UIKit

public struct SCYearAndMonth: Identifiable, Sendable, Equatable, Hashable {
    public let id: UUID = .init()
    public let year: Int
    public let month: Int
    public var dates: [SCDate] = []

    public var yearAndMonth: String {
        "\(year)年\(month)月"
    }
    
    public init(year: Int, month: Int, dates: [SCDate]) {
        self.year = year
        self.month = month
        self.dates = dates
    }
}
