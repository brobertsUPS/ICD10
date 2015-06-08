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
        let theFileManager = NSFileManager.defaultManager()
        let filePath = dataFilePath()
        if theFileManager.fileExistsAtPath(filePath) {
            // And then open the DB File
            openDBPath(filePath)
        }
        else {
            // Copy the file from the Bundle and write it to the Device:
            let pathToBundledDB = NSBundle.mainBundle().pathForResource("testDML", ofType: "sqlite3")
            let pathToDevice = dataFilePath()
            var error:NSError?

            if (theFileManager.copyItemAtPath(pathToBundledDB!, toPath:pathToDevice, error: nil)) {
                //get the database open
                openDBPath(pathToDevice)
            }
            else {
                // failure 
            }
        }

        println("LOADED")
        if objects.count == 0 {//get the root locations when we load up
            let query = "SELECT * FROM Condition_location cl WHERE NOT EXISTS (SELECT * FROM Sub_location sl WHERE cl.LID = sl.LID) ORDER BY location_name"
            
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    
                    let locationID = Int(sqlite3_column_int(statement, 0))
                    let locationName = sqlite3_column_text(statement, 1)
                    let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                    let tuple = (locationID,locationNameString!)
                    objects.append(tuple)
                }
            }
        }
    }
    
    func openDBPath(filePath:String) {
        var result = sqlite3_open(filePath, &database)
        
        if result != SQLITE_OK {
            sqlite3_close(database)
            println("Failed To Open Database")
            return
        }
    }
    
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues
    
    /**
    *   Fills an array with the sublocations of the selected item
    **/
    func findSubLocations(locationID:Int) -> [(Int,String)]{
        
        var sub_locations = [(Int,String)]()    //make new locations list for the sub_locations of the selected item
        
        //get get the sub locations and their names (does an exact match query 
        //to only natural join on one row from the sub_location table
        let query = "SELECT * FROM Condition_location NATURAL JOIN (SELECT * FROM Sub_location WHERE Parent_locationID=\(locationID)) ORDER BY location_name"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW { //for every sub location
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
        println(id)
        let newSubLocations = findSubLocations(id)
        
        if segue.identifier == "showCodes" {
            println("query prepared")
            println(id)
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            var statement:COpaquePointer = nil
            let query = "SELECT ICD10_code, description_text, ICD9_code from (SELECT * FROM condition_location NATURAL JOIN located_in WHERE LID = \(id))  NATURAL JOIN ICD10_condition NATURAL JOIN characterized_by NATURAL JOIN ICD9_condition"
            
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                
                if sqlite3_step(statement) == SQLITE_ROW { // if we got the row back successfully
                    println("Hit step")
                    let icd10Code = sqlite3_column_text(statement, 0)
                    let icd10CodeString = String.fromCString(UnsafePointer<CChar>(icd10Code))!
                    println(icd10CodeString)
                    controller.ICD10Text = icd10CodeString
                    println(controller.ICD10Text)
                    
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
            
            controller.detailItem = locationName
            
            controller.title = locationName
            controller.titleName = locationName
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

