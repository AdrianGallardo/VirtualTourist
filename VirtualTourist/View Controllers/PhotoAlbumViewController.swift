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
	var blockOperations = [BlockOperation]()

	var saveObserverToken: Any?

	var page = 1
	var totalPages = 0

//	MARK: - Lifecycle
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

		addSaveNotificationObserver()
	}

	override func viewWillAppear(_ animated: Bool) {
		setupFetchedResultsController()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		fetchedResultsController = nil
	}

	deinit {
		removeSaveNotificationObserver()
	}

//	MARK: - Setup FetchResultsController
	fileprivate func setupFetchedResultsController() {
		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedResultsController.delegate = self
		do {
			try fetchedResultsController.performFetch()

			if let numberOfPhotos = fetchedResultsController.sections?[0].numberOfObjects {
				print("number of photos \(numberOfPhotos)")
				labelView.isHidden = numberOfPhotos > 0
				newCollectionButton.isEnabled = numberOfPhotos > 0
			}

		} catch {
			fatalError("The fetch could not be performed \(error.localizedDescription)")
		}
	}

//	MARK: - New Collection Action
	fileprivate func showActivityIndicator(_ active: Bool) {
		newCollectionButton.isEnabled = !active
		activityView.isHidden = !active
		if active {
			activityIndicator.startAnimating()
		} else {
			activityIndicator.stopAnimating()
		}
	}

	@IBAction func newCollection(_ sender: Any) {
		let backgroundContext: NSManagedObjectContext! = dataController.backgroundContext

		showActivityIndicator(true)

		self.page = self.page + 1
		// If asked page is greater than the totalPages, reset the variable and ask for page 1
		if (self.page >= self.totalPages) && (self.totalPages > 0) {
			self.page = 1
		}

		let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
		if let result = try? dataController.viewContext.fetch(fetchRequest) {
			for photo in result {
				dataController.viewContext.delete(photo)
				if dataController.viewContext.hasChanges {
					do {
						try dataController.viewContext.save()
					} catch {
						print(error.localizedDescription)
					}
				}
			}
		}

		let pinID = pin.objectID
		backgroundContext.perform {
			let backgroundPin = backgroundContext.object(with: pinID) as! Pin

			VirtualTouristClient.getPhotos(latitude: backgroundPin.latitude, longitude: backgroundPin.longitude, page: self.page) { (photoSearch, error) in
				guard let photoSearch = photoSearch else {
					print(String(reflecting: error))
					return
				}

				self.totalPages = photoSearch.photos.pages

				print(photoSearch.photos.photo.count)
				for photoImage in photoSearch.photos.photo {
					VirtualTouristClient.downloadImage(server: photoImage.server, id: photoImage.id, secret: photoImage.secret, format: "s", completion: { (data, error) in
						guard let data = data else {
							return
						}

						let photo = Photo(context: backgroundContext)
						photo.data = data
						photo.pin = backgroundPin

						if backgroundContext.hasChanges {
							do {
								try backgroundContext.save()
							} catch {
								print(error.localizedDescription)
							}
						}
					})
				}
			}

			DispatchQueue.main.async {
				self.showActivityIndicator(false)
			}

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

// MARK: - NSFetchedResultsControllerDelegate
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		blockOperations = [BlockOperation]()
	}

	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		photoAlbumCollectionView.performBatchUpdates {
			for operation in self.blockOperations {
				operation.start()
			}
		} completion: { (completed) in	print("Operation finished")}
	}

	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			print("insert")
			blockOperations.append(BlockOperation(block: {
				self.photoAlbumCollectionView.insertItems(at: [newIndexPath!])
			}))
			break
		case .delete:
			print("delete")
			blockOperations.append(BlockOperation(block: {
				self.photoAlbumCollectionView.deleteItems(at: [indexPath!])
			}))
			break
		default:
			break
		}
	}
}
// MARK: - Observe notifications
extension PhotoAlbumViewController {
	func addSaveNotificationObserver() {
		removeSaveNotificationObserver()
		saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController.viewContext, queue: nil, using: handleSaveNotification(notification:))
	}

	func removeSaveNotificationObserver() {
		if let token = saveObserverToken {
			NotificationCenter.default.removeObserver(token)
		}
	}

	fileprivate func reloadPhotoAlbum() {
		photoAlbumCollectionView.reloadData()
	}

	func handleSaveNotification(notification: Notification) {
		DispatchQueue.main.async {
			self.reloadPhotoAlbum()
		}
	}
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var imageView: UIImageView!
}
