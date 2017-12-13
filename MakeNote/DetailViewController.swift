//
//  DetailViewController.swift
//  Plain Ol' Notes
//
//  Created by Todd Perkins on 12/6/16.
//  Copyright © 2016 Todd Perkins. All rights reserved.
//

import UIKit
import CoreLocation

class DetailViewController: UIViewController, UINavigationControllerDelegate,UIImagePickerControllerDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var noteNameTextField: UITextField!
    
    
    var imagePicker: UIImagePickerController!
    
    var databasePath = String()
    var recentlyAddedRowId: Int64 = 0
    var selectedNoteName = String()

    let locationManager = CLLocationManager()
    var locationValue = CLLocationCoordinate2D()
    
    var longitude : [Double] = []
    var latitude : [Double] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let noteDB = FMDatabase(path: databasePath as String)
        
        if (noteDB?.open())!
        {
            var querySQL = String()
            if(recentlyAddedRowId == 0){
                querySQL = "SELECT * FROM NOTE WHERE Name = '\(selectedNoteName)'"
            }
            else{
                querySQL = "SELECT * FROM NOTE WHERE NoteId = '\(recentlyAddedRowId)'"
            }
            
                let results:FMResultSet? = noteDB?.executeQuery(querySQL, withArgumentsIn: nil)
            
                if results?.next() == true {
                    recentlyAddedRowId = Int64((results?.int(forColumn: "NoteId"))!)
                    noteNameTextField.text = results?.string(forColumn: "Name")
                    textView.text = results?.string(forColumn: "Details")
                } else {
                    print("No DATA in NOTE")
                }
            
            // Get the IMages from database
            let getImageSQL = "SELECT * from Image where NoteId = '\(recentlyAddedRowId)'"
            let result2: FMResultSet? = noteDB?.executeQuery(getImageSQL, withArgumentsIn: nil)
            
            while( result2?.next() == true ) {
                let imageString = result2?.string(forColumn: "Image")
                longitude.append(Double((result2?.string(forColumn: "Longitude"))!)!)
                latitude.append(Double((result2?.string(forColumn: "Latitude"))!)!)
                let imageData = Data(base64Encoded: imageString! as String, options: NSData.Base64DecodingOptions())
                let selectedImage = UIImage(data: imageData! as Data);
                
                let imageSize = CGSize(width: 350, height: 200)
                UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0  )
                selectedImage?.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize))
                let scaledImage = UIGraphicsGetImageFromCurrentImageContext()

                
                let textAttachment = NSTextAttachment()
                textAttachment.image = scaledImage
                let attrString = NSAttributedString(attachment: textAttachment)
                textView.textStorage.insert(attrString, at: textView.selectedRange.location)
                textView.selectedRange = NSMakeRange(textView.text.characters.count, 0)
                
            }
                noteDB?.close()
            } else {
                print ("Error_6: \(noteDB?.lastErrorMessage())")
            }
        
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func takePhoto(_ sender: Any) {
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
                imagePicker =  UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
        
                present(imagePicker, animated: true, completion: nil)
            }
            else{
                print("Camera is not availabel")
            }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("Photo taken")
        let chosenImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let imageSize = CGSize(width: 350, height: 200)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0.0  )
        chosenImage.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: imageSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        
        let data = UIImagePNGRepresentation(scaledImage!)
        let base64String = data!.base64EncodedString(options: NSData.Base64EncodingOptions.endLineWithLineFeed) as NSString!
        // Changing cursor position to the end
        //let endPosition : UITextPosition = textView.endOfDocument
        //textView.selectedRange = NSMakeRange(endPosition, endPosition)
        
        let range = textView.selectedRange
        let textAttachment = NSTextAttachment()
        textAttachment.image = scaledImage
        let attrString = NSAttributedString(attachment: textAttachment)
        textView.textStorage.insert(attrString, at: textView.selectedRange.location)
        
        latitude.append(locationValue.latitude)
        longitude.append(locationValue.longitude)
        textView.selectedRange = range
        
        //let chosenImageView = UIImageView(image: chosenImage)
        //chosenImageView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        //let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: chosenImageView.frame.width, height: chosenImageView.frame.height))
        //textView.textContainer.exclusionPaths = [path]
        //textView.addSubview(chosenImageView)
        
        
        // INserting image into the database
        let notesDB = FMDatabase(path: databasePath as String)
        
        if (notesDB?.open())! {
            let insertSQL = "INSERT INTO Image (Image, NoteId, Latitude, Longitude) VALUES ('\(base64String!)', '\(recentlyAddedRowId)', '\(locationValue.latitude)', '\(locationValue.longitude)')"
            
            let result = notesDB?.executeUpdate(insertSQL, withArgumentsIn: nil)
            
            if !result! {
                print ("Error_4: \(notesDB?.lastErrorMessage())")
            } else {
                print("Image inserted ")
            }
            notesDB?.close()
        } else {
            print ("Error_5: \(notesDB?.lastErrorMessage())")
        }

        
        dismiss(animated: true, completion: nil)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationValue  = manager.location!.coordinate
    }
    
    
    @IBAction func goToNotes(_ sender: Any) {
        
        //Update Note into Database
        let notesDB = FMDatabase(path: databasePath as String)
        
        if (notesDB?.open())! {
            let updateSQL = "UPDATE NOTE SET Name='\(noteNameTextField.text!)' , Details='\(textView.text!)' where NoteId=\(recentlyAddedRowId)"
            
            let result = notesDB?.executeUpdate(updateSQL, withArgumentsIn: nil)
            
            if !result! {
                print ("Error_4: \(notesDB?.lastErrorMessage())")
            } else {
                print("Note Updated without images")
            }
            
            notesDB?.close()
        } else {
            print ("Error_5: \(notesDB?.lastErrorMessage())")
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func showMap(_ sender: Any) {
        performSegue(withIdentifier: "mapSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "mapSegue"){
            let nextViewController : MapViewController = segue.destination as! MapViewController
            nextViewController.latitudes = self.latitude
            nextViewController.longitudes = self.longitude
        }

    }
    
        
}
