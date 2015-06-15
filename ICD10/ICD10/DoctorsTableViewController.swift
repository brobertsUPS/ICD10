//
//  DoctorsTableViewController.swift
//  A table view for all of the doctors in the database
//
//  Created by Brandon S Roberts on 6/9/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class DoctorsTableViewController: UITableViewController {
    
    var doctors:[String] = []
    var ids:[Int] = []
    var database:COpaquePointer = nil
    var emails:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Doctors"
        var dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        doctors = []
        ids = []
        emails = []
        findDoctors()
        self.tableView.reloadData()
    }
    override func viewWillAppear(animated: Bool) {
        doctors = []
        ids = []
        emails = []
        findDoctors()
        self.tableView.reloadData()
    }

    
    @IBAction func addNewDoctor(sender: UIButton) {
        self.performSegueWithIdentifier("addDoctor", sender: self)
    }
    
    func findDoctors() {
        var doctorSearch = "SELECT * FROM Doctor"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let doctorID = Int(sqlite3_column_int(statement, 0))
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorEmail = sqlite3_column_text(statement, 3)
                let doctorEmailString = String.fromCString(UnsafePointer<CChar>(doctorEmail))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
                ids.append(doctorID)
                emails.append(doctorEmailString!)
            }
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return doctors.count }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("doctorsPageResultCell", forIndexPath: indexPath) as! UITableViewCell
        let doctorName = doctors[indexPath.row]
        cell.textLabel!.text = doctorName
        return cell
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "addDoctor"{
            let controller = segue.destinationViewController as! EditDoctorViewController
            controller.newDoctor = true
        }else{
            
            let indexPath = self.tableView.indexPathForSelectedRow()
            let fullName = doctors[indexPath!.row]
            let dID = ids[indexPath!.row]
            let email = emails[indexPath!.row]
            
            var fullNameArr = split(fullName) {$0 == " "}
            var firstName: String = fullNameArr[0]
            var lastName: String =  fullNameArr[1]
            
            let controller = segue.destinationViewController as! EditDoctorViewController
            
            controller.firstName = firstName
            controller.lastName = lastName
            controller.email = email
            controller.id = dID
        }
        sqlite3_close(database)
    }
    
    /**
    *   Registers clicking return and resigns the keyboard
    **/
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    /**
    *   Registers clicking the background and resigns any responder that could possibly be up
    **/
    @IBAction func backgroundTap(sender: UIControl){
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    

}