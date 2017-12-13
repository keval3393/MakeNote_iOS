//
//  MapViewController.swift
//  Plain Ol' Notes
//
//  Created by Keval Makwana on 2017-04-22.
//  Copyright © 2017 Todd Perkins. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController  {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    var latitudes : [Double] = []
    var longitudes : [Double] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var allAnnotations = [MKPointAnnotation]()
        let annotation = MKPointAnnotation()
        var i = 0
        while (i < latitudes.count)
        {
            let myCoOrdinates = CLLocationCoordinate2DMake(latitudes[i], longitudes[i])
            annotation.coordinate = myCoOrdinates
            allAnnotations.append(annotation)
            i+=1
        }
        
        mapView.showAnnotations(allAnnotations, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goToNote(_ sender: Any) {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

}
