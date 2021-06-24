//
//  File.swift
//  
//
//  Created by 平川 知秀 on 2021/06/24.
//

import Foundation
extension Sequence {
    public func forEach(_ exec: (Element) async throws -> Void) async rethrows {
        for object in self {
            try await exec(object)
        }
    }
}

extension Dictionary {
    public func reduce<Result>(_ initialResult: Result, _ nextPartialResult: (Result, (key: Key, value: Value)) async throws -> Result) async rethrows -> Result {
        var result = initialResult
        for object in self {
            result = try await nextPartialResult(result, object)
        }
        return result
    }
}
