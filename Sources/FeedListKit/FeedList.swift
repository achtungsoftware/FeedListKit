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

public struct UIFeedList<T: Model, UseApi: Api, RowView: View, LoadingView: View, NoDataView: View>: View {
    
    @ObservedObject var feedNetworking: FeedNetworking<T, UseApi>
    var row: (Binding<T>) -> RowView
    var loadingView: () -> LoadingView
    var noDataView: () -> NoDataView
    var listStyle: FeedList<T, UseApi, RowView, LoadingView, NoDataView>.Style
    let startAtId: String?
    let refreshable: Bool
    let onDelete: ((_ offsets: IndexSet) -> Void)?
    
    public init(feedNetworking: FeedNetworking<T, UseApi>,
                @ViewBuilder row: @escaping (Binding<T>) -> RowView,
                @ViewBuilder loadingView: @escaping () -> LoadingView,
                @ViewBuilder noDataView: @escaping () -> NoDataView,
                listStyle: FeedList<T, UseApi, RowView, LoadingView, NoDataView>.Style = .plain,
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
    
    public var body: some View {
        UIListRepresentable(feedNetworking: feedNetworking, row: row)
            .overlay(feedNetworking.isLoading ? loadingView() : nil)
            .overlay(feedNetworking.rows.isEmpty && !feedNetworking.isLoading ? noDataView() : nil)
    }
}

internal struct UIListRepresentable<T: Model, RowView: View, UseApi: Api>: UIViewRepresentable {
    
    @ObservedObject var feedNetworking: FeedNetworking<T, UseApi>
    var row: (Binding<T>) -> RowView
    
    init(feedNetworking: FeedNetworking<T, UseApi>, @ViewBuilder row: @escaping (Binding<T>) -> RowView) {
        self.feedNetworking = feedNetworking
        self.row = row
    }
    
    let collectionView = UITableView(frame: .zero, style: .plain)
    
    func makeUIView(context: Context) -> UITableView {
        collectionView.separatorStyle = .none
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        collectionView.register(HostingCell.self, forCellReuseIdentifier: "Cell")
        return collectionView
    }
    
    func updateUIView(_ uiView: UITableView, context: Context) {
        DispatchQueue.main.async {
            uiView.reloadData()
        }
    }
    
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
            
            let tableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! HostingCell
            
            let view = parent.row(Binding(get: {
                self.parent.feedNetworking.rows[indexPath.row]
            }, set: {
                self.parent.feedNetworking.rows[indexPath.row] = $0
            }))
                .id(parent.feedNetworking.rows[indexPath.row].id)
            
            if tableViewCell.host == nil {
                let controller = UIHostingController(rootView: AnyView(view))
                tableViewCell.host = controller
                
                let tableCellViewContent = controller.view!
                tableCellViewContent.translatesAutoresizingMaskIntoConstraints = false
                tableViewCell.contentView.addSubview(tableCellViewContent)
                tableCellViewContent.topAnchor.constraint(equalTo: tableViewCell.contentView.topAnchor).isActive = true
                tableCellViewContent.leftAnchor.constraint(equalTo: tableViewCell.contentView.leftAnchor).isActive = true
                tableCellViewContent.bottomAnchor.constraint(equalTo: tableViewCell.contentView.bottomAnchor).isActive = true
                tableCellViewContent.rightAnchor.constraint(equalTo: tableViewCell.contentView.rightAnchor).isActive = true
            } else {
                tableViewCell.host?.rootView = AnyView(view)
            }
            
            tableViewCell.setNeedsLayout()
            
            return tableViewCell
        }
    }
    
    internal class HostingCell: UITableViewCell {
        var host: UIHostingController<AnyView>?
    }
}
