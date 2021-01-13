//
//  DataController.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 13/01/21.
//

import Foundation
import CoreData

class DataController {
	let persistentContainer: NSPersistentContainer

	var viewContext: NSManagedObjectContext {
		return persistentContainer.viewContext
	}

	init(modelName: String) {
		persistentContainer = NSPersistentContainer(name: modelName)
	}

	func load(completion: (() -> Void)? = nil) {
		persistentContainer.loadPersistentStores { (storeDescription, error) in
			guard error == nil else {
				fatalError(error!.localizedDescription)
			}
			completion?()
		}
	}
}
