import AppKit
import SwiftUI

@main
struct CopyMenuBarApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("Copy", systemImage: "doc.on.clipboard") {
            CopyMenu(model: model)
        }
        .menuBarExtraStyle(.menu)

        Window("剪贴板历史", id: "history") {
            HistoryPanelView(model: model)
                .frame(minWidth: 520, minHeight: 520)
        }

        Window("设置", id: "settings") {
            SettingsView(model: model)
                .frame(width: 360, height: 220)
        }
    }
}

private struct CopyMenu: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("打开剪贴板历史") {
            openWindow(id: "history")
            NSApplication.shared.activate()
        }

        Button(model.isRecordingPaused ? "恢复记录" : "暂停记录") {
            model.toggleRecordingPaused()
        }

        Divider()

        Button("清空全部历史", role: .destructive) {
            model.clearHistory()
        }

        Button("设置") {
            openWindow(id: "settings")
            NSApplication.shared.activate()
        }

        Divider()

        Button("退出") {
            NSApplication.shared.terminate(nil)
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Toggle("暂停记录", isOn: Binding(
                get: { model.isRecordingPaused },
                set: { _ in model.toggleRecordingPaused() }
            ))
            Text("历史保留数量：最近 1000 条")
                .foregroundStyle(.secondary)
            Text("所有数据仅保存在本机 Application Support/Copy。")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
