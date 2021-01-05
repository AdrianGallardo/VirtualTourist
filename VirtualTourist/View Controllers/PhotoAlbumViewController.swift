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
	var coordinate: CLLocationCoordinate2D?

	override func viewDidLoad() {
		self.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(19.312551),
																							longitude: CLLocationDegrees(-99.077818))

		let annotation = MKPointAnnotation()
		annotation.title = "Titulo"
		annotation.subtitle = "Subtitulo"
		annotation.coordinate = coordinate!
		let region = MKCoordinateRegion(center: annotation.coordinate,
																		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

		mapView.addAnnotation(annotation)
		mapView.setRegion(region, animated: true)
		
	}

	// MARK: - MKMapViewDelegate
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		let reuseId = "pin"
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
			pinView!.canShowCallout = true
			pinView!.pinTintColor = .red
			pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
		} else {
			pinView!.annotation = annotation
		}

		return pinView
	}
}
