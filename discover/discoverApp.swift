//
//  discoverApp.swift
//  discover
//
//  Created by forest on 2026/10/26.
//

import SwiftUI
import SwiftData

@main
struct discoverApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Dream.self,
            Item.self,
            Action.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // ストアの読み込みに失敗した場合（スキーマ不整合など）、古いストアファイルを削除してリトライする
            print("ModelContainer creation failed: \(error). Attempting to reset store...")
            
            // 標準的なSwiftDataのURLからストアファイルを削除
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            
            // 再度コンテナの作成を試みる
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
