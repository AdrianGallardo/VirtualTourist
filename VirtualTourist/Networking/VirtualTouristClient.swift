//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 04/01/21.
//

import Foundation

class VirtualTouristClient {

	class func getPhotos(latitude: Double, longitude: Double, page: Int, completion: @escaping (PhotoSearch?, Error?) -> Void) {
		taskForGETRequest(url: Endpoints.getPhotos(latitude, longitude, page).url, response: PhotoSearch.self) { (response, error) in
			if let response = response {
				completion(response, nil)
			} else {
				completion(nil, error)
			}
		}
	}

	class func downloadImage(server: String, id: String, secret: String, format: String, completion: @escaping (Data?, Error?) -> Void) {
		guard let url = Endpoints.downloadImage(server, id, secret, format).url else {
			print("Error URL image")
			return
		}
		let imageTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
			DispatchQueue.main.async {
				completion(data, error)
			}
		}

		imageTask.resume()
	}


	//MARK: - GET Task
	class func taskForGETRequest<ResponseType: Decodable>(url: URL?, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {

		guard let url = url else {
			return
		}

		let task = URLSession.shared.dataTask(with: url) { (data, response, error) in

			guard let data = data else {
				DispatchQueue.main.async {
					completion(nil, error)
				}
				return
			}

			let decoder = JSONDecoder()
			do {
				let responseObject = try decoder.decode(ResponseType.self, from: data)
				DispatchQueue.main.async {
					completion(responseObject, nil)
				}
			} catch {
				DispatchQueue.main.async {
					completion(nil, error)
				}
			}

		}
		task.resume()
	}

	// MARK: - Endpoints
	enum Endpoints {
		static var apiKey = "c5b24e42ffd0cb3602dde89411e584e9"
		static let apiUrl = "https://api.flickr.com/services/rest/"
		static let photoUrl = "https://live.staticflickr.com/"
		static let photosPerPage = 30
		static let searchRadiusKM = 1

		case getPhotos(Double, Double, Int)
		case downloadImage(String, String, String, String)

		var stringValue: String {
			switch self {
			case .getPhotos(let latitude, let longitude, let page):
				return "\(Endpoints.apiUrl)?method=flickr.photos.search&format=json&api_key=\(Endpoints.apiKey)&lat=\(latitude)&lon=\(longitude)&radius=\(Endpoints.searchRadiusKM)&page=\(page)&per_page=\(Endpoints.photosPerPage)&nojsoncallback=1"
			case .downloadImage(let server, let id, let secret, let format):
				return "\(Endpoints.photoUrl)\(server)/\(id)_\(secret)_\(format).jpg"
			}
		}

		var url: URL? {
			return URL(string: stringValue)
		}
	}
}
