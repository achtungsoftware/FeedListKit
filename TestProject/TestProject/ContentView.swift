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
import FeedListKit

struct ContentView: View {
    
    init() {
        _feedNetworking = StateObject(wrappedValue: MyFeedNetworking())
    }
    
    @StateObject private var feedNetworking: MyFeedNetworking
    @State private var offset: CGPoint = .zero
    
    var body: some View {
        NavigationView {
            UIFeedList(feedNetworking: feedNetworking, row: { animal in
                ZStack {
                    Bool.random() ? Color.blue : Color.green
                    
                    Text(animal.name.wrappedValue)
                        .frame(height: Double(Int.random(in: 40..<600)))
                }
                .swipeActions {
                    Button {} label: {
                        Label("Favorite", systemImage: "star")
                    }
                    .tint(.yellow)
                }
            }, loadingView: {
                Text("Loading...")
            }, noDataView: {
                Text("No animals found!")
            }, offsetChanged: { offset in
                self.offset = offset
            })
            .overlay {
                Text("Offset: \(offset.y)")
            }
            .task {
                await feedNetworking.fetch()
            }
            .navigationTitle("Test")
        }
    }
}
