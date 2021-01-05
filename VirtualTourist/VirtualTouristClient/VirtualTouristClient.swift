//
//  VirtualTouristClient.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 04/01/21.
//

import Foundation

class VirtualTouristClient {


	enum Endpoints {
		static var apiKey = ""
		static let apiUrl = "https://api.flickr.com/services/rest/"
		static let photoUrl = "https://live.staticflickr.com/"

		case getPhotos(Double, Double, Int)
		case getImage(String, String, String, String)

		var stringValue: String {
			switch self {
			case .getPhotos(let latitude, let longitude, let page):
				return "\(Endpoints.apiUrl)?method=flickr.photos.search&format=json&api_key=\(Endpoints.apiKey)&lat=\(latitude)&lon=\(longitude)&radius=10&page=\(page)&per_page=15"
			case .getImage(let server, let id, let secret, let format):
				return "\(Endpoints.photoUrl)\(server)/\(id)_\(secret)_\(format).jpg"
			}
		}

		var url: URL? {
			return URL(string: stringValue)
		}
	}
}
