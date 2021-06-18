//
//  String.swift
//  DataManager
//
//  Created by manager on 2019/02/04.
//  Copyright © 2019 四熊泰之. All rights reserved.
//

import Foundation


public func make2dig(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "00"
    case 1:
        return "0" + str
    default:
        return str
    }
}

public func make2digS(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "  "
    case 1:
        return " " + str
    default:
        return str
    }
}

public func make4dig(_ value: Int) -> String {
    let str = String(value)
    switch str.count {
    case 0:
        return "0000"
    case 1:
        return "000" + str
    case 2:
        return "00" + str
    case 3:
        return "0" + str
    default:
        return str
    }
}
