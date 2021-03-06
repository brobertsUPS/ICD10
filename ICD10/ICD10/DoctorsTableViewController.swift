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
    var emails:[String] = []
    var types:[Int] = []
    
    var dbManager:DatabaseManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Doctors"
        dbManager = DatabaseManager()
        doctors = []
        ids = []
        emails = []
        types = []
        findDoctors()
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        doctors = []
        ids = []
        emails = []
        types = []
        findDoctors()
        self.tableView.reloadData()
    }
    
    func findDoctors() {
        dbManager.checkDatabaseFileAndOpen()
        let doctorSearch = "SELECT * FROM Doctor"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let doctorID = Int(sqlite3_column_int(statement, 0))
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorEmail = sqlite3_column_text(statement, 3)
                let doctorEmailString = String.fromCString(UnsafePointer<CChar>(doctorEmail))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                
                let type = Int(sqlite3_column_int(statement, 4))
                
                doctors.append(doctorFullName)
                ids.append(doctorID)
                emails.append(doctorEmailString!)
                types.append(type)
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
    }



    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return doctors.count }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("doctorsPageResultCell", forIndexPath: indexPath) 
        let doctorName = doctors[indexPath.row]
        cell.textLabel!.text = doctorName
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            _ = doctors[indexPath.row]
            doctors.removeAtIndex(indexPath.row)
            dbManager.checkDatabaseFileAndOpen()
            dbManager.removeDoctorFromDatabase(ids[indexPath.row])
            dbManager.closeDB()
            
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func addNewDoctor(sender: UIButton) {
        self.performSegueWithIdentifier("addDoctor", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "addDoctor"{
            let controller = segue.destinationViewController as! EditDoctorViewController
            controller.newDoctor = true
        }else{
            
            let indexPath = self.tableView.indexPathForSelectedRow
            let fullName = doctors[indexPath!.row]
            let dID = ids[indexPath!.row]
            let email = emails[indexPath!.row]
            let type = types[indexPath!.row]
            
            var fullNameArr = fullName.componentsSeparatedByString(" ")
            let firstName: String = fullNameArr[0]
            let lastName: String =  fullNameArr[1]
            
            let controller = segue.destinationViewController as! EditDoctorViewController
            
            controller.firstName = firstName
            controller.lastName = lastName
            controller.email = email
            controller.id = dID
            controller.docType = type
        }
    }
    
    //MARK: - TextBox Changes

    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    @IBAction func backgroundTap(sender: UIControl){
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    

}
