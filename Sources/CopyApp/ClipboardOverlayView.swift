import CopyCore
import SwiftUI

struct ClipboardOverlayView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""
    @State private var showSettings = false

    private var selectedWeekday: Int {
        WeekdayCalendar.currentWeekdayNumber()
    }

    private var days: [WeekdayCalendarDay] {
        WeekdayCalendar.days(selectedWeekday: selectedWeekday)
    }

    private var results: [ClipboardItem] {
        model.search(query)
    }

    private var currentItem: ClipboardItem? {
        model.items.first
    }

    var body: some View {
        VStack(spacing: 16) {
            weekdayBar
            currentClipboardCard
            searchField
            historyList
            controls
        }
        .padding(18)
        .frame(width: 460, height: 560)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .preferredColorScheme(.dark)
    }

    private var weekdayBar: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.number) { day in
                Text("\(day.number)")
                    .font(.system(size: 13, weight: day.isSelected ? .bold : .medium))
                    .foregroundStyle(day.isSelected ? Color.black : Color.white.opacity(0.72))
                    .frame(width: 42, height: 34)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(day.isSelected ? Color.white : Color.white.opacity(0.10))
                    )
            }
        }
    }

    private var currentClipboardCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("当前剪贴板", systemImage: currentItem == nil ? "clipboard" : iconName(for: currentItem!.type))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                Spacer()
                if model.isRecordingPaused {
                    Text("已暂停")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            if let currentItem {
                Text(currentItem.preview)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Text(typeLabel(for: currentItem.type))
                    if let sourceAppName = currentItem.sourceAppName {
                        Text(sourceAppName)
                    }
                    Text(currentItem.createdAt, style: .relative)
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
            } else {
                Text("复制任意文字、链接或图片后会显示在这里")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.50))
            TextField("搜索历史", text: $query)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.10))
        )
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(results) { item in
                    overlayRow(for: item)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxHeight: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            if showSettings {
                HStack {
                    Label("本地保存 · 最近 1000 条", systemImage: "internaldrive")
                    Spacer()
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
                .padding(.horizontal, 4)
            }

            HStack(spacing: 10) {
                panelButton(
                    title: model.isRecordingPaused ? "恢复" : "暂停",
                    systemImage: model.isRecordingPaused ? "play.fill" : "pause.fill"
                ) {
                    model.toggleRecordingPaused()
                }
                panelButton(title: "清空", systemImage: "trash") {
                    model.clearHistory()
                }
                panelButton(title: "设置", systemImage: "slider.horizontal.3") {
                    showSettings.toggle()
                }
                panelButton(title: "退出", systemImage: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private func overlayRow(for item: ClipboardItem) -> some View {
        Button {
            model.restore(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName(for: item.type))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.preview)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(typeLabel(for: item.type))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("复制回剪贴板") {
                model.restore(item)
            }
            Button("删除", role: .destructive) {
                model.delete(item)
            }
        }
    }

    private func panelButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .labelStyle(.titleAndIcon)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func iconName(for type: ClipboardItemType) -> String {
        switch type {
        case .text:
            return "text.alignleft"
        case .link:
            return "link"
        case .image:
            return "photo"
        }
    }

    private func typeLabel(for type: ClipboardItemType) -> String {
        switch type {
        case .text:
            return "文字"
        case .link:
            return "链接"
        case .image:
            return "图片"
        }
    }
}
