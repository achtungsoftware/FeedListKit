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

import Foundation
import FeedListKit

struct Animal: Model {
    let id: String
    var name: String
}

class MyFeedNetworking: FeedNetworking<Animal, MyApi> {}

class MyApi: Api {
    
    static let testArray: Array<Animal> = [
        .init(id: "1", name: "Lion"),
        .init(id: "2", name: "Dog"),
        .init(id: "3", name: "Chicken"),
        .init(id: "4", name: "Giraffe"),
        .init(id: "5", name: "Cow"),
        .init(id: "6", name: "Cat"),
        .init(id: "7", name: "Bird"),
        .init(id: "8", name: "Ape"),
        .init(id: "9", name: "Crocodile"),
    ]
    
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type) async -> [T]? where T : FeedListKit.Model {
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            return testArray as? [T]
        } catch {
            return testArray as? [T]
        }
    }
    
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type, callback: @escaping ([T]?) -> ()) where T : FeedListKit.Model {
        callback(testArray as? [T])
    }
}
