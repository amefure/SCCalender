//
//  SCDateEntity.swift
//
//  Created by ame on 2025/11/04.
//

import SwiftUI

/// 日付情報`SCDate`に持たせるデータエンティティプロトコル
public protocol SCDateEntity {
    var date: Date { get set }
}
