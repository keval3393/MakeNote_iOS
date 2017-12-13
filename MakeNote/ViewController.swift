//
//  ViewController.swift
//  Plain Ol' Notes
//
//  Created by Todd Perkins on 12/6/16.
//  Copyright © 2016 Todd Perkins. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var table: UITableView!
    var data:[String] = []
    var databasePath = String()
    var recentlyAddedRowId: Int64 = 0
    var selectedNote = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Notes"
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNote))
        self.navigationItem.rightBarButtonItem = addButton
        self.navigationItem.leftBarButtonItem = editButtonItem
        load()
    }
    
    func addNote() {
        if (table.isEditing) {
            return
        }
        let noteName:String = "Note \(data.count + 1)"
        let noteDetail:String = "Enter note details.."
        
            //Inserting a note in database
            
            let notesDB = FMDatabase(path: databasePath as String)
            
            if (notesDB?.open())! {
                let insertSQL = "INSERT INTO Note (Name, Details, CreatedOn) VALUES ('\(noteName)', '\(noteDetail)', '\(getCurrentDate())')"
                
                let result = notesDB?.executeUpdate(insertSQL, withArgumentsIn: nil)
                
                if !result! {
                    print ("Error_4: \(notesDB?.lastErrorMessage())")
                } else {
                    print("Note inserted without images")
                }
                
                recentlyAddedRowId = (notesDB?.lastInsertRowId())!
                notesDB?.close()
            } else {
                print ("Error_5: \(notesDB?.lastErrorMessage())")
            }

        self.performSegue(withIdentifier: "detail", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
//        
//        cell.backgroundColor=UIColor.clear
//        let gradient : CAGradientLayer = CAGradientLayer()
//        let arrayColors:Array<AnyObject> = [UIColor.purple.cgColor, UIColor.white.cgColor]
//        gradient.colors=arrayColors
//        gradient.frame = cell.bounds
//        cell.layer.insertSublayer(gradient, at: UInt32(indexPath.row))
        cell.textLabel?.text = data[indexPath.row]
        
        return cell
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        table.setEditing(editing, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        //selectedNote = data[indexPath.row]
        
        let noteDB = FMDatabase(path: databasePath as String)
        
        if (noteDB?.open())! {
            let querySQL = "DELETE FROM NOTE WHERE Name = '\(data[indexPath.row])'"
            
            let result = noteDB?.executeUpdate(querySQL, withArgumentsIn: nil)
            if(result)! {
                print("Record Deleted")
            }
            noteDB?.close()
        } else {
            print ("Error_6: \(noteDB?.lastErrorMessage())")
        }
        data.remove(at: indexPath.row)
        table.deleteRows(at: [indexPath], with: .fade)
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        selectedNote = data[indexPath.row]
        recentlyAddedRowId = 0
        self.performSegue(withIdentifier: "detail", sender: nil)
    }
    
    func load() {
        
        let fileMgr = FileManager.default
        let dirPaths = fileMgr.urls(for: .documentDirectory, in: .userDomainMask)
        
        
        databasePath = dirPaths[0].appendingPathComponent("notes.db").path
        
        print("\(databasePath)")
        
        
        if !fileMgr.fileExists(atPath: databasePath as String) {
            
            let notesDB = FMDatabase(path: databasePath as String)
            
            if notesDB == nil {
                print ("Error_1: \(notesDB?.lastErrorMessage())")
            }
            
            if (notesDB?.open())! {
                let createNoteTable = "CREATE TABLE IF NOT EXISTS Note (NoteId INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, Details TEXT, CreatedOn TEXT)"
                
                let createImageTable = "CREATE TABLE IF NOT EXISTS Image (ImageId INTEGER PRIMARY KEY AUTOINCREMENT, Image BLOB, NoteId INTEGER, Latitude REAL, Longitude REAL)"
                
                if !(notesDB?.executeStatements(createNoteTable))! {
                    print ("Error_2: \(notesDB?.lastErrorMessage())")
                }
                
                if !(notesDB?.executeStatements(createImageTable))! {
                    print ("Error_3: \(notesDB?.lastErrorMessage())")
                }
                notesDB?.close()
            } else {
                print ("Error_4: \(notesDB?.lastErrorMessage())")
            }
        }
        else{
            let noteDB = FMDatabase(path: databasePath as String)
            
            if (noteDB?.open())! {
                let querySQL = "SELECT Name FROM Note"
                
                let results:FMResultSet? = noteDB?.executeQuery(querySQL, withArgumentsIn: nil)
                data = []
                while(results?.next() == true) {
                    data.append((results?.string(forColumn: "Name"))!)
                }
                noteDB?.close()
            } else {
                print ("Error_6: \(noteDB?.lastErrorMessage())")
            }
        }
        table.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCurrentDate() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let stringDate = dateFormatter.string(from: date)
        return stringDate
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "detail"){
            let nextViewController : DetailViewController = segue.destination as! DetailViewController
            nextViewController.databasePath = self.databasePath
            nextViewController.recentlyAddedRowId = self.recentlyAddedRowId
            nextViewController.selectedNoteName = self.selectedNote
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {    
        self.viewDidLoad()
    }


}

