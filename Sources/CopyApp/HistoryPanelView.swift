import CopyCore
import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var model: AppModel
    @State private var query = ""

    private var results: [ClipboardItem] {
        model.search(query)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding()

            List {
                ForEach(results) { item in
                    HistoryRow(item: item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.restore(item)
                        }
                        .contextMenu {
                            Button("复制回剪贴板") {
                                model.restore(item)
                            }
                            Button("删除", role: .destructive) {
                                model.delete(item)
                            }
                        }
                }
            }
        }
    }

    private var searchField: some View {
        TextField("搜索剪贴板历史", text: $query)
            .textFieldStyle(.roundedBorder)
    }
}

private struct HistoryRow: View {
    let item: ClipboardItem

    var body: some View {
        HStack(spacing: 12) {
            typeIcon
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(typeLabel)
                    if let sourceAppName = item.sourceAppName {
                        Text(sourceAppName)
                    }
                    Text(item.createdAt, style: .relative)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var typeIcon: some View {
        Image(systemName: iconName)
            .foregroundStyle(.secondary)
    }

    private var iconName: String {
        switch item.type {
        case .text:
            return "text.alignleft"
        case .link:
            return "link"
        case .image:
            return "photo"
        }
    }

    private var typeLabel: String {
        switch item.type {
        case .text:
            return "文字"
        case .link:
            return "链接"
        case .image:
            return "图片"
        }
    }
}
