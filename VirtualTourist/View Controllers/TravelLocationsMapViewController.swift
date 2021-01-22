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
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var activityView: UIView!

	var dataController: DataController!
	var pins: [Pin] = []
	var photoAlbum: Photos?
	
	override func viewDidLoad() {
		activityView.isHidden = true
		activityIndicator.stopAnimating()

		let longpressRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(self.handleLongPress))
		longpressRecognizer.delaysTouchesBegan = true
		longpressRecognizer.delegate = self
		mapView.addGestureRecognizer(longpressRecognizer)

		if let initialRegion = UserDefaults.standard.object(forKey: "initialRegion") as? [Double] {
			mapView.setRegion(setInitialRegion(initialRegion), animated: true)
		}
  }

	override func viewWillAppear(_ animated: Bool) {
		loadPins()
	}

	func loadPins() {
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

				guard let latitude = view.annotation?.coordinate.latitude, let longitude = view.annotation?.coordinate.longitude else {
					return
				}

				let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
				let latitudePredicate = NSPredicate(format: "latitude == %@", String(latitude))
				let longitudePredicate = NSPredicate(format: "longitude == %@", String(longitude))
				let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latitudePredicate, longitudePredicate])

				fetchRequest.predicate = predicate
				if let result = try? dataController.viewContext.fetch(fetchRequest) {
					if !result.isEmpty {
						photoAlbumVC.pin = result[0]
						photoAlbumVC.photoAlbum = self.photoAlbum
					}
				}

				photoAlbumVC.dataController = self.dataController
				self.navigationController!.pushViewController(photoAlbumVC, animated: true)
			}
		}
	}

	@objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
		if gestureRecognizer.state != UIGestureRecognizer.State.ended {
			return
		}
		else if gestureRecognizer.state != UIGestureRecognizer.State.began {
			activityView.isHidden = false
			activityIndicator.startAnimating()

			let mapCoordinate =  mapView.convert(gestureRecognizer.location(in: mapView), toCoordinateFrom: mapView)

			let annotation = MKPointAnnotation()
			annotation.coordinate = mapCoordinate

			lookUpCurrentLocation(location: CLLocation(latitude: mapCoordinate.latitude, longitude: mapCoordinate.longitude)) { (placeMark) in
				annotation.title = placeMark?.locality ?? "Unknown"
				self.mapView.addAnnotation(annotation)
				self.savePin(annotation)
			}

			VirtualTouristClient.getPhotos(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, page: 1) { (photoSearch, error) in
				guard let photoSearch = photoSearch else {
					print(String(reflecting: error))
					return
				}

				self.photoAlbum = photoSearch.photos
				self.savePhotos(photoSearch.photos)

				self.activityView.isHidden = true
				self.activityIndicator.stopAnimating()
			}
		}
	}

	func savePin(_ annotation: MKPointAnnotation) {
		let pin = Pin(context: dataController.viewContext)
		pin.latitude = annotation.coordinate.latitude
		pin.longitude = annotation.coordinate.longitude
		pin.title = annotation.title!

		if dataController.viewContext.hasChanges {
			print("saving pin")
			do {
				try dataController.viewContext.save()
				print("pin saved")
			} catch {
				print(error.localizedDescription)
			}
		}
	}

	func savePhotos(_ photos: Photos) {
		for photoImage in photos.photo {
			VirtualTouristClient.downloadImage(server: photoImage.server, id: photoImage.id, secret: photoImage.secret, format: "s", completion: { (data, error) in
				guard let data = data else {
					return
				}

				let photo = Photo(context: self.dataController.viewContext)
				photo.data = data

				if self.dataController.viewContext.hasChanges {
					print("saving photo")
					do {
						try self.dataController.viewContext.save()
						print("photo saved")
					} catch {
						print(error.localizedDescription)
					}
				}

			})
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
