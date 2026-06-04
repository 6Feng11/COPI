import CopyCore
import AppKit
import SwiftUI

struct ClipboardOverlayView: View {
    @ObservedObject var model: AppModel
    let onSelectItem: (ClipboardItem) -> Void

    @State private var query = ""
    @State private var showSettings = false
    @State private var isSearchExpanded = false
    @FocusState private var isSearchFocused: Bool

    private var results: [ClipboardItem] {
        model.search(query)
    }

    var body: some View {
        VStack(spacing: 16) {
            headerBar
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

    private var headerBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(DateHeader.title())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("剪贴板")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.46))
            }

            Spacer(minLength: 10)

            dynamicSearch
        }
    }

    private var dynamicSearch: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isSearchExpanded = true
                    isSearchFocused = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)

            if isSearchExpanded {
                TextField("搜索", text: $query)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 112)
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                if !query.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                            query = ""
                            isSearchFocused = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(.leading, isSearchExpanded ? 2 : 0)
        .padding(.trailing, isSearchExpanded ? 12 : 0)
        .frame(height: 40)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(isSearchExpanded ? 0.12 : 0.09))
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSearchExpanded)
        .onChange(of: isSearchFocused) { _, focused in
            guard !focused, query.isEmpty else {
                return
            }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isSearchExpanded = false
            }
        }
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
            onSelectItem(item)
        } label: {
            clipboardContentBlock(for: item)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("复制回剪贴板") {
                onSelectItem(item)
            }
            Button("删除", role: .destructive) {
                model.delete(item)
            }
        }
    }

    private func clipboardContentBlock(for item: ClipboardItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(typeLabel(for: item.type))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                Spacer()
                Text(ClipboardTimeFormatter.timeString(for: item.createdAt))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.42))
            }

            switch item.type {
            case .text, .link:
                Text(item.preview)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .image:
                imagePreview(for: item)
            }
        }
    }

    @ViewBuilder
    private func imagePreview(for item: ClipboardItem) -> some View {
        if let imagePath = item.imagePath,
           let image = NSImage(contentsOfFile: imagePath) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        } else {
            Text("图片缩略图")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.52))
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
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
