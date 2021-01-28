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

	var backgroundContext: NSManagedObjectContext!

	init(modelName: String) {
		persistentContainer = NSPersistentContainer(name: modelName)
	}

	func configureContext() {
		backgroundContext = persistentContainer.newBackgroundContext()

		viewContext.automaticallyMergesChangesFromParent = true
		backgroundContext.automaticallyMergesChangesFromParent = true

		backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
	}

	func load(completion: (() -> Void)? = nil) {
		persistentContainer.loadPersistentStores { (storeDescription, error) in
			guard error == nil else {
				fatalError(error!.localizedDescription)
			}
			self.configureContext()
			completion?()
		}
	}
}
