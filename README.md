# FeedListKit
FeedList kit is a high level framework for representing data from an Api inside a ``SwiftUi`` ``List``.

# How to use

## Create the Api
First, you need to create an api which conforms to the ``Api`` protocol.
```swift
class MyApi: Api {
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type) async -> [T]? where T : Model {
        // Fetch your data and return the object array asynchronously
    }
    
    static func fetchRows<T>(_ urlString: String, parameters: [String : String]?, type: T.Type, callback: @escaping ([T]?) -> ()) where T : Model {
        // Fetch your data and return the object array with callback
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
Create your first ``FeedNetworking``.
```swift
class MyAnimalFeedNetworking: FeedNetworking<Animal, MyApi> {
    // The url to your api endpoint
    override var apiUrl: String {
        "http://mydomain.com/api/animals"
    }
    
    // Your parameters
    override var postData: [String : String] {
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
            AnimalRow(animal.wrappedValue)
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