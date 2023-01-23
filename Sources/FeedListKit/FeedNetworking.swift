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

/// This class handles api feeds
/// `FeedNetworking` makes sure, that the `rows` array is unique with help of the `Identifiable` `id`
@MainActor open class FeedNetworking<T: Model, UseApi: Api>: ObservableObject {
    
    public init() {}
    
    public var tableView = UITableView(frame: .zero, style: .plain)
    
    /// This var stores the currently displayed rows
    @Published public var rows: Array<T> = []
    
    /// The api url should always be overwritten
    open var apiUrl: String { "" }
    
    /// The http parameters
    open var httpParameters: [String: String] { [:] }
    
    public var loadMoreAtRowIndex: Int { 2 }
    
    /// This var stores the current page
    public var page: Int = 0
    
    /// This var indicates wether the first fetch is done.
    /// If this var is `true`, the first fetch is not done
    @Published public var isLoading: Bool = true
    
    /// This var indicates wether the network is currently fetching something
    public var isFetching: Bool = false
    
    /// This var indicates wether the network is currently refreshing the `rows`
    public var isRefreshing: Bool = false
    
    /// This var indicates wether the network is currently fetching more `rows`
    public var isFetchingMore: Bool = false
    
    /// This method fetches the first rows (page)
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - arrayMutation: Which ``ArrayMutationType`` should be used?, default is `.append`
    ///   - callback: The callback
    open func fetch(animated: Bool = true, arrayMutation: ArrayMutationType = .append, resetPage: Bool = false, callback: @escaping () -> Void = {}) {
        
        if isFetching {
            return
        }
        
        if resetPage {
            page = 0
        }
        
        isFetching = true
        
        UseApi.fetchRows(apiUrl, parameters: paging(httpParameters, _page: page), type: T.self) { array in
            if let array = array {
                if animated {
                    withAnimation {
                        switch arrayMutation {
                        case .replace:
                            self.rows = array
                        case .append:
                            for row in array {
                                if !self.contains(row) {
                                    self.rows.append(row)
                                }
                            }
                        }
                    }
                }else {
                    switch arrayMutation {
                    case .replace:
                        self.rows = array
                    case .append:
                        for row in array {
                            if !self.contains(row) {
                                self.rows.append(row)
                            }
                        }
                    }
                }
            }
            
            callback()
            self.fetchFinished(animated: animated)
        }
    }
    
    /// This method fetches the first rows (page)
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - arrayMutation: Which ``ArrayMutationType`` should be used?, default is `.append`
    ///   - callback: The callback
    open func fetch(animated: Bool = true, arrayMutation: ArrayMutationType = .append, resetPage: Bool = false) async {
        
        if isFetching {
            return
        }
        
        if resetPage {
            page = 0
        }
        
        isFetching = true
        
        if let array = await UseApi.fetchRows(apiUrl, parameters: paging(httpParameters, _page: page), type: T.self) {
            if animated {
                withAnimation {
                    switch arrayMutation {
                    case .replace:
                        self.rows = array
                    case .append:
                        for row in array {
                            if !self.contains(row) {
                                self.rows.append(row)
                            }
                        }
                    }
                }
            }else {
                switch arrayMutation {
                case .replace:
                    self.rows = array
                case .append:
                    for row in array {
                        if !self.contains(row) {
                            self.rows.append(row)
                        }
                    }
                }
            }
        }
        
        self.fetchFinished(animated: animated)
    }
    
    /// This method fetches more rows
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - callback: The callback
    open func fetchMore(animated: Bool = true, callback: @escaping () -> Void = {}) {
        
        if isFetching || isFetchingMore {
            return
        }
        
        page += 1
        
        isFetchingMore = true
        
        fetch(animated: animated) {
            callback()
            self.fetchMoreFinished(animated: animated)
        }
    }
    
    /// This method fetches more rows
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - callback: The callback
    open func fetchMore(animated: Bool = true) async {
        
        if isFetching || isFetchingMore {
            return
        }
        
        page += 1
        
        isFetchingMore = true
        
        await fetch(animated: animated)
        fetchMoreFinished(animated: animated)
    }
    
    /// This method refreshes and resets the rows to page `0`
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - callback: The callback
    open func refresh(animated: Bool = true, callback: @escaping () -> Void = {}) {
        
        if isFetching {
            return
        }
        
        if animated {
            withAnimation {
                isRefreshing = true
            }
        }else {
            isRefreshing = true
        }
        
        page = 0
        
        fetch(animated: animated, arrayMutation: .replace) {
            callback()
            self.refreshFinished(animated: animated)
        }
    }
    
    /// This method refreshes and resets the rows to page `0`
    /// - Parameters:
    ///   - animated: Should the result variables be animated?, default is `true`
    ///   - callback: The callback
    open func refresh(animated: Bool = true) async {
        
        if isFetching {
            return
        }
        
        if animated {
            withAnimation {
                isRefreshing = true
            }
        }else {
            isRefreshing = true
        }
        
        page = 0
        
        await fetch(animated: animated, arrayMutation: .replace)
        refreshFinished(animated: animated)
    }
    
    /// This method must be called in `.task{}`, it automatically handles fetching more rows
    /// - Parameters:
    ///   - row: The loaded row `T`
    ///   - animated: Should the result variables be animated?, default is `true`
    open func rowDidAppear(_ row: T, animated: Bool = true) async {
        if !isFetchingMore && !isFetching && !isLoading {
            if FeedNetworking.getArrayIndex(rows, searchedObject: row) == rows.count - loadMoreAtRowIndex {
                await fetchMore(animated: animated)
            }
        }
    }
    
    open func fetchFinished(animated: Bool = true) {
        
        isFetching = false
        
        if animated {
            withAnimation {
                isLoading = false
            }
        }else {
            isLoading = false
        }
        
        tableView.reloadData()
    }
    
    open func fetchMoreFinished(animated: Bool = true) {
        if animated {
            withAnimation {
                isFetchingMore = false
            }
        }else {
            isFetchingMore = false
        }
        
        tableView.reloadData()
    }
    
    open func refreshFinished(animated: Bool = true) {
        if animated {
            withAnimation {
                isRefreshing = false
            }
        }else {
            isRefreshing = false
        }
        
        tableView.reloadData()
    }
    
    public func paging(_ params: [String : String], _page: Int) -> [String : String] {
        return params.merging([
            "page": String(_page)
        ]) { (_, new) in new }
    }
    
    
    /// Checks if the `rows` array contains the provided row `T`, with the help of the `Identifiable` `id`
    /// - Parameter row: The row to search for
    /// - Returns: `true` or `false`
    public func contains(_ row: T) -> Bool {
        for _row in rows {
            if _row.id == row.id {
                return true
            }
        }
        
        return false
    }
    
    /// Trys to return the index of an object inside a `Identifiable` `Array`.
    /// - Parameter array: The `Identifiable` `Array` in which we search for the index
    /// - Parameter searchedObject: The `Identifiable` to search for
    /// - Returns: The index if found, else `0`
    public static func getArrayIndex<T: Identifiable>(_ array: [T], searchedObject: T) -> Int {
        var currentIndex: Int = 0
        for obj in array
        {
            if obj.id == searchedObject.id {
                return currentIndex
            }
            currentIndex += 1
        }
        return 0
    }
}

public extension FeedNetworking {
    enum ArrayMutationType {
        case replace, append
    }
}
