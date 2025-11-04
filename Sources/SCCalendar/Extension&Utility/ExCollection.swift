//
//  ExCollection.swift
//  MinnanoTanjyoubi
//
//  Created by t&a on 2023/12/01.
//

import UIKit

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
