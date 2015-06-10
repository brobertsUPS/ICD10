//
//  BillViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/4/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    var database:COpaquePointer = nil
    var searchTableViewController: SearchTableViewController?
    
    @IBOutlet weak var patientTextField: UITextField!
    @IBOutlet weak var patientDOBTextField: UITextField!
    @IBOutlet weak var doctorTextField: UITextField!
    @IBOutlet weak var siteTextField: UITextField!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var cptTextField: UITextField!
    @IBOutlet weak var mcTextField: UITextField!
    @IBOutlet weak var pcTextField: UITextField!
    @IBOutlet weak var ICD10TextField: UITextField!
    
    var textFieldText:[String] = []
    
    //****************************************** Clicks and Actions ******************************************************************************
    
    /**
    *   Registers the click in the text box and calls the appropriate segue
    **/
    @IBAction func clickedInTextBox(sender: UITextField) {
        if sender.tag == 0 {
            self.performSegueWithIdentifier("patientSearchPopover", sender: self)
        }
        
        if sender.tag == 2 {
            self.performSegueWithIdentifier("doctorSearchPopover", sender: self)
        }
        
        if sender.tag == 5 {
            self.performSegueWithIdentifier("cptSearch", sender: self)
        }
        if sender.tag == 6 {
            self.performSegueWithIdentifier("mcSearch", sender: self)
        }
        if sender.tag == 7 {
            self.performSegueWithIdentifier("pcSearch", sender: self)
        }
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
        
        patientTextField.resignFirstResponder()
        patientDOBTextField.resignFirstResponder()
        doctorTextField.resignFirstResponder()
        siteTextField.resignFirstResponder()
        roomTextField.resignFirstResponder()
        cptTextField.resignFirstResponder()
        mcTextField.resignFirstResponder()
        pcTextField.resignFirstResponder()
        ICD10TextField.resignFirstResponder()
    }
    
    
    //****************************************** Segues ******************************************************************************
    
    /**
    *   Stops any segue that is not directly called by clicking in search boxes
    */
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "beginICD10Search" {
            return true
        }
        return false
    }
    
    /**
    *   Navigates to the correct popup the user clicked into
    **/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "beginICD10Search" {
            let controller = segue.destinationViewController as! MasterViewController
            controller.billViewController = self
        }else{
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            println("Popover \(popoverViewController)")
            self.searchTableViewController = popoverViewController               //set our view controller as the patientSearchPopover
            
            println("searchTableviewcontr \(searchTableViewController)")
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            
            //do the initial empty searches
            
            if segue.identifier == "patientSearchPopover"{
                popoverViewController.tupleSearchResults = patientSearch()
                popoverViewController.searchType = "patient"
            }
            
            if segue.identifier == "doctorSearchPopover" {
                popoverViewController.doctorSearchResults = doctorSearch()
                popoverViewController.searchType = "doctor"
            }
            
            if segue.identifier == "cptSearch"{
                popoverViewController.tupleSearchResults = codeSearch("C")
            }
            if segue.identifier == "mcSearch"{
                popoverViewController.tupleSearchResults = codeSearch("M")
            }
            if segue.identifier == "pcSearch"{
                popoverViewController.tupleSearchResults = codeSearch("P")
            }
            
            
        }
    }
    
    //****************************************** Changes in text fields ******************************************************************************
    
    /**
    ** Updates the table view in the popup for any patients that match the patient input
    **/
    @IBAction func userChangedPatientSearch(sender: UITextField) {
        
        let patients = patientSearch()                                  //retrieve any patients that match the input
        if let patientSearchViewController = searchTableViewController {//only update the view if we have selected it
            patientSearchViewController.tupleSearchResults = patients
            patientSearchViewController.tableView.reloadData()                        //update the list in the popup
        }
    }
    
    /**
    *   Updates the table view in the popup for any doctors that match the input
    **/
    @IBAction func userChangedDoctorSearch(sender:UITextField){
        let doctors = doctorSearch()
        if let doctorSearchViewController = searchTableViewController {
            println("changing doctor search")
            doctorSearchViewController.doctorSearchResults = doctors
            doctorSearchViewController.tableView.reloadData()
        }
    }
    
    /**
    *   Updates the table view in the popup for any visit codes that match the input
    **/
    @IBAction func userChangedVisitCodeSearch(sender:UITextField) {
        var visitCodes:[(String,String)] = []
        println("code search \(sender.tag)")
        
        if sender.tag == 5 {//CPT search
            println("CPT Search")
            visitCodes = codeSearch("C")
            
        } else if sender.tag == 6 { //MC search
            visitCodes = codeSearch("M")
        } else if sender.tag == 7 { //PC search
            visitCodes = codeSearch("P")
        }
        
        if let visitCodeViewController = searchTableViewController {
            visitCodeViewController.tupleSearchResults = visitCodes
            visitCodeViewController.tableView.reloadData()
        }
        
    }
    
    
    //****************************************** Searches ******************************************************************************
    
    /**
    *   Searches for any patients matching the text that was input into the patient textfield.
    *   @return patients, a list of patients matching the user input
    **/
    func patientSearch() ->[(String, String)] {
        
        var patients:[(String, String)] = []
        
        let inputPatient = patientTextField.text   //get the typed information
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
    *   Searches for any doctors matching the text that was input into the doctor textfield.
    *   @return doctors, a list of doctors matching the user input
    **/
    func doctorSearch() -> [String] {
        
        var doctors:[String] = []
        
        let inputDoctor = doctorTextField.text
        println(inputDoctor)
        
        let doctorSearch = "SELECT f_name, l_name FROM Doctor WHERE f_name LIKE '%\(inputDoctor)%' OR l_name LIKE '%\(inputDoctor)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let doctorFName = sqlite3_column_text(statement, 0)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 1)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
            }
        }
        println(doctors)
        return doctors
    }
    
    /**
    *   Searches for any code matching the text or code that was input into the visit code textField
    **/
    func codeSearch(type:String) -> [(String,String)]{
        
        var visitCodes:[(String,String)] = []
        
        var codeType = type
        var inputSearch = ""
        
        if codeType == "C" {
            inputSearch = cptTextField.text
        }else if codeType == "M" {
            inputSearch = mcTextField.text
        } else if codeType == "P" {
            inputSearch = pcTextField.text
        }
        println(codeType)
        println(inputSearch)
        let codeSearch = "SELECT apt_code, code_description FROM Apt_type WHERE type_description='\(codeType)' AND (code_description LIKE '%\(inputSearch)%' OR apt_code LIKE '%\(inputSearch)%');"
        
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, codeSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let apt_code = sqlite3_column_text(statement, 0)
                let apt_codeString = String.fromCString(UnsafePointer<CChar>(apt_code))
                
                let code_description = sqlite3_column_text(statement, 1)
                let code_descriptionString = String.fromCString(UnsafePointer<CChar>(code_description))
                
                let tuple = (apt_codeString!, code_descriptionString!)
                visitCodes.append(tuple)
            }
        }
        println("Visitcode \(visitCodes)")
        return visitCodes
    }


    
    //****************************************** Update text fields ******************************************************************************
    
    /**
    *   Updates the patient text field with selected data when the user selects a row in the patient popup window
    *   Closes the popup after updating the patientTextField
    **/
    func updatePatient(notification: NSNotification){
        //load data here
        println("SearchTableViewController \(self.searchTableViewController)")
        if let controller = searchTableViewController {
            let tuple = controller.selectedTuple
            let (dob,name) = tuple
            self.patientTextField.text = name
            self.patientDOBTextField.text = dob
            self.dismissViewControllerAnimated(true, completion: nil)
            patientTextField.resignFirstResponder()
        }
        //unwrap optional if searchTableViewController was not nil
        
    }


    /**
    *   Updates the doctor text field witht the selected doctor
    **/
    func updateDoctor(notification: NSNotification) {
        let doctorName = searchTableViewController?.selectedDoctor
        println("SearchTableViewController update doctor \(self.searchTableViewController)")
        self.doctorTextField.text = doctorName
        self.dismissViewControllerAnimated(true, completion: nil)
        doctorTextField.resignFirstResponder()
    }
    
    /**
    *   Updates the cpt code text field witht the selected code
    **/
    func updateCPT(notification:NSNotification){
        
        let tuple = searchTableViewController?.selectedTuple
        var (code_description,updatedCPTCode) = tuple!
        
        if cptTextField.isFirstResponder() {
            self.cptTextField.text = code_description
            cptTextField.resignFirstResponder()
        } else if mcTextField.isFirstResponder(){
            self.mcTextField.text = code_description
            mcTextField.resignFirstResponder()
        } else if pcTextField.isFirstResponder() {
            self.pcTextField.text = code_description
            pcTextField.resignFirstResponder()
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    

    
    //****************************************** Adding to Database ******************************************************************************
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
    
    //****************************************** Default override methods ******************************************************************************
    
    /**
    *   Open the database and adds a notification ovserver to this view controller.
    *   Observer listens for a click on the patient popup
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        let dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePatient:",name:"loadPatient", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCPT:",name:"loadTuple", object: nil)
        
        if self.textFieldText.count > 0 {
            patientTextField.text = textFieldText[0]
            patientDOBTextField.text = textFieldText[1]
            doctorTextField.text = textFieldText[2]
            siteTextField.text = textFieldText[3]
            roomTextField.text = textFieldText[4]
            cptTextField.text = textFieldText[5]
            mcTextField.text = textFieldText[6]
            pcTextField.text = textFieldText[7]
            ICD10TextField.text = textFieldText[8]
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
