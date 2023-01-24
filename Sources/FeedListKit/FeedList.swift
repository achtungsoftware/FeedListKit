//  Copyright © 2022 - present Julian Gerhards
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  GitHub https://github.com/knoggl/FeedListKit
//

import SwiftUI

public struct FeedList<T: Model, UseApi: Api, RowView: View, LoadingView: View, NoDataView: View>: View {
    
    @ObservedObject var feedNetworking: FeedNetworking<T, UseApi>
    var row: (Binding<T>) -> RowView
    var loadingView: () -> LoadingView
    var noDataView: () -> NoDataView
    var listStyle: Style
    let startAtId: String?
    let refreshable: Bool
    let onDelete: ((_ offsets: IndexSet) -> Void)?
    
    public init(feedNetworking: FeedNetworking<T, UseApi>,
                @ViewBuilder row: @escaping (Binding<T>) -> RowView,
                @ViewBuilder loadingView: @escaping () -> LoadingView,
                @ViewBuilder noDataView: @escaping () -> NoDataView,
                listStyle: Style = .plain,
                startAtId: String? = nil,
                refreshable: Bool = true,
                onDelete: ((_ offsets: IndexSet) -> Void)? = nil) {
        self.feedNetworking = feedNetworking
        self.row = row
        self.loadingView = loadingView
        self.noDataView = noDataView
        self.listStyle = listStyle
        self.startAtId = startAtId
        self.refreshable = refreshable
        self.onDelete = onDelete
    }
    
    @State private var didLoad: Bool = false
    
    public var body: some View {
        ScrollViewReader { scrollViewReader in
            List {
                ForEach($feedNetworking.rows, id: \.id) { $item in
                    row($item)
                        .task {
                            await feedNetworking.rowDidAppear(item)
                        }
                }
                .onDelete(perform: onDelete)
                .onAppear {
                    
                    // TODO: scroll to startAtId not working properly
                    
                    if didLoad { return }
                    didLoad = true
                    
                    if let startAtId = startAtId {
                        scrollViewReader.scrollTo(startAtId, anchor: .top)
                    }
                }
            }
            .if(refreshable) {
                $0.refreshable {
                    await feedNetworking.refresh()
                }
            }
            .if(listStyle == .plain) {
                $0.listStyle(.plain)
            }
            .if(listStyle == .inset) {
                $0.listStyle(.inset)
            }
            .if(listStyle == .grouped) {
                $0.listStyle(.grouped)
            }
            .if(listStyle == .insetGrouped) {
                $0.listStyle(.insetGrouped)
            }
        }
        .overlay(feedNetworking.isLoading ? loadingView() : nil)
        .overlay(feedNetworking.rows.isEmpty && !feedNetworking.isLoading ? noDataView() : nil)
    }
}

public extension FeedList {
    enum Style {
        case plain, inset, grouped, insetGrouped
    }
}

internal extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

/// DO NOT USE IN PRODUCTION EXPERIMENTAL FEATURE!
@available(iOS 16.0, *)
public struct UIFeedList<T: Model, UseApi: Api, RowView: View, LoadingView: View, NoDataView: View>: View {
    
    @ObservedObject var feedNetworking: FeedNetworking<T, UseApi>
    var row: (Binding<T>) -> RowView
    var loadingView: () -> LoadingView
    var noDataView: () -> NoDataView
    var listStyle: FeedList<T, UseApi, RowView, LoadingView, NoDataView>.Style
    let startAtId: String?
    let refreshable: Bool
    let onDelete: ((_ offsets: IndexSet) -> Void)?
    let offsetChanged: ((CGPoint) -> Void)?
    var tableView: UITableView
    
    public init(feedNetworking: FeedNetworking<T, UseApi>,
                @ViewBuilder row: @escaping (Binding<T>) -> RowView,
                @ViewBuilder loadingView: @escaping () -> LoadingView,
                @ViewBuilder noDataView: @escaping () -> NoDataView,
                listStyle: FeedList<T, UseApi, RowView, LoadingView, NoDataView>.Style = .plain,
                startAtId: String? = nil,
                refreshable: Bool = true,
                onDelete: ((_ offsets: IndexSet) -> Void)? = nil,
                offsetChanged: ((CGPoint) -> Void)? = nil,
                tableView: UITableView) {
        self.feedNetworking = feedNetworking
        self.row = row
        self.loadingView = loadingView
        self.noDataView = noDataView
        self.listStyle = listStyle
        self.startAtId = startAtId
        self.refreshable = refreshable
        self.onDelete = onDelete
        self.offsetChanged = offsetChanged
        self.tableView = tableView
    }
    
    @State private var didAppear: Bool = false
    
    public var body: some View {
        UIListRepresentable(feedNetworking: feedNetworking, row: row, offsetChanged: offsetChanged, tableView: tableView)
            .overlay(feedNetworking.isLoading ? loadingView() : nil)
            .overlay(feedNetworking.rows.isEmpty && !feedNetworking.isLoading ? noDataView() : nil)
            .onAppear {
                if didAppear { return }
                feedNetworking.tableView = tableView
                didAppear = true
            }
    }
}

@available(iOS 16.0, *)
final class ContentCell: UITableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
    }

    func configure<T: Model, RowView: View, UseApi: Api>(parent: UIListRepresentable<T, RowView, UseApi>, cellForRowAt indexPath: IndexPath) {
        self.contentConfiguration = UIHostingConfiguration {
            parent.row(Binding(get: {
                parent.feedNetworking.rows[indexPath.row]
            }, set: {
                parent.feedNetworking.rows[indexPath.row] = $0
            }))
                .id(parent.feedNetworking.rows[indexPath.row].id)
        }
        .margins(.all, 0)
    }
}

@available(iOS 16.0, *)
internal struct UIListRepresentable<T: Model, RowView: View, UseApi: Api>: UIViewRepresentable {
    
    @ObservedObject var feedNetworking: FeedNetworking<T, UseApi>
    var row: (Binding<T>) -> RowView
    let offsetChanged: ((CGPoint) -> Void)?
    var tableView: UITableView
    
    init(feedNetworking: FeedNetworking<T, UseApi>, @ViewBuilder row: @escaping (Binding<T>) -> RowView, offsetChanged: ((CGPoint) -> Void)? = nil, tableView: UITableView) {
        self.feedNetworking = feedNetworking
        self.row = row
        self.offsetChanged = offsetChanged
        self.tableView = tableView
    }
    
    func makeUIView(context: Context) -> UITableView {
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.register(ContentCell.self, forCellReuseIdentifier: "cell")
        tableView.allowsSelection = false
        return tableView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) { }
    
    func makeCoordinator() -> UIListCoordinator<T, RowView, UseApi> {
        UIListCoordinator(parent: self)
    }
    
    class UIListCoordinator<T: Model, RowView: View, UseApi: Api>: NSObject, UITableViewDataSource, UITableViewDelegate {
        
        var parent: UIListRepresentable<T, RowView, UseApi>
        
        init(parent: UIListRepresentable<T, RowView, UseApi>) {
            self.parent = parent
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            parent.feedNetworking.rows.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "cell",
                for: indexPath
            ) as? ContentCell else {
                return UITableViewCell()
            }
            
            cell.configure(parent: parent, cellForRowAt: indexPath)
            
            return cell
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if let offsetChanged = parent.offsetChanged {
                offsetChanged(scrollView.contentOffset)
            }
        }
    }
}
