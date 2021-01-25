//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 21/12/20.
//

import Foundation
import MapKit
import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var newCollectionButton: UIButton!
	@IBOutlet weak var photoAlbumCollectionView: UICollectionView!
	@IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
	@IBOutlet weak var labelView: UIView!
	@IBOutlet weak var activityView: UIView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	var pin: Pin!
	var photoAlbum: Photos!
	var photos: [Photo] = []
	var dataController: DataController!

	var page = 1
	var totalPages = 0

	override func viewDidLoad() {
		mapView.isUserInteractionEnabled = false
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
		let region = MKCoordinateRegion(center: annotation.coordinate,
																		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

		mapView.addAnnotation(annotation)
		mapView.setRegion(region, animated: true)

		let space:CGFloat = 2.0
		let dimensionW = (view.frame.size.width - (2 * space)) / 3.0
		let dimensionH = (view.frame.size.height - space) / 7.0

		flowLayout.minimumInteritemSpacing = space
		flowLayout.minimumLineSpacing = space
		flowLayout.itemSize = CGSize(width: dimensionW, height: dimensionH)
	}

	override func viewWillAppear(_ animated: Bool) {
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
		if let result = try? dataController.viewContext.fetch(fetchRequest) {
			photos = result
		}

		if !photos.isEmpty {
			configNewCollectionButton(active: true)
		} else {
			if photoAlbum.total == "0" {
				configNewCollectionButton(active: false)
			} else {
				configNewCollectionButton(active: true)
				self.totalPages = photoAlbum.pages
			}
		}

		print("reloading")
		photoAlbumCollectionView.reloadData()
	}

	@IBAction func newCollection(_ sender: Any) {
		newCollectionButton.isEnabled = false
		activityView.isHidden = false
		activityIndicator.startAnimating()

		if self.page >= self.totalPages {
			self.page = 1
		} else {
			self.page = self.page + 1
		}

		VirtualTouristClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, page: self.page) { (photoSearch, error) in
			guard let photoSearch = photoSearch else {
				print(String(reflecting: error))
				return
			}

			self.photoAlbum = photoSearch.photos
			self.newCollectionButton.isEnabled = true
			self.activityView.isHidden = true
			self.activityIndicator.stopAnimating()
			self.photoAlbumCollectionView.reloadData()
		}
	}

	func configNewCollectionButton(active: Bool) {
		labelView.isHidden = active
		newCollectionButton.isEnabled = active
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

	// MARK: - UICollectionViewDataSource
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.photos.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell

		if !photos.isEmpty {
			if let data = photos[indexPath.row].data {
				cell.imageView?.image = UIImage(data: data)
				cell.setNeedsLayout()
			}
		}

		configNewCollectionButton(active: !photos.isEmpty)

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
		let photoToDelete = photos.remove(at: indexPath.row)
		dataController.viewContext.delete(photoToDelete)
		if dataController.viewContext.hasChanges {
			do {
				try dataController.viewContext.save()
			} catch {
				print(error.localizedDescription)
			}
		}

		photoAlbumCollectionView.reloadData()
	}
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
}
