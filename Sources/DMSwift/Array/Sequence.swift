//
//  File.swift
//  
//
//  Created by 平川 知秀 on 2021/06/24.
//

import Foundation
extension Sequence {
    public func forEach(_ exec: (Element) async -> Void) async {
        for object in self {
            await exec(object)
        }
    }
}
