//
//  TravelLocationsMapView.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 21/12/20.
//

import Foundation
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
  @IBOutlet weak var mapView: MKMapView!
	var photos: Photos?

	override func viewDidLoad() {
		var annotations = [MKPointAnnotation]()
		let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(19.357429),
																						longitude: CLLocationDegrees(-99.270616))
		
		let annotation = MKPointAnnotation()
		annotation.title = "Titulo"
		annotation.subtitle = "Subtitulo"
		annotation.coordinate = coordinate
		annotations.append(annotation)

		mapView.addAnnotations(annotations)

		VirtualTouristClient.getPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, page: 1) { (photoSearch, error) in
			guard let photoSearch = photoSearch else {
				print(String(reflecting: error))
				return
			}

			self.photos = photoSearch.photos

		}
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

	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
							 calloutAccessoryControlTapped control: UIControl) {
		print("tap")
		if control == view.rightCalloutAccessoryView {
			if let photoAlbumVC = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController")
					as? PhotoAlbumViewController {
				photoAlbumVC.coordinate = view.annotation?.coordinate
				photoAlbumVC.photos = self.photos
				self.navigationController!.pushViewController(photoAlbumVC, animated: true)
			}
		}
	}
}
