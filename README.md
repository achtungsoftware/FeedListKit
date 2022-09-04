# FeedListKit
FeedListKit is a high level framework for representing data from an Api inside a ``SwiftUi`` ``List``. It automatically handles refreshing and loading more on scroll.

# How to use

## Create the Api
First, you need to create an api which conforms to the ``Api`` protocol. FeedListKit automatically sends a ``page`` parameter to your api, you need to handle paging directly in your api.

FeedListKit works great with [NetworkKit](https://github.com/knoggl/NetworkKit):
```swift
class MyApi: Api {
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type) async -> [T]? where T : Model {
        do {
            return try await NKHttp.getObjectArray(urlString, parameters: parameters, type: type)
        } catch {
            return nil
        }
    }
    
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type, callback: @escaping ([T]?) -> ()) where T : Model {
        NKHttp.getObjectArray(urlString, parameters: parameters, type: type, callback: callback)
    }
}
```

But you can also fetch the data on your own:
```swift
class MyApi: Api {
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type) async -> [T]? where T : Model {
        // Fetch your data and return the object array asynchronously.
        // You can use URLSession or some other http library.
    }
    
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type, callback: @escaping ([T]?) -> ()) where T : Model {
        // Fetch your data and return the object array with callback.
        // You can use URLSession or some other http library.
    }
}
```

## Create a model for your data
The model needs to conform to the ``Model`` protocol.
```swift
struct Animal: Model {
    var id: String
    var name: String
}
```


## Create a FeedNetworking
Create your first ``FeedNetworking`` and pass your object ``Model`` and your ``Api`` type.
```swift
class MyAnimalFeedNetworking: FeedNetworking<Animal, MyApi> {
    // The url to your api endpoint
    override var apiUrl: String {
        "http://mydomain.com/api/animals"
    }
    
    // Your parameters
    override var httpParameters: [String : String] {
        [
            "myKey": myValue
        ]
    }
}
```

## Use FeedList
```swift
struct MyAnimals: View {

    init() {
        self._feedNetworking = StateObject(wrappedValue: MyAnimalFeedNetworking())
    }

    @StateObject private var feedNetworking: MyAnimalFeedNetworking

    var body: some View {
        FeedList(feedNetworking: feedNetworking, row: { animal in
            Text(animal.wrappedValue.name)
        }, loadingView: {
            Text("Fetching animals ...")
        }, noDataView: {
            Text("No Animals found! :(")
        })
        .task {
            await feedNetworking.fetch()
        }
    }
}
```
