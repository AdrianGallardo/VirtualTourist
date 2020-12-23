//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 21/12/20.
//

import Foundation
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
	@IBOutlet weak var mapView: MKMapView!
	var coordinates: CLLocationCoordinate2D?
}
