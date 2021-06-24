//
//  ConvertCache.swift
//  NCEngine
//
//  Created by manager on 2021/03/24.
//  Copyright © 2021 四熊 泰之. All rights reserved.
//

import Foundation
import Combine



/// メモリの使用量を返す
protocol ByteCountable {
    /// メモリの使用量
    var bytes: Int { get }
}

/// キャッシュ管理システム
public class NCCacheSystem {
    /// キャッシュ管理システム本体
    static let shared = NCCacheSystem()
    
    public static func calcMaxCacheBytes(for rate: Int = defaults.maxCacheRate) -> Int {
        return (Int(ProcessInfo().physicalMemory) * rate) / 100
    }
    
    /// キャッシュとして必要な最小容量
    static let minMB = 256
    /// キャッシュのリスト
    private var storageList: [CacheStorage] = []
    /// リスト追加用のロック
    private let lock = NSLock()

    // MARK: ハンドルリスト（先頭が古い）
    /// ハンドル操作用のqueue
    private let queue = DispatchQueue(label: "cacheSystem.ncengine", qos: .utility)
    ///最古のキャッシュハンドル
    private var firstHandle: CacheHandle?
    /// 最新のキャッシュハンドル
    private var lastHandle: CacheHandle?
    
    private var maxBytesData: Int
    private var currentBytesData: Int = 0
    
    /// 最大キャッシュ容量
    var maxBytes: Int {
        get {
            var result: Int = 0
            queue.sync { result = maxBytesData }
            return result
        }
        set { // 最大量の変更
            let maxBytes = max(newValue, NCCacheSystem.minMB * 1024 * 1024) //  最小限の容量は必要
            queue.async {
                self.execChangeMaxByte(maxBytes: maxBytes)
            }
        }
    }
    
    /// 現在のキャッシュ使用量
    var currentBytes: Int {
        get {
            var result: Int = 0
            queue.sync { result = currentBytesData }
            return result
        }
        set { // 設定値以上の使用分を解放する
            queue.async {
                self.execClearLimit(limit: newValue)
            }
        }
    }
    
    // MARK: - 初期化
    private init() {
        let maxCacheRate: Int = defaults.maxCacheRate
        let bytes = NCCacheSystem.calcMaxCacheBytes(for: maxCacheRate)
        self.maxBytesData = max(bytes, NCCacheSystem.minMB * 1024 * 1024) // 最低256MB確保する
    }
    
    // MARK: -
    private func execChangeMaxByte(maxBytes: Int) {
        if maxBytes <= 0 { return }
        self.maxBytesData = maxBytes
    }
    
    /// キャッシュを追加する
    func appendCache(_ storage: CacheStorage) {
        lock.lock()
        defer { lock.unlock() }
        self.storageList.append(storage)
    }
    
    /// キャッシュを削除する
    func removeStorage(_ storage: CacheStorage) {
        lock.lock()
        defer { lock.unlock() }
        guard let index = self.storageList.firstIndex(where: { $0 === storage }) else { return }
        self.storageList.remove(at: index)
    }
    
    /// キャッシュされたデータをクリアする
    func clearAllCache() {
        lock.lock() // リストの追加を停止
        defer { lock.unlock() }
        storageList.forEach { $0.prepareClearAllCache() } // 準備
        queue.sync { // 準備中に発行されたコマンドを全て処理してから実行
            guard var handle = self.firstHandle else { return }  // 登録が無ければ作業不要
            handle.prev = nil // 本来は不要だがメモリリークがあった時に役に立つ
            while let next = handle.next { // 次のハンドル処理
                handle.next = nil
                next.prev = nil
                handle = next
            }
            self.firstHandle = nil
            self.lastHandle = nil
        }
        storageList.forEach { $0.completeClearAllCache() } // 完了
    }
    
    // MARK: - ハンドル操作
    /// 新規にハンドルを追加する
    func append(handle: CacheHandle) {
        queue.async {
            self.execAppend(handle: handle)
        }
    }
    
    /// 登録済みのハンドルを最新に更新する
    func touch(handle: CacheHandle) {
        queue.async {
            self.execTouch(handle: handle)
        }
    }
    
    private func execAppend(handle: CacheHandle) {
        if let last = self.lastHandle {
            last.next = handle
            handle.prev = last
            lastHandle = handle
        } else {
            firstHandle = handle
            lastHandle = handle
        }
        self.currentBytesData += handle.bytes
        self.execClearLimit(limit: self.maxBytesData)
    }
    
    private func execClearLimit(limit: Int) {
        while currentBytesData > limit, let handle = self.firstHandle {
            handle.storage.removeHandle(for: handle)
            self.currentBytesData -= handle.bytes
            self.firstHandle = handle.next
            handle.prev = nil // メモリリーク対策
            handle.next = nil
        }
        if let firstHandle = self.firstHandle {
            if firstHandle.prev != nil { firstHandle.prev = nil }
        } else {
            lastHandle = nil
        }
    }
    
    private func execTouch(handle: CacheHandle) {
        assert(firstHandle != nil)
        if let prev = handle.prev {
            if let next = handle.next { // リストの中間のhandle
                // リンクを外す
                prev.next = next
                next.prev = prev
            } else { // 最後尾のhandle
                // 何もしない
                return
            }
        } else if let next = handle.next { // 先頭のhandle
            // リンクを外す
            next.prev = nil
            self.firstHandle = next
        } else { // 唯一のhandle、またはパージ済みのhandle
            // 何もしない
            return
        }
        // 末尾に追加
        handle.next = nil
        self.lastHandle?.next = handle
        handle.prev = self.lastHandle
        self.lastHandle = handle
    }
}

/// キャッシュデータの操作インターフェース
class CacheHandle {
    /// 一つ古いハンドル
    final var prev: CacheHandle? = nil
    /// 一つ新しいハンドル
    final var next: CacheHandle? = nil
    /// キャッシュデータのストレージ
    final let storage: CacheStorage
    /// データのメモリ占有量
    final let bytes: Int
    
    init(map: CacheStorage, bytes: Int) {
        self.storage = map
        self.bytes = bytes
    }
}

/// キャッシュのインターフェース
protocol CacheStorage: AnyObject {
    /// ハンドルに対応するキャッシュをパージする
    func removeHandle(for handle: CacheHandle)
    /// キャッシュの全消去の準備
    func prepareClearAllCache()
    /// キャッシュの全消去完了時の処理
    func completeClearAllCache()
}

private class ConvertCacheHandle<S>: CacheHandle {
    let key: S
    
    init(map: CacheStorage, bytes: Int, key: S) {
        self.key = key
        super.init(map: map, bytes: bytes)
    }
}

private class ConvertData<R: ByteCountable>: NSLock {
    override init() {
        super.init()
        self.lock()
    }
    private var data: R!
    
    /// 書き込みがあるまで読込はブロックされる
    var value: R {
        get {
            self.lock()
            defer { self.unlock() }
            return data
        }
        set {
            data = newValue
            self.unlock()
        }
    }
}

/// 変換キャッシュ
class NCCachingConverter<S: Hashable & ByteCountable, R: ByteCountable>: CacheStorage {
    fileprivate let lock: NSLock
    private var map: [S: (handle: ConvertCacheHandle<S>, data: R)] = [:]
    
    private let converter: (S) -> R
    private var working: [S: ConvertData<R>] = [:]
    
    init(_ converter: @escaping (S) -> R) {
        self.lock = NSLock()
        self.converter = converter
        NCCacheSystem.shared.appendCache(self)
    }
    deinit {
        NCCacheSystem.shared.removeStorage(self)
    }

    func convert(_ keySource: S) -> R {
        lock.lock()
        if let object = self.object(forKey: keySource) {
            lock.unlock()
            return object
        } else if let data = working[keySource] {
            lock.unlock()
            return data.value
        }
        let data = ConvertData<R>()
        working[keySource] = data
        lock.unlock()
        
        let result = converter(keySource)
        data.value = result
        
        lock.lock()
        working.removeValue(forKey: keySource)
        self.regist(data: result, forKey: keySource)
        lock.unlock()
        return result
    }
    
    func prepareClearAllCache() {
        lock.lock()
        map.removeAll()
    }
    
    func completeClearAllCache() {
        lock.unlock()
        // workingは残しているためロック解除直後にworkingの中身が登録されることがある
    }
    
    func removeHandle(for handle: CacheHandle) {
        if case let handle as ConvertCacheHandle<S> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value.handle === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
    
    private func object(forKey key: S) -> R? {
        guard let (handle, data) = map[key] else { return nil }
        NCCacheSystem.shared.touch(handle: handle)
        return data
    }
    
    private func removeObject(forKey key: S) {
        map.removeValue(forKey: key)
    }
    
    private func regist(data: R, forKey key: S) {
        if map[key] != nil { return }
        let handle = ConvertCacheHandle(map: self, bytes: key.bytes + data.bytes, key: key)
        map[key] = (handle, data)
        NCCacheSystem.shared.append(handle: handle)
    }
}

/// プライベート用の変換キャッシュ
class NCPrivateCachingConverter<O, S: Hashable & ByteCountable, R: ByteCountable>: CacheStorage {
    fileprivate let lock: NSLocking
    private var map: [S: (handle: ConvertCacheHandle<S>, data: R)] = [:]
    
    private let converter: (O, S) -> R
    private var working: [S: ConvertData<R>] = [:]
    
    init(lock: NSLocking, converter: @escaping (O, S) -> R) {
        self.lock = lock
        self.converter = converter
        NCCacheSystem.shared.appendCache(self)
    }

    deinit {
        
        NCCacheSystem.shared.removeStorage(self)
    }
    
    func convert(owner: O, _ keySource: S) -> R {
        // 呼出時に既にロックがされている前提
        if let object = self.object(forKey: keySource) {
            lock.unlock()
            return object
        } else if let data = working[keySource] {
            lock.unlock()
            return data.value
        }
        let data = ConvertData<R>()
        working[keySource] = data
        lock.unlock()
        
        let result = converter(owner, keySource)
        data.value = result
        
        lock.lock()
        working.removeValue(forKey: keySource)
        self.regist(data: result, forKey: keySource)
        lock.unlock()
        return result
    }
    
    func prepareClearAllCache() {
        lock.lock()
        map.removeAll()
        working.removeAll()
    }
    
    func completeClearAllCache() {
        lock.unlock()
        // workingは残しているためロック解除直後にworkingの中身が登録されることがある
    }
    
    func removeHandle(for handle: CacheHandle) {
        if case let handle as ConvertCacheHandle<S> = handle {
            lock.lock()
            map.removeValue(forKey: handle.key)
        } else { // あり得ないけど念のため
            lock.lock()
            if let index = map.firstIndex(where: { $0.value.handle === handle }) {
                map.remove(at: index)
            } else {
                fatalError() // 完全なロジックエラー
            }
        }
        lock.unlock()
    }
    
    private func object(forKey key: S) -> R? {
        guard let (handle, data) = map[key] else { return nil }
        NCCacheSystem.shared.touch(handle: handle)
        return data
    }
    
    private func removeObject(forKey key: S) {
        map.removeValue(forKey: key)
    }
    
    private func regist(data: R, forKey key: S) {
        if map[key] != nil { return }
        let handle = ConvertCacheHandle(map: self, bytes: key.bytes + data.bytes, key: key)
        map[key] = (handle, data)
        NCCacheSystem.shared.append(handle: handle)
    }
}
