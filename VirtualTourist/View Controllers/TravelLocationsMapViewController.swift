//
//  TravelLocationsMapView.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 21/12/20.
//

import Foundation
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

  @IBOutlet weak var mapView: MKMapView!
	var photos: Photos?
	var dataController: DataController!
	var pins: [Pin] = []
	
	override func viewDidLoad() {
		let longpressRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(self.handleLongPress))
		longpressRecognizer.minimumPressDuration = 1
		longpressRecognizer.delaysTouchesBegan = true
		longpressRecognizer.delegate = self
		mapView.addGestureRecognizer(longpressRecognizer)

		if let initialRegion = UserDefaults.standard.object(forKey: "initialRegion") as? [Double] {
			mapView.setRegion(setInitialRegion(initialRegion), animated: true)
		}

		let feechRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
		if let result = try? dataController.viewContext.fetch(feechRequest) {
			pins = result

			var annotations = [MKPointAnnotation]()
			for pin in pins {
				let annotation = MKPointAnnotation()
				annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
				annotation.title = pin.title
				annotations.append(annotation)
			}

			mapView.addAnnotations(annotations)
		}
  }

	override func viewWillDisappear(_ animated: Bool) {
		print("saving region to User Defaults")
		let initialRegion = [mapView.region.center.latitude, mapView.region.center.longitude, mapView.region.span.latitudeDelta, mapView.region.span.longitudeDelta]
		UserDefaults.standard.set(initialRegion, forKey: "initialRegion")
	}

	func setInitialRegion(_ initialRegion: [Double]) -> MKCoordinateRegion {
		let center = CLLocationCoordinate2D(latitude: initialRegion[0], longitude: initialRegion[1])
		let span = MKCoordinateSpan(latitudeDelta: initialRegion[2], longitudeDelta: initialRegion[3])
		return MKCoordinateRegion(center: center, span: span)
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

	@objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
		if gestureRecognizer.state != UIGestureRecognizer.State.ended {
			return
		}
		else if gestureRecognizer.state != UIGestureRecognizer.State.began {
			let mapCoordinate =  mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView)

			let annotation = MKPointAnnotation()
			annotation.coordinate = mapCoordinate

			lookUpCurrentLocation(location: CLLocation(latitude: mapCoordinate.latitude, longitude: mapCoordinate.longitude)) { (placeMark) in
				annotation.title = placeMark?.locality ?? "Unknown"
			}

			print(String(reflecting: annotation.title))
			print(String(reflecting: annotation.coordinate))

			mapView.addAnnotation(annotation)

			VirtualTouristClient.getPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, page: 1) { (photoSearch, error) in
				guard let photoSearch = photoSearch else {
					print(String(reflecting: error))
					return
				}

				self.photos = photoSearch.photos
			}
			print(mapView.region.span.latitudeDelta)
			print(mapView.region.span.longitudeDelta)
			print(mapView.center)
		}
	}

	func lookUpCurrentLocation(location: CLLocation, completionHandler: @escaping (CLPlacemark?) -> Void ) {
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, error) in
			if error == nil {
				let firstLocation = placemarks?[0]
				completionHandler(firstLocation)
			} else {
				completionHandler(nil)
			}
		})
	}
}
