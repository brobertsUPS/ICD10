//
//  PatientsTableViewController.swift
//  A class to list all of the patients in the database
//
//  Created by Brandon S Roberts on 6/9/15.
//
//

import UIKit

class PatientsTableViewController: UITableViewController {
    
    var patients:[(dob:String, name:String)] = []    //the patients
    var ids:[Int] = []                              //The ids in the database (used in selection)
    var emails:[String] = []
    var dbManager:DatabaseManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Patients"
        dbManager = DatabaseManager()

        patients = []
        ids = []
        emails = []
        findPatients()
        self.tableView.reloadData()
    }
    override func viewWillAppear(animated: Bool) {
        patients = []
        ids = []
        emails = []

        findPatients()
        
        self.tableView.reloadData()
    }
    
    @IBAction func AddNewPatient(sender: UIButton){
        self.performSegueWithIdentifier("addPatient", sender: self)
    }
    
    
    func findPatients(){
        dbManager.checkDatabaseFileAndOpen()
        var query = "SELECT * FROM Patient"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
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
                
                patients.append(dob:patientDOBString!,name:patientFullName)
                ids.append(patientID)
                emails.append(patientEmailString!)
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
    }
    
    @IBAction func refresh(sender: UIBarButtonItem) {
        self.tableView.reloadData()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return patients.count }

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
        
        if segue.identifier == "addPatient" {
            let controller = segue.destinationViewController as! EditPatientViewController
            controller.newPatient = true
        }else{
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
}
