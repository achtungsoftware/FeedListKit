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

// Thanks to https://stackoverflow.com/a/65878281

internal struct RenderedPreferenceKey: PreferenceKey {
    static var defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = value + nextValue() // sum all those remain to-be-rendered
    }
}

internal struct MarkRender: ViewModifier {
    @State private var toBeRendered: Int = 1
    func body(content: Content) -> some View {
        content
            .preference(key: RenderedPreferenceKey.self, value: toBeRendered)
            .onAppear { toBeRendered = 0 }
    }
}

internal extension View {
    func trackRendering() -> some View {
        self.modifier(MarkRender())
    }

    func onRendered(_ perform: @escaping () -> Void) -> some View {
        self.onPreferenceChange(RenderedPreferenceKey.self) { toBeRendered in
           if toBeRendered == 0 { perform() }
        }
    }
}
