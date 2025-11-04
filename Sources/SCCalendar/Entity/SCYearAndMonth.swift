//
//  SCYearAndMonth.swift
//
//  Created by ame on 2025/06/07.
//

import UIKit

public struct SCYearAndMonth: Identifiable, Sendable {
    let id: UUID = .init()
    let year: Int
    let month: Int
    var dates: [SCDate] = []

    var yearAndMonth: String {
        "\(year)年\(month)月"
    }
}
