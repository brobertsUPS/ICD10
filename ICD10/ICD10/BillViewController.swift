//
//  BillViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/4/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UISplitViewControllerDelegate {
    
    var database:COpaquePointer = nil
    var searchTableViewController: SearchTableViewController? = nil
    
    var visitDate:String = ""
    var patient:String = ""
    var referringPhys:String = ""
    var site:String = ""
    var room:String = ""
    var cpt:String = ""
    var mc:String = ""
    var pc:String = ""
    var ICD10:[String] = []
    var ICD9:[String] = []
    
    @IBOutlet weak var patientTextField: UITextField!
    @IBOutlet weak var patientDOBTextField: UITextField!
    
    @IBOutlet weak var doctorTextField: UITextField!
    
    
    
    @IBAction func clickedInTextBox(sender: UITextField) {
        if sender == patientTextField {
            println("Same")
            self.performSegueWithIdentifier("patientSearchPopover", sender: self)
        }
    }

    /**
    ** Updates the table view in the popup for any patients that match the patient input
    **/
    @IBAction func userChangedPatientSearch(sender: UITextField) {
        
        let patients = patientSearch()                                  //retrieve any patients that match the input
        if let patientSearchViewController = searchTableViewController {//only update the view if we have selected it
            patientSearchViewController.searchResults = patients
            patientSearchViewController.tableView.reloadData()                        //update the list in the popup
        }
    }
    
    /**
    *   Open the database and adds a notification ovserver to this view controller. 
    *   Observer listens for a click on the patient popup
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        checkDatabaseFileAndOpen()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePatient:",name:"loadPatient", object: nil)
    }
    
    /**
    *   Updates the patient text field with selected data when the user selects a row in the patient popup window
    *   Closes the popup after updating the patientTextField
    **/
    func updatePatient(notification: NSNotification){
        //load data here
        let tuple = searchTableViewController?.selectedPatient
        var (dob,name) = tuple!
        self.patientTextField.text = name
        self.patientDOBTextField.text = dob
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    /**
    *   Navigates to the correct popup the user clicked into
    **/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "patientSearchPopover" {
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            searchTableViewController = popoverViewController               //set our view controller as the patientSearchPopover
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        
        /*
        if segue.identifier == "beginSearch" {
            let splitViewController = segue.destinationViewController as! UISplitViewController
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
            navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
            splitViewController.delegate = self
        }
        */
    }
    
    /**
    *   Searches for any patients matching the text that was input into the patient textfield.
    *   @return patients, a list of patients matching the user input
    **/
    func patientSearch() ->[(String, String)] {
        
        var patients:[(String, String)] = []
        
        let inputPatient = patientTextField.text;   //get the typed information
        println(inputPatient)
        let patientSearch = "SELECT * FROM Patient WHERE f_name LIKE '%\(inputPatient)%' OR l_name LIKE '%\(inputPatient)%';"//search and update the patients array
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, patientSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let patientDOB = sqlite3_column_text(statement, 1)
                let patientDOBString = String.fromCString(UnsafePointer<CChar>(patientDOB))
                
                let patientFName = sqlite3_column_text(statement, 2)
                let patientFNameString = String.fromCString(UnsafePointer<CChar>(patientFName))
                
                let patientLName = sqlite3_column_text(statement, 3)
                let patientLNameString = String.fromCString(UnsafePointer<CChar>(patientLName))
                
                let patientFullName = patientFNameString! + " " + patientLNameString!
                
                let tuple = (patientDOBString!, patientFullName)
                patients.append(tuple)
            }
        }
        println(patients)
        return patients
    }
    
    /**
    *   Adds the patient to the database
    **/
    @IBAction func addPatient(sender: UIButton) {
        var fullName = patientTextField.text
        var fullNameArr = split(fullName) {$0 == " "}
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        var dateOfBirth = patientDOBTextField.text
        
        let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name) VALUES (NULL, '\(dateOfBirth)', '\(firstName)', '\(lastName)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            println("inserted patient \(fullName)")

        }
    }
    
    /**
    *   Adds the doctor to the database
    **/
    @IBAction func addDoctor(sender: UIButton) {
        var fullName = doctorTextField.text
        var fullNameArr = split(fullName) {$0 == " "}
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        
        let query = "INSERT INTO Doctor (dID,f_name,l_name) VALUES (NULL,'\(firstName)', '\(lastName)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            println("inserted doctor \(fullName)")
            
        }
    }
    
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
    
    /**
    *   Makes this view popup under the text fields and not in a new window
    **/
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
