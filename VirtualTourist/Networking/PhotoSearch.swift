//
//  PhotoSearchResponse.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 05/01/21.
//

import Foundation

struct FlickrPhoto: Codable {
	let id: String
	let owner: String
	let secret: String
	let server: String
	let farm: Int
	let title: String
	let ispublic: Int
	let isfriend: Int
	let isfamily: Int
}

struct Photos: Codable {
	let page: Int
	let pages: Int
	let perpage: Int
	let total: Int
	let photos: [FlickrPhoto]
}

struct PhotoSearch: Codable {
	let photos: Photos
}
