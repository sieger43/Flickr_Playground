import UIKit
import Foundation

struct FlickrPhotoRecord : Codable {

    let id : String?
    let owner : String?
    let secret : String?
    let server : String?
    let farm : Int?
    let title : String?
    let ispublic : Int?
    let isfriend : Int?
    let isfamily : Int?
    let url_m : String?
    let height_m : String?
    let width_m : String?
    
    enum CodingKeys: String, CodingKey {
        
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case ispublic
        case isfriend
        case isfamily
        case url_m
        case height_m
        case width_m
    }
}

struct FlickPhotoInformation : Codable {
    let page : Int?
    let pages : Int?
    let perpage : Int?
    let total : String?
    let photo : [FlickrPhotoRecord]
}

struct FlickrSearchResponse: Codable {
    let photos: FlickPhotoInformation?
    let stat: String?
}

struct FlickrErrorResponse: Codable {
    
    // { "stat": "fail", "code": 99, "message": "Insufficient permissions. Method requires read privileges; none granted." }
    
    let stat: String
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case stat
        case code
        case message
    }
}

extension FlickrErrorResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}

class FlickrClient
{
    static let restApiKey = ""
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/"
        
        case photosearch
        
        var stringValue : String {
            switch self {
            case .photosearch: return Endpoints.base
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
    }
    
    class func handleFlickrSearchResponse(success: Bool, error: Error?, response: FlickrSearchResponse?) {
        if success {
            print("Happy FlickrSearchResponse")
            
            if let thedata = response {
                print("\(thedata)")
            }
            
        } else {
            let message = error?.localizedDescription ?? ""
            print("\(message)");
            print("Sad FlickrSearchResponse")
        }
    }

    class func getPhotoList(completion: @escaping (Bool, Error?, FlickrSearchResponse?) -> Void) {
        
        let qItems = [URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: restApiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "lat", value: "43.204940"),
            URLQueryItem(name: "lon", value: "-77.691951"),
            URLQueryItem(name: "extras", value: "url_m")]
        
        //+ "?method=flickr.photos.search&format=json&nojsoncallback=1&api_key=" + restApiKey
        
        taskForGETRequest(url: Endpoints.photosearch.url, queryItems: qItems, responseType: FlickrSearchResponse.self) { response, error in
            if let response = response {
                completion(true, nil, response)
            } else {
                print("false FlickrSearchResponse")
                completion(false, error, nil)
            }
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, queryItems: [URLQueryItem], responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {

        var finalURL:URL = url;

        var components = URLComponents(url: finalURL, resolvingAgainstBaseURL: false)!
        
        components.queryItems = queryItems
        
        if let urlWithQuery = components.url {
            
            finalURL = urlWithQuery
        }
        
        print(finalURL)
        
        let request = URLRequest(url: finalURL)
        // The default HTTP method for URLRequest is “GET”.
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            print(data.description)
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(FlickrErrorResponse.self, from: data) as Error
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        
        return task
    }
}

FlickrClient.getPhotoList(completion: FlickrClient.handleFlickrSearchResponse)

var str = "Hello, playground"

print(str)
