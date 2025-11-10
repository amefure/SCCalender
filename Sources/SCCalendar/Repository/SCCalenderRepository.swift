//
//  SCCalenderRepository.swift
//
//  Created by t&a on 2025/06/07.
//

import Combine
import SwiftUI

public final class SCCalenderRepository: @unchecked Sendable {
    /// 初期表示位置デモ値
    public static let START_YEAR = 2023
    public static let START_MONTH = 1
    ///  カレンダーの週行数を`42(7行)`に固定する
    private static let WEEK_ROW_COUNT = 42
    /// 最初に表示したい曜日
    private var initWeek: SCWeek = .sunday

    /// 表示対象として保持している年月オブジェクト
    ///  `[2023.12 , 2024.1 , 2024.2 , 2024.3 , 2024.4]`
    ///  直近5ヶ月しか保持しない
    /// `forwardMonth / backMonth`を実行するたびにずれていく
    public var yearAndMonths: AnyPublisher<[SCYearAndMonth], Never> {
        _yearAndMonths.eraseToAnyPublisher()
    }

    private let _yearAndMonths = CurrentValueSubject<[SCYearAndMonth], Never>([])

    /// 表示している曜日配列(順番はUIに反映される)
    public var dayOfWeekList: AnyPublisher<[SCWeek], Never> {
        _dayOfWeekList.eraseToAnyPublisher()
    }

    private let _dayOfWeekList = CurrentValueSubject<[SCWeek], Never>(SCWeek.INITAL_LIST)

    /// アプリに表示中の年月インデックス
    public var displayCalendarIndex: AnyPublisher<Int, Never> {
        _displayCalendarIndex.eraseToAnyPublisher()
    }

    private let _displayCalendarIndex = CurrentValueSubject<Int, Never>(0)

    /// 当日の日付情報
    private let today: DateComponents

    /// カレンダー
    private let calendar = Calendar(identifier: .gregorian)

    /// 日付に紐付ける情報
    private var allEntities: [SCDateEntity] = []
    
    private let df = DateFormatUtility()
    
    /// データと日付の連携の際に比較する`Calendar.Component`フラグ
    /// `isMatchDataDayYear`で年を含めない場合は年ごとにデータが繰り返される
    private let isMatchDataDayYear: Bool

    public init(
        isMatchDataDayYear: Bool = true
    ) {
        today = calendar.dateComponents([.year, .month, .day], from: Date())
        self.isMatchDataDayYear = isMatchDataDayYear
    }

    /// 初期表示用に当月の年月だけセットして流す
    public func fetchInitYearAndMonths() -> [SCYearAndMonth] {
        // 初回描画用に最新月だけ取得して表示する
        let today = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: Date())
        let yearAndMonth: SCYearAndMonth = createYearAndMonth(year: today.year ?? 1, month: today.month ?? 1)
        return [yearAndMonth]
    }

    public func initialize(
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
    /// カレンダー初期格納年月を指定して更新
    /// - Parameters:
    ///   - year: 当日の指定年
    ///   - month: 中央となる指定月
    ///   - range: 中央を基準に前後に含める月数（例: range = 1なら前後1ヶ月ずつ）
    private func initialSetUpCalendarData(year: Int, month: Int, range: Int = 2) {
        let middle = createYearAndMonth(year: year, month: month)

        var yearAndMonths: [SCYearAndMonth] = []

        let dateComponents = DateComponents(year: middle.year, month: middle.month)
        // 範囲内の前後SCYearAndMonthを生成して追加
        for offset in -range ... range {
            guard let newDate = calendar.date(from: dateComponents),
                  let targetDate = calendar.date(byAdding: .month, value: offset, to: newDate) else { continue }
            let components = calendar.dateComponents([.year, .month], from: targetDate)
            guard let y = components.year,
                  let m = components.month else { continue }
            let yearAndMonth = createYearAndMonth(year: y, month: m)
            yearAndMonths.append(yearAndMonth)
        }
        
        // 中央に指定しているインデックス番号を取得
        let index: Int = yearAndMonths.firstIndex(where: { $0.yearAndMonth == middle.yearAndMonth }) ?? 0
        updateDisplayCalendarIndex(index: index)
        // カレンダー更新
        updateYearAndMonths(yearAndMonths: yearAndMonths)

    }
    
    /// カレンダー表示年月インデックスを変更
    private func updateDisplayCalendarIndex(index: Int) {
        _displayCalendarIndex.send(index)
    }
    
    /// `yearAndMonths`を更新
    private func updateYearAndMonths(yearAndMonths: [SCYearAndMonth]) {
        _yearAndMonths.send(yearAndMonths)
    }
}

public extension SCCalenderRepository {
    /// 1ヶ月単位の`SCYearAndMonth`インスタンスを作成
    func createYearAndMonth(
        year: Int,
        month: Int
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
                let components = calendar.dateComponents(isMatchDataDayYear ? [.year, .month, .day]: [.month, .day], from: $0.date)
                if isMatchDataDayYear {
                    return day == components.day && month == components.month && year == components.year
                } else {
                    return day == components.day && month == components.month
                }
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
        guard !_yearAndMonths.value.isEmpty else { return }
        // 現在インデックスを進める
        let next = _displayCalendarIndex.value + 1
        // 最後に到達する1つ前で追加
        if next >= _yearAndMonths.value.count - 1 {
           
           _ = addNextMonth()
        } else {
            updateDisplayCalendarIndex(index: next)
        }
    }

    /// 年月ページを1つ戻る
    func backMonthPage() {
        guard !_yearAndMonths.value.isEmpty else { return }

       // 現在インデックスを戻す
       let next = _displayCalendarIndex.value - 1

       if next <= 0 {
           // 先頭に到達したら配列を更新
           _ = addPreMonth()
       } else {
           updateDisplayCalendarIndex(index: next)
       }
    }

    /// 格納済みの最新月の翌月を1ヶ月分追加する
    /// - Returns: 成功フラグ
    private func addNextMonth() -> Bool {
        var yearAndMonths = _yearAndMonths.value
        guard let last = yearAndMonths.last else { return false }
        
        // 次の月を作成
        let next: SCYearAndMonth
        if last.month == 12 {
            next = createYearAndMonth(year: last.year + 1, month: 1)
        } else {
            next = createYearAndMonth(year: last.year, month: last.month + 1)
        }
        
        // 新しい月を末尾に追加して先頭を削除（5ヶ月を維持）
        yearAndMonths.append(next)
        if yearAndMonths.count > 5 {
            yearAndMonths.removeFirst()
        }
        // 年月更新
        updateYearAndMonths(yearAndMonths: yearAndMonths)
        return true
    }

    /// 格納済みの最古月の前月を12ヶ月分追加する
    /// - Returns: 成功フラグ
    private func addPreMonth() -> Bool {
        var yearAndMonths = _yearAndMonths.value
        guard let first = yearAndMonths.first else { return false }

        // 前の月を作成
        let prev: SCYearAndMonth
        if first.month == 1 {
            prev = createYearAndMonth(year: first.year - 1, month: 12)
        } else {
            prev = createYearAndMonth(year: first.year, month: first.month - 1)
        }

        // 先頭に追加して末尾を削除（5ヶ月を維持）
        yearAndMonths.insert(prev, at: 0)
        if yearAndMonths.count > 5 {
            yearAndMonths.removeLast()
        }
        updateYearAndMonths(yearAndMonths: yearAndMonths)
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

        // 週始まりが変更されたため中身すべて入れ替える
        var newYearAndMonths: [SCYearAndMonth] = []
        for yearAndMonth in oldYearAndMonths {
            let yearAndMonths: SCYearAndMonth = createYearAndMonth(year: yearAndMonth.year, month: yearAndMonth.month)
            newYearAndMonths.append(yearAndMonths)
        }
        updateYearAndMonths(yearAndMonths: newYearAndMonths)
        return list
    }

    func moveTodayCalendar() {
        let (year, month) = df.getDateYearAndMonth()

        // 現在表示中の年月
        guard let displayYearAndMonth = _yearAndMonths.value[safe: _displayCalendarIndex.value] else { return }

        // すでに今月を表示している場合は何もしない
        if displayYearAndMonth.year == year && displayYearAndMonth.month == month {
            return
        }

        // 現在の配列に今月が含まれていなければ、再構築して中央に今月を表示
        if !_yearAndMonths.value.contains(where: { $0.year == year && $0.month == month }) {
            initialSetUpCalendarData(year: year, month: month)
        } else {
            // 今月が含まれているならそのインデックスに移動
            if let todayIndex = _yearAndMonths.value.firstIndex(where: { $0.year == year && $0.month == month }) {
                updateDisplayCalendarIndex(index: todayIndex)
            }
        }
    }
}
