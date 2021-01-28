//
//  Photo+Extension.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 28/01/21.
//

import Foundation
import CoreData

extension Photo {
	public override func awakeFromInsert() {
		super.awakeFromInsert()
		creationDate = Date()
	}
}
