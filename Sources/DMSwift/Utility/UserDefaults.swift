//
//  File.swift
//  
//
//  Created by 平川 知秀 on 2021/06/24.
//

import Foundation
public let defaults = UserDefaults.standard

extension UserDefaults {
    /// キャッシュに使用できるメモリの全メモリに対する割合(%)）
    public var maxCacheRate: Int {
        get { integer(forKey: "maxCacheRate") }
        set {
            set(newValue, forKey: "maxCacheRate")
            NCCacheSystem.shared.maxBytes = NCCacheSystem.calcMaxCacheBytes(for: newValue)
        }
    }
}
