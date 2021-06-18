//
//  Alert.swift
//  DataManager
//
//  Created by manager on 2020/04/07.
//  Copyright © 2020 四熊泰之. All rights reserved.
//

import Foundation
#if os(macOS)
import Cocoa
#elseif os(iOS) || os(tvOS)
import UIKit
#endif

public func showMessage(message: String, info: String = "", ok: String = "Ok") {
    #if os(macOS)
    let alert = NSAlert()
    alert.messageText = message
    alert.informativeText = info
    alert.addButton(withTitle: ok)
    alert.runModal()
    #elseif os(iOS) || os(tvOS)
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    let actionOk = UIAlertAction(title: ok, style: .default) { _ in  }
    alert.addAction(actionOk)
    let vc = UIApplication.shared.windows.first?.rootViewController
    vc?.present(alert, animated: true, completion: nil)
    #endif
}

public func showDialog(message: String, ok: (title: String, action: ()->()), ng: (title: String, action: ()->())) {
    #if os(macOS)
    let alert = NSAlert()
    alert.messageText = message
    alert.addButton(withTitle: ok.title)
    alert.addButton(withTitle: ng.title)
    if alert.runModal() == .alertFirstButtonReturn {
        ok.action()
    } else {
        ng.action()
    }
    #elseif os(iOS) || os(tvOS)
    let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
    let actionOk = UIAlertAction(title: ok.title, style: .default) { _ in ok.action() }
    let actionNG = UIAlertAction(title: ng.title, style: .cancel) { _ in ng.action() }
    alert.addAction(actionOk)
    alert.addAction(actionNG)
    let vc = UIApplication.shared.windows.first?.rootViewController
    vc?.present(alert, animated: true, completion: nil)
    #endif
}



#if os(iOS)
import UIKit

extension Error {
    public func showAlert() {
        let message = self.localizedDescription
        showMessage(message: message)
    }
}

extension UIViewController {
    public func showMessageDialog(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: "ok", style: .default, handler: nil)
        alert.addAction(action1)
        self.present(alert, animated: true)
        return
    }
    
    public func showSelectDialog(title: String, message: String, ok: String, cancel: String) -> Bool {
        var isOk: Bool = true
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action1 = UIAlertAction(title: ok, style: .default, handler: { _ in isOk = true })
        let action2 = UIAlertAction(title: cancel, style: .default, handler: { _ in isOk = false })
        alert.addAction(action1)
        alert.addAction(action2)
        self.present(alert, animated: true)
        return isOk
    }
}



#elseif os(macOS)
import Cocoa

extension Error {
    public func showAlert() {
        let alert = NSAlert(error: self)
        alert.runModal()
    }
    
}

#endif

#if os(macOS) || os(iOS)
extension Error {
    public func asyncShowAlert() {
        DispatchQueue.main.async {
            self.showAlert()
        }
    }
}
#endif
