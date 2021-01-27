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
	var dataController: DataController!
	var fetchedResultsController: NSFetchedResultsController<Photo>!

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
		setupFetchedResultsController()

//		if !photos.isEmpty {
//			configNewCollectionButton(active: true)
//		} else {
//			configNewCollectionButton(active: false)
//		}

	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		fetchedResultsController = nil
	}

	fileprivate func setupFetchedResultsController() {
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "data", ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedResultsController.delegate = self
		do {
			try fetchedResultsController.performFetch()
		} catch {
			fatalError("The fetch could not be performed \(error.localizedDescription)")
		}
	}

	@IBAction func newCollection(_ sender: Any) {
		newCollectionButton.isEnabled = false
		activityView.isHidden = false
		activityIndicator.startAnimating()

		self.page = self.page + 1
		if (self.page >= self.totalPages) && (self.totalPages > 0) {
			self.page = 1
		}

		VirtualTouristClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude, page: self.page) { (photoSearch, error) in
			guard let photoSearch = photoSearch else {
				print(String(reflecting: error))
				return
			}

			guard let total = Int(photoSearch.photos.total) else {
				return
			}

			self.activityView.isHidden = true
			self.activityIndicator.stopAnimating()

			self.totalPages = photoSearch.photos.pages

			if total > 0 {
				let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
				fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
				if let result = try? self.dataController.viewContext.fetch(fetchRequest) {
					for photo in result {
						self.dataController.viewContext.delete(photo)

						if self.dataController.viewContext.hasChanges {
							do {
								try self.dataController.viewContext.save()
							} catch {
								print(error.localizedDescription)
							}
						}
					}
				}
			}

			for photoImage in photoSearch.photos.photo {
				VirtualTouristClient.downloadImage(server: photoImage.server, id: photoImage.id, secret: photoImage.secret, format: "s", completion: { (data, error) in
					guard let data = data else {
						return
					}

					let photo = Photo(context: self.dataController.viewContext)
					photo.data = data
					photo.pin = self.pin
					self.dataController.viewContext.insert(photo)

					if self.dataController.viewContext.hasChanges {
						do {
							try self.dataController.viewContext.save()
						} catch {
							print(error.localizedDescription)
						}
					}
				})
			}

			self.newCollectionButton.isEnabled = true
			self.activityView.isHidden = true
			self.activityIndicator.stopAnimating()
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
		return fetchedResultsController.sections?[section].numberOfObjects ?? 0
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell

		let aPhoto = fetchedResultsController.object(at: indexPath)
		if let data = aPhoto.data {
			cell.imageView?.image = UIImage(data: data)
			cell.setNeedsLayout()
		}

		return cell
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
		let photoToDelete = fetchedResultsController.object(at: indexPath)
		dataController.viewContext.delete(photoToDelete)
		if dataController.viewContext.hasChanges {
			do {
				try dataController.viewContext.save()
			} catch {
				print(error.localizedDescription)
			}
		}

	}
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		print("controllerWillChangeContent")
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		print("controllerDidChangeContent")
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			photoAlbumCollectionView.insertItems(at: [newIndexPath!])
			break
		case .delete:
			photoAlbumCollectionView.deleteItems(at: [indexPath!])
			break
		default:
			break
		}
	}
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
}
