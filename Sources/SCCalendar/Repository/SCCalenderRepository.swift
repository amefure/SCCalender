//
//  SCCalenderRepository.swift
//
//  Created by t&a on 2025/06/07.
//

import Combine
import SwiftUI

public final class SCCalenderRepository: @unchecked Sendable {
    /// 初期表示位置デモ値
    private static let START_YEAR = 2023
    private static let START_MONTH = 1
    ///  カレンダーの週行数を`42(7行)`に固定する
    private static let WEEK_ROW_COUNT = 42
    /// 最初に表示したい曜日
    private var initWeek: SCWeek = .sunday

    /// 表示対象として保持している年月オブジェクト
    ///  `[2024.2 , 2024.3 , 2024.4]`
    /// `forwardMonth / backMonth`を実行するたびに追加されていく
    /// 初期表示時点は
    var yearAndMonths: AnyPublisher<[SCYearAndMonth], Never> {
        _yearAndMonths.eraseToAnyPublisher()
    }

    private let _yearAndMonths = CurrentValueSubject<[SCYearAndMonth], Never>([])

    /// 表示している曜日配列(順番はUIに反映される)
    var dayOfWeekList: AnyPublisher<[SCWeek], Never> {
        _dayOfWeekList.eraseToAnyPublisher()
    }

    private let _dayOfWeekList = CurrentValueSubject<[SCWeek], Never>(SCWeek.INITAL_LIST)

    /// アプリに表示中の年月インデックス
    var displayCalendarIndex: AnyPublisher<Int, Never> {
        _displayCalendarIndex.eraseToAnyPublisher()
    }

    private let _displayCalendarIndex = CurrentValueSubject<Int, Never>(0)

    /// 当日の日付情報
    private let today: DateComponents

    /// カレンダー
    private let calendar = Calendar(identifier: .gregorian)

    /// 日付に紐付ける情報
    private var allEntities: [SCDateEntity] = []

    init() {
        today = calendar.dateComponents([.year, .month, .day], from: Date())
    }

    /// 初期表示用に当月の年月だけセットして流す
    func fetchInitYearAndMonths() -> [SCYearAndMonth] {
        let df = DateFormatUtility()
        // 初回描画用に最新月だけ取得して表示する
        let today = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
        let yearAndMonth: SCYearAndMonth = createYearAndMonth(year: today.year ?? 1, month: today.month ?? 1, df: df)
        return [yearAndMonth]
    }

    func initialize(
        startYear: Int = START_YEAR,
        startMonth: Int = START_MONTH,
        initWeek: SCWeek = .sunday,
        entities: [SCDateEntity]
    ) {
        self.initWeek = initWeek
        allEntities = entities

        let nowYear: Int = today.year ?? startYear
        let nowMonth: Int = today.month ?? startMonth

        // 週の始まりに設定する曜日を指定
        _ = setFirstWeek(initWeek)

        // カレンダーの初期表示用データのセットアップ
        initialSetUpCalendarData(year: nowYear, month: nowMonth)
    }
}

// MARK: Private

public extension SCCalenderRepository {
    /// カレンダー初期格納年月を指定して更新（前後rangeヶ月分を含める）
    /// - Parameters:
    ///   - year: 当日の指定年
    ///   - month: 中央となる指定月
    ///   - range: 中央を基準に前後に含める月数（例: range = 1なら前後1ヶ月ずつ）
    private func initialSetUpCalendarData(year: Int, month: Int, range: Int = 5) {
        let df = DateFormatUtility()
        let middle = createYearAndMonth(year: year, month: month, df: df)
        var yearAndMonths: [SCYearAndMonth] = []

        let dateComponents = DateComponents(year: middle.year, month: middle.month)
        // 範囲内の前後SCYearAndMonthを生成して追加
        for offset in -range ... range {
            guard let newDate = calendar.date(from: dateComponents),
                  let targetDate = calendar.date(byAdding: .month, value: offset, to: newDate) else { continue }
            let components = calendar.dateComponents([.year, .month], from: targetDate)
            guard let y = components.year,
                  let m = components.month else { continue }
            let yearAndMonth = createYearAndMonth(year: y, month: m, df: df)
            yearAndMonths.append(yearAndMonth)
        }

        // 中央に指定しているインデックス番号を取得
        let index: Int = yearAndMonths.firstIndex(where: { $0.yearAndMonth == middle.yearAndMonth }) ?? 0
        _displayCalendarIndex.send(index)
        // カレンダー更新
        updateCalendar(yearAndMonths: yearAndMonths)
    }
}

public extension SCCalenderRepository {
    /// カレンダーUIを更新
    /// `currentYearAndMonth`を元に日付情報を取得して配列に格納
    private func updateCalendar(yearAndMonths: [SCYearAndMonth]) {
        _yearAndMonths.send(yearAndMonths)
    }

    /// 1ヶ月単位の`SCYearAndMonth`インスタンスを作成
    func createYearAndMonth(
        year: Int,
        month: Int,
        df: DateFormatUtility
    ) -> SCYearAndMonth {
        // 指定された年月の最初の日を取得
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let startDate = calendar.date(from: components) else {
            return SCYearAndMonth(year: year, month: month, dates: [])
        }

        // 指定された年月の日数を取得
        guard let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return SCYearAndMonth(year: year, month: month, dates: [])
        }

        // 日にち情報を格納する配列を準備
        var dates: [SCDate] = []

        // 月の初めから最後の日までループして日にち情報を作成
        for day in 1 ... range.count {
            components.year = year
            components.month = month
            components.day = day
            guard let date = calendar.date(from: components) else {
                return SCYearAndMonth(year: year, month: month, dates: [])
            }
            let dayOfWeek = calendar.component(.weekday, from: date)
            let week = SCWeek(rawValue: dayOfWeek - 1) ?? SCWeek.sunday
            let isToday: Bool = df.checkInSameDayAs(date: date, sameDay: Date())
            // 対象の日付に紐づくエンティティ情報だけを格納する
            let entities: [SCDateEntity] = allEntities.filter {
                let components = calendar.dateComponents([.month, .day], from: $0.date)
                return day == components.day && month == components.month
            }
            let scDate = SCDate(
                year: year,
                month: month,
                day: day,
                date: date,
                week: week,
                entities: entities,
                isToday: isToday
            )
            dates.append(scDate)
        }

        guard let week = dates.first?.week else { return SCYearAndMonth(year: year, month: month, dates: []) }

        let firstWeek: Int = _dayOfWeekList.value.firstIndex(of: week) ?? 0
        let initWeek: Int = _dayOfWeekList.value.firstIndex(of: initWeek) ?? 0
        let subun: Int = abs(firstWeek - initWeek)

        // 月始まりの曜日より前にブランクを追加
        if subun != 0 {
            for _ in 0 ..< subun {
                let blankScDate = SCDate(year: -1, month: -1, day: -1)
                dates.insert(blankScDate, at: 0)
            }
        }

        // 月終わりの曜日より後にブランクを追加
        if dates.count % 7 != 0 {
            let space = 7 - dates.count % 7
            for _ in 0 ..< space {
                let blankScDate = SCDate(year: -1, month: -1, day: -1)
                dates.append(blankScDate)
            }
        }

        // カレンダーの週行数を`42(7行)`に固定する
        if dates.count < Self.WEEK_ROW_COUNT {
            let blankCount = Self.WEEK_ROW_COUNT - dates.count
            for _ in 0 ..< blankCount {
                let blankScDate = SCDate(year: -1, month: -1, day: -1)
                dates.append(blankScDate)
            }
        }
        return SCYearAndMonth(year: year, month: month, dates: dates)
    }
}

public extension SCCalenderRepository {
    func forwardMonthPage() {
        let count: Int = _yearAndMonths.value.count
        let next = Int(min(CGFloat(_displayCalendarIndex.value + 1), CGFloat(count)))
        setDisplayCalendarIndex(index: next)
        // 最大年月まで2になったら翌月を追加する
        if _displayCalendarIndex.value == count - 2 {
            _ = addNextMonth()
        }
    }

    /// 年月ページを1つ戻る
    func backMonthPage() {
        if _displayCalendarIndex.value == 2 {
            // 残り年月が2になったら前月を12ヶ月分追加する
            _ = addPreMonth()
            // 2のタイミングで12ヶ月分追加するのでインデックスを+10
            let next = Int(_displayCalendarIndex.value + 10)
            setDisplayCalendarIndex(index: next)
        } else {
            let next = Int(_displayCalendarIndex.value - 1)
            setDisplayCalendarIndex(index: next)
        }
    }

    /// 格納済みの最新月の翌月を1ヶ月分追加する
    /// - Returns: 成功フラグ
    private func addNextMonth() -> Bool {
        var yearAndMonths = _yearAndMonths.value
        guard let last = yearAndMonths.last else { return false }
        let df = DateFormatUtility()
        if last.month + 1 == 13 {
            let yearAndMonth = createYearAndMonth(year: last.year + 1, month: 1, df: df)
            yearAndMonths.append(yearAndMonth)
        } else {
            let yearAndMonth = createYearAndMonth(year: last.year, month: last.month + 1, df: df)
            yearAndMonths.append(yearAndMonth)
        }
        updateCalendar(yearAndMonths: yearAndMonths)
        return true
    }

    /// 格納済みの最古月の前月を12ヶ月分追加する
    /// - Returns: 成功フラグ
    private func addPreMonth() -> Bool {
        var yearAndMonths = _yearAndMonths.value
        let df = DateFormatUtility()
        // 12ヶ月分一気に追加する
        for _ in 1 ..< 12 {
            guard let first = yearAndMonths.first else { return false }
            if first.month - 1 == 0 {
                let yearAndMonth = createYearAndMonth(year: first.year - 1, month: 12, df: df)
                yearAndMonths.insert(yearAndMonth, at: 0)
            } else {
                let yearAndMonth = createYearAndMonth(year: first.year, month: first.month - 1, df: df)
                yearAndMonths.insert(yearAndMonth, at: 0)
            }
        }
        updateCalendar(yearAndMonths: yearAndMonths)
        return true
    }

    /// 最初に表示したい曜日を設定
    /// - parameter week: 開始曜日
    func setFirstWeek(_ week: SCWeek) -> [SCWeek] {
        initWeek = week
        var list = _dayOfWeekList.value
        list.moveWeekToFront(initWeek)
        _dayOfWeekList.send(list)
        let oldYearAndMonths = _yearAndMonths.value

        let df = DateFormatUtility()

        // 週始まりが変更されたため中身すべて入れ替える
        var newYearAndMonths: [SCYearAndMonth] = []
        for yearAndMonth in oldYearAndMonths {
            let yearAndMonths: SCYearAndMonth = createYearAndMonth(year: yearAndMonth.year, month: yearAndMonth.month, df: df)
            newYearAndMonths.append(yearAndMonths)
        }
        updateCalendar(yearAndMonths: newYearAndMonths)
        return list
    }

    /// カレンダー表示年月インデックスを変更
    private func setDisplayCalendarIndex(index: Int) {
        _displayCalendarIndex.send(index)
    }

    func moveTodayCalendar() {
        let df = DateFormatUtility()
        // 今月の年月を取得
        let (year, month) = df.getDateYearAndMonth()

        guard let displayYearAndMonth = _yearAndMonths.value[safe: Int(_displayCalendarIndex.value)] else { return }
        // 今月を表示しているなら更新しない
        guard displayYearAndMonth.month != month else { return }
        guard let todayIndex = _yearAndMonths.value.firstIndex(where: { $0.year == year && $0.month == month }) else { return }
        setDisplayCalendarIndex(index: todayIndex)
    }
}
