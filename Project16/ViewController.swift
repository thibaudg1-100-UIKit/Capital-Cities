//
//  ViewController.swift
//  Project16
//
//  Created by RqwerKnot on 29/10/2022.
//

import UIKit
import MapKit
import Contacts

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet var mapView: MKMapView!
    
    var searchResults = [MKMapItem]()
    var resultAnnotations = [MKPointAnnotation]()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // add key in info.plistas well

        
        title = "Capital Cities"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(changeMapType))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchPlace))
        
        let london = Capital(title: "London", coordinate: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), info: "Home to the 2012 Summer Olympics.")
        let oslo = Capital(title: "Oslo", coordinate: CLLocationCoordinate2D(latitude: 59.95, longitude: 10.75), info: "Founded over a thousand years ago.")
        let paris = Capital(title: "Paris", coordinate: CLLocationCoordinate2D(latitude: 48.8567, longitude: 2.3508), info: "Often called the City of Light.")
        let rome = Capital(title: "Rome", coordinate: CLLocationCoordinate2D(latitude: 41.9, longitude: 12.5), info: "Has a whole country inside it.")
        let washington = Capital(title: "Washington DC", coordinate: CLLocationCoordinate2D(latitude: 38.895111, longitude: -77.036667), info: "Named after George himself.")
        let riga = Capital(title: "Riga", coordinate: CLLocationCoordinate2D(latitude: 56.948889, longitude: 24.106389), info: "Heart of the Baltics")
        
        mapView.addAnnotation(london)
        // or several at once:
        mapView.addAnnotations([oslo, paris, rome, washington, riga])
        
        
        // Adding a Placemark to the map:
        let coords = CLLocationCoordinate2DMake(51.5083, -0.1384)
        let address = [CNPostalAddressStreetKey: "181 Piccadilly, St. James's", CNPostalAddressCityKey: "London", CNPostalAddressPostalCodeKey: "W1A 1ER", CNPostalAddressISOCountryCodeKey: "GB"]
        
        let place = MKPlacemark(coordinate: coords, addressDictionary: address)
        
        mapView.addAnnotation(place)
        
        // Adding directions to the map:
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 56.948889, longitude: 24.106389), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 59.437222, longitude: 24.745278), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            for route in unwrappedResponse.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is Capital else { return nil }
        
        let identifier = "Capital"
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            annotationView?.pinTintColor = .systemYellow
            annotationView?.canShowCallout = true
            annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let capital = view.annotation as? Capital {
            let title = capital.title
            let message = capital.info
            
            
            
            if let vc = storyboard?.instantiateViewController(withIdentifier: "WebView") as? WebViewController {
                vc.city = title
                
                navigationController?.pushViewController(vc, animated: true)
                
            } else {
                let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
                
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                
                present(ac, animated: true)
            }
        }
    }
    
    @objc func changeMapType() {
        let ac = UIAlertController(title: "Choose a map type", message: nil, preferredStyle: .actionSheet)
        
        ac.addAction(UIAlertAction(title: "Standard", style: .default, handler: { [weak self] _ in
            self?.mapView.mapType = .standard
        }))
        ac.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { [weak self] _ in
            self?.mapView.mapType = .hybridFlyover
        }))
        ac.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { [weak self] _ in
            self?.mapView.mapType = .satelliteFlyover
        }))
        
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        ac.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(ac, animated: true)
    }
    
    @objc func searchPlace() {
        let ac = UIAlertController(title: "Look up a place", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let search = UIAlertAction(title: "Search", style: .default) { [weak self, weak ac] _ in
            guard let query = ac?.textFields?[0].text else { return }
            
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = query
            if let region = self?.mapView.region { searchRequest.region = region}
            
            let search = MKLocalSearch(request: searchRequest)
            
            search.start { response, error in
                guard let response = response else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error").")
                    return
                }
                
                self?.searchResults = response.mapItems
                
                self?.showResults()
            }
        }
        
        ac.addAction(search)
        
        present(ac, animated: true)
    }
    
    func showResults() {
        mapView.removeAnnotations(resultAnnotations)
        
        for result in searchResults {
            print(result.name ?? "No name for this item")
            
            let newAnnotation = MKPointAnnotation()
            newAnnotation.coordinate = result.placemark.coordinate
            newAnnotation.title = result.name ?? "Unknown"
            
            resultAnnotations.append(newAnnotation)
            mapView.addAnnotation(newAnnotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let userLocation = MKPointAnnotation()
            userLocation.coordinate = location.coordinate
            userLocation.title = "You"
            
            mapView.addAnnotation(userLocation)
            
            print("Your location: \(location)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // start location services only once you know for sure that your app is authorized to use such services
        if manager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
}

