//
//  PhotoAlbumView.swift
//  VirtualTourist
//
//  Created by Adrian Gallardo on 21/12/20.
//

import Foundation
import MapKit
import UIKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var newCollectionButton: UIButton!
	@IBOutlet weak var photoAlbumCollectionView: UICollectionView!
	@IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
	@IBOutlet weak var labelView: UIView!
	@IBOutlet weak var activityView: UIView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!

	var coordinate: CLLocationCoordinate2D?
	var photos: Photos?
	var page = 1
	var totalPages = 0

	override func viewDidLoad() {
		mapView.isUserInteractionEnabled = false
		
		let annotation = MKPointAnnotation()
		annotation.coordinate = coordinate!
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

		if let total = photos?.total, let pages = photos?.pages {
			if total == "0" {
				labelView.isHidden = false
				newCollectionButton.isEnabled = false
			} else {
				labelView.isHidden = true
				newCollectionButton.isEnabled = true
				self.totalPages = pages
			}
		}

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
		guard let latitude = coordinate?.latitude, let longitude = coordinate?.longitude else {
			return
		}
		VirtualTouristClient.getPhotos(latitude: latitude, longitude: longitude, page: self.page) { (photoSearch, error) in
			guard let photoSearch = photoSearch else {
				print(String(reflecting: error))
				return
			}

			self.photos = photoSearch.photos
			self.newCollectionButton.isEnabled = true
			self.activityView.isHidden = true
			self.activityIndicator.stopAnimating()
			self.photoAlbumCollectionView.reloadData()
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

	// MARK: - UICollectionViewDataSource
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.photos?.photo.count ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let imageSize = "s"
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
		let photoImage = photos?.photo[indexPath.row]

		if let photoImage = photoImage {
			VirtualTouristClient.downloadImage(server: photoImage.server, id: photoImage.id, secret: photoImage.secret, format: imageSize, completion: { (data, error) in
				guard let data = data else {
					return
				}

				let image = UIImage(data: data)
				cell.imageView?.image = image
				cell.setNeedsLayout()
			})
		}
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {

	}
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
}
