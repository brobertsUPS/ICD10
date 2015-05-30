//
//  MasterViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var objects = [(Int,String)]()
    var database:COpaquePointer = nil
    
    private let locationCell = "Location"
    private let symptomsCell = "Symptoms"
    private let favoritesCell = "Favorites"


    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.navigationItem.leftBarButtonItem = self.editButtonItem()

        //let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        //self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
        
        //get the database open
        
        let filePath = dataFilePath()
        println(filePath)
        var result = sqlite3_open(filePath, &database)
        
        if result != SQLITE_OK {
            sqlite3_close(database)
            println("Failed To Open Database")
            return
        }
        
        
        println("LOADED")
        if objects.count == 0 {//get the root locations when we load up
            let query = "SELECT * FROM Condition_location cl WHERE NOT EXISTS (SELECT * FROM Sub_location sl WHERE cl.LID = sl.LID)"
            
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    
                    let locationID = Int(sqlite3_column_int(statement, 0))
                    let locationName = sqlite3_column_text(statement, 1)
                    let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                    let tuple = (locationID,locationNameString!)
                    println(tuple)
                    objects.append(tuple)
                }
            }
        }
    }
    
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        println(documentsDirectory)
        return documentsDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    func insertNewObject(sender: AnyObject) {
        objects.insert(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
        self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
    }
    */
    // MARK: - Segues
    
    /**
    *   Fills an array with the sublocations of the selected item
    **/
    func findSubLocations(locationID:Int) -> [(Int,String)]{
        
        var sub_locations = [(Int,String)]()    //make new locations list for the sub_locations of the selected item
        
        //get get the sub locations and their names (does an exact match query 
        //to only natural join on one row from the sub_location table
        let query = "SELECT * FROM Condition_location NATURAL JOIN (SELECT * FROM Sub_location WHERE Parent_locationID=\(locationID));"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW { //for every sub location
                println("HIT")
                let locationID = Int(sqlite3_column_int(statement, 0))
                let locationName = sqlite3_column_text(statement, 1)
                let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                let tuple = (locationID,locationNameString!)
                sub_locations.append(tuple)
            }
        }
        return sub_locations
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let indexPath = self.tableView.indexPathForSelectedRow()
        let (id, locationName) = objects[indexPath!.row]
        let newSubLocations = findSubLocations(id)
        
        if segue.identifier == "showCodes" {
            
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            var statement:COpaquePointer = nil
            let query = "SELECT ICD10_code, description_text, ICD9_code FROM Condition_location NATURAL JOIN Located_in NATURAL JOIN ICD10_condition WHERE LID = \(id)"
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                
                if sqlite3_step(statement) == SQLITE_ROW { // if we got the row back successfully
                    
                    let icd10Code = sqlite3_column_text(statement, 0)
                    let icd10CodeString = String.fromCString(UnsafePointer<CChar>(icd10Code))!
                    println(icd10CodeString)
                    controller.ICD10Text = icd10CodeString
                    
                    let description = sqlite3_column_text(statement, 1)
                    let descriptionString = String.fromCString(UnsafePointer<CChar>(description))!
                    println(descriptionString)
                    controller.conditionDescriptionText = descriptionString
                    
                    let icd9Code = sqlite3_column_text(statement, 2)
                    let icd9CodeString = String.fromCString(UnsafePointer<CChar>(icd9Code))!
                    println(icd9CodeString)
                    controller.ICD9Text = icd9CodeString
                    
                }
            }
            
            //controller.detailItem = locationName
            
            controller.title = locationName
            
            //setup the codes for the location
            
            controller.navigationItem.leftItemsSupplementBackButton = true
        } else {
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! MasterViewController
            controller.objects = newSubLocations
            controller.title = locationName
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell

        let (id, location_name) = objects[indexPath.row]
        cell.textLabel!.text = location_name
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            objects.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let (id, locationName) = objects[indexPath.row]
        let newSubLocations = findSubLocations(id)
        
        if newSubLocations.count == 0 {
            self.performSegueWithIdentifier("showCodes", sender: self)
        } else {
            self.performSegueWithIdentifier("showLocations", sender: self)
        }
    }


}

