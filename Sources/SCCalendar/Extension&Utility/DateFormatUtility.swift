//
//  DateFormatUtility.swift
//  MinnanoTanjyoubi
//
//  Created by t&a on 2023/02/12.
//

import UIKit

enum DateFormatItem: String {
    case slash = "yyyy/MM/dd"
    case jp = "yyyy年M月d日"
    case jpOnlyDate = "M月d日"
    case jpEra = "Gy年"
    case hyphen = "yyyy-MM-dd-H-m"
    case time = "H-mm"
    case monthOnly = "M"
}

final class DateFormatUtility: Sendable {
    private let df = DateFormatter()
    private let c: Calendar

    init(format: DateFormatItem = .slash) {
        if format == .jpEra {
            c = Calendar(identifier: .japanese)
        } else {
            c = Calendar(identifier: .gregorian)
        }
        df.dateFormat = format.rawValue
        df.locale = Locale(identifier: "ja_JP")
        df.calendar = c
        df.timeZone = TimeZone(identifier: "Asia/Tokyo")
    }

    /// 日付を文字列で取得する
    func getString(date: Date) -> String {
        df.string(from: date)
    }

    /// 日付をDate型で取得する
    func getDate(from: String) -> Date? {
        df.date(from: from)
    }

    /// 日付をDate型で取得する
    func getDateNotNull(from: String) -> Date {
        df.date(from: from) ?? Date()
    }

    /// 月をInt型で取得する
    func getMonthInt(date: Date) -> Int {
        let month = df.string(from: date)
        return Int(month) ?? 0
    }
}

// MARK: - 　Calendar

extension DateFormatUtility {
    /// `Date`型を受け取り`DateComponents`型を返す
    /// - Parameters:
    ///   - date: 変換対象の`Date`型
    ///   - components: `DateComponents`で取得したい`Calendar.Component`
    /// - Returns: `DateComponents`
    func convertDateComponents(
        date: Date,
        components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    ) -> DateComponents {
        c.dateComponents(components, from: date)
    }

    /// 指定した年数にしたDateオブジェクトを返す
    func setDate(
        year: Int,
        month: Int? = nil,
        day: Int? = nil
    ) -> Date {
        let now = Date()
        // 現在の時間、分、秒を取得
        let currentMonth: Int = month ?? c.component(.month, from: now)
        let currentDay: Int = day ?? c.component(.day, from: now)
        let currentHour: Int = c.component(.hour, from: now)
        let currentMinute: Int = c.component(.minute, from: now)
        let currentSecond: Int = c.component(.second, from: now)

        // 指定された年月日と現在の時刻で日付を構成する
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = currentMonth
        dateComponents.day = currentDay
        dateComponents.hour = currentHour
        dateComponents.minute = currentMinute
        dateComponents.second = currentSecond

        return c.date(from: dateComponents) ?? now
    }

    /// 指定した日付の年月をタプルで取得
    func getDateYearAndMonth(
        date: Date = Date()
    ) -> (year: Int, month: Int) {
        let today = convertDateComponents(date: date)
        guard let year = today.year,
              let month = today.month else { return (2024, 8) }
        return (year, month)
    }

    /// 受け取った日付が指定した日と同じかどうか
    func checkInSameDayAs(
        date: Date,
        sameDay: Date = Date()
    ) -> Bool {
        // 時間をリセットしておく
        let resetDate = c.startOfDay(for: date)
        let resetToDay = c.startOfDay(for: sameDay)
        return c.isDate(resetDate, inSameDayAs: resetToDay)
    }
}
