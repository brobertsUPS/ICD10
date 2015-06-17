//
//  BillDatesTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/15/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillDatesTableViewController: UITableViewController {

    var billDates:[String] = []
    var dbManager:DatabaseManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        dbManager.checkDatabaseFileAndOpen()
        let dateQuery = "SELECT date FROM Appointment GROUP BY date"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, dateQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var date = sqlite3_column_text(statement, 0)
                var dateString = String.fromCString(UnsafePointer<CChar>(date))
                billDates.append(dateString!)                                      //if we got into this step the dateString is good
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showBillsForDate" {
            dbManager.checkDatabaseFileAndOpen()
            
            var patientBills:[(id:Int, dob:String, name:String)] = []
            var IDs:[(aptID:Int, dID:Int, placeID:Int, roomID:Int)] = []
            
            let indexPath = self.tableView.indexPathForSelectedRow()
            let date = billDates[indexPath!.row]
            
            let billsQuery = "SELECT pID,date_of_birth, f_name, l_name, aptID, dID, placeID, roomID FROM Patient NATURAL JOIN Appointment WHERE date='\(date)'"
            println("bills query ran")
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(dbManager.db, billsQuery, -1, &statement, nil) == SQLITE_OK {
                println("bills query succeeded")
                while sqlite3_step(statement) == SQLITE_ROW {
                    
                    let patientID = Int(sqlite3_column_int(statement, 0))
                    
                    let patientDOB = sqlite3_column_text(statement, 1)
                    let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                    
                    let patientFName = sqlite3_column_text(statement, 2)
                    let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                    
                    let patientLName = sqlite3_column_text(statement, 3)
                    let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                    
                    let aptID = Int(sqlite3_column_int(statement, 4))
                    let dID = Int(sqlite3_column_int(statement, 5))
                    let placeID = Int(sqlite3_column_int(statement, 6))
                    let roomID = Int(sqlite3_column_int(statement, 7))
                    
                    let patientFullName = patientFNameString! + " " + patientLNameString!
                    
                    patientBills.append(id: patientID,dob: patientDOBString!, name: patientFullName)
                    IDs.append(aptID:aptID,dID:dID, placeID:placeID, roomID:roomID )

                }
            }
            let controller = segue.destinationViewController as! BillsTableViewController
            println(patientBills)
            controller.patientsInfo = patientBills
            controller.IDs = IDs
            sqlite3_finalize(statement)
        }
        
        dbManager.closeDB()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return billDates.count }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billDateCell", forIndexPath: indexPath) as! UITableViewCell
        let date = billDates[indexPath.row]
        cell.textLabel!.text = date
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showBillsForDate", sender: self)
    }
    

}
