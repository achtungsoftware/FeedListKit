//
//  File.swift
//  
//
//  Created by Julian Gerhards on 05.09.22.
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
