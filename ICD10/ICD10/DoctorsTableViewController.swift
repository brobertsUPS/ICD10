//
//  DoctorsTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/9/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class DoctorsTableViewController: UITableViewController {
    
    var doctors:[String] = []
    var ids:[Int] = []
    var database:COpaquePointer = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Doctors"
        checkDatabaseFileAndOpen()
        
        var doctorSearch = "SELECT * FROM Doctor"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return doctors.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("doctorsPageResultCell", forIndexPath: indexPath) as! UITableViewCell
        let doctorName = doctors[indexPath.row]
        cell.textLabel!.text = doctorName

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    //****************************************** Checking and opening Database ******************************************************************************
    
    /**
    *   Checks that the database file is on the device. If not, copies the database file to the device.
    *   Connects to the database after file is verified to be in the right spot.
    **/
    func checkDatabaseFileAndOpen() {
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
    }
    
    /**
    *   Gets the path of the database file on the device
    **/
    func dataFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("testDML.sqlite3") as String
    }
    
    /**
    *   Makes a connection to the database file located at the provided filePath
    **/
    func openDBPath(filePath:String) {
        var result = sqlite3_open(filePath, &database)
        
        if result != SQLITE_OK {
            sqlite3_close(database)
            println("Failed To Open Database")
            return
        }
    }


}
