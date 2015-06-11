//
//  PatientsTableViewController.swift
//  
//
//  Created by Brandon S Roberts on 6/9/15.
//
//

import UIKit

class PatientsTableViewController: UITableViewController {
    
    var patients:[(String, String)] = []
    var ids:[Int] = []
    var emails:[String] = []
    var database:COpaquePointer = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Patients"
        let dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        
        var query = "SELECT * FROM Patient"
        var statement:COpaquePointer = nil
        println("Selected")
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let patientID = Int(sqlite3_column_int(statement, 0))
                
                let patientDOB = sqlite3_column_text(statement, 1)
                let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                
                let patientFName = sqlite3_column_text(statement, 2)
                let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                
                let patientLName = sqlite3_column_text(statement, 3)
                let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                
                let patientEmail = sqlite3_column_text(statement, 4)
                let patientEmailString = String.fromCString(UnsafePointer<CChar>(patientEmail))
                
                let patientFullName = patientFNameString! + " " + patientLNameString!
                
                let tuple = (patientDOBString!, patientFullName)
                patients.append(tuple)
                ids.append(patientID)
                emails.append(patientEmailString!)
            }
        }

        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
        return patients.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("patientPageResultCell", forIndexPath: indexPath) as! UITableViewCell
        let (dob, patientName) = patients[indexPath.row]
        cell.textLabel!.text = patientName
        cell.detailTextLabel!.text = dob
        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
   
        let indexPath = self.tableView.indexPathForSelectedRow()
        let (dob, fullName) = patients[indexPath!.row]
        let pID = ids[indexPath!.row]
        let email = emails[indexPath!.row]
        let controller = segue.destinationViewController as! EditPatientViewController
        
        var fullNameArr = split(fullName) {$0 == " "}
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        
        controller.firstName = firstName
        controller.lastName = lastName
        controller.dob = dob
        controller.id = pID
        controller.email = email
        
        
    }

}
