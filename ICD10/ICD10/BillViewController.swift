/*
*  BillViewController.swift
*   A class to represent a bill/visit in a medical practice
*
*  Created by Brandon S Roberts on 6/4/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class BillViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    var database:COpaquePointer!                          //The database connection
    var searchTableViewController: SearchTableViewController?   //A view controller for the popup table view
    var billViewController:BillViewController?    //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var patientTextField: UITextField!
    @IBOutlet weak var patientDOBTextField: UITextField!
    @IBOutlet weak var doctorTextField: UITextField!
    @IBOutlet weak var siteTextField: UITextField!
    @IBOutlet weak var roomTextField: UITextField!
    @IBOutlet weak var cptTextField: UITextField!
    @IBOutlet weak var mcTextField: UITextField!
    @IBOutlet weak var pcTextField: UITextField!
    @IBOutlet weak var ICD10TextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    
    var textFieldText:[String] = []                             //A list of saved items for the bill
    var icdCodes:[(icd10:String,icd9:String)] = []              //A list of saved codes for the bill
    
    /*
    var patientID:Int?
    var referringDoctorID:Int?
    var placeOfServiceID:Int?
    var roomID:Int?
    */
    //var ids:[Int] = []?
    
    //****************************************** Default override methods ******************************************************************************
    
    /**
    *   Open the database and adds a notification ovserver to this view controller.
    *   Observer listens for a click on the patient popup
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        let dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        self.navigationItem.title = "Bill"
        
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
        }
        
        for var i=0; i<icdCodes.count; i++ {
            let (icd10, icd9) = icdCodes[i]
            switch i {
            case 0:ICD10TextField.text = "\(icd10)"
            default: ICD10TextField.text = "\(ICD10TextField.text), \(icd10)"
            }
        }
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        dateTextField.text = formatter.stringFromDate(date)
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

    
    //****************************************** Clicks and Actions ******************************************************************************
    
    /**
    *   Registers the click in the text box and calls the appropriate segue
    **/
    @IBAction func clickedInTextBox(sender: UITextField) {
        
        switch sender.tag {
        case 0:self.performSegueWithIdentifier("patientSearchPopover", sender: self)
        case 2:self.performSegueWithIdentifier("doctorSearchPopover", sender: self)
        case 5:self.performSegueWithIdentifier("cptSearch", sender: self)
        case 6:self.performSegueWithIdentifier("mcSearch", sender: self)
        case 7:self.performSegueWithIdentifier("pcSearch", sender: self)
        default:break
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
    
    
    @IBAction func saveBill(sender: UIButton) {
        
        let error = checkInputs()//check that everything is there
        if error == "" {
            
            let placeID = getPlaceOfServiceID(siteTextField.text) //get the ids to input into the bill
            let roomID = getRoomID(roomTextField.text)
            let patientID = getPatientID(patientTextField.text)
            let referringDoctorID = getDoctorID(doctorTextField.text)
            var aptID = 0
            
            //insert into appointment
            let insertAPTQuery = "INSERT INTO Appointment (aptID, pID, dID, date, placeID, roomID) VALUES (NULL, '\(patientID)','\(referringDoctorID)', '\(dateTextField.text)', '\(placeID)', '\(roomID)');"
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(database, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
                aptID = Int(sqlite3_last_insert_rowid(statement))
                println("Successful Save")
            }
            
            //insert id of referring doctor or add it if none
            //Insert into has_type for all types there were\
            if cptTextField.text != "" {
                let insertHasType = "INSERT INTO Has_type (aptID,apt_code) VALUES (\(aptID),'\(cptTextField.text)')"
                var statement:COpaquePointer = nil
                if sqlite3_prepare_v2(database, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_step(statement)
                    aptID = Int(sqlite3_last_insert_rowid(statement))
                    println("Successful CPT Save")
                }
            }
            
            if mcTextField.text != "" {
                let insertHasType = "INSERT INTO Has_type (aptID,apt_code) VALUES (\(aptID),'\(mcTextField.text)')"
                var statement:COpaquePointer = nil
                if sqlite3_prepare_v2(database, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_step(statement)
                    aptID = Int(sqlite3_last_insert_rowid(statement))
                    println("Successful MC Save")
                }
            }
            
            if pcTextField.text != "" {
                let insertHasType = "INSERT INTO Has_type (aptID,apt_code) VALUES (\(aptID),'\(pcTextField.text)')"
                var statement:COpaquePointer = nil
                if sqlite3_prepare_v2(database, insertAPTQuery, -1, &statement, nil) == SQLITE_OK {
                    sqlite3_step(statement)
                    aptID = Int(sqlite3_last_insert_rowid(statement))
                    println("Successful PC Save")
                }
            }

            //Insert into diagnosed with for all ICD10 codes
                //loop
            let diagnosedWith = "INSERT INTO Diagnosed_with (aptID, ICD10_code) VALUES (\(aptID), '\(ICD10TextField.text)')"
            if sqlite3_prepare_v2(database, diagnosedWith, -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
                aptID = Int(sqlite3_last_insert_rowid(statement))
                println("Successful ICD10 Save")
            }
            //popup for successful bill save
            //remove everything from the stack and remove back button
            //segue to self
        } else {
            println(error)//popup with the error message
        }
    }
    
    
    //****************************************** Segues ******************************************************************************
    
    /**
    *   Stops any segue that is not directly called by a user action
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
            sqlite3_close(database)
        }else{
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            self.searchTableViewController = popoverViewController                          //set our view controller as the SearchPopover
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            
            //do the initial empty searches
            
            switch segue.identifier! {
            case "patientSearchPopover":
                popoverViewController.tupleSearchResults = patientSearch(patientTextField!.text)
                popoverViewController.searchType = "patient"
            case "doctorSearchPopover":
                popoverViewController.doctorSearchResults = doctorSearch(doctorTextField!.text)
                popoverViewController.searchType = "doctor"
            case "cptSearch":popoverViewController.tupleSearchResults = codeSearch("C")
            case "mcSearch":popoverViewController.tupleSearchResults = codeSearch("M")
            case "pcSearch":popoverViewController.tupleSearchResults = codeSearch("P")
            default:break
            }
            
        }
    }
    
    //****************************************** Changes in text fields ******************************************************************************
    
    /**
    ** Updates the table view in the popup for any patients that match the patient input
    **/
    @IBAction func userChangedPatientSearch(sender: UITextField) {
        let patients = patientSearch(patientTextField!.text)                                  //retrieve any patients that match the input
        if let patientSearchViewController = searchTableViewController {//only update the view if we have selected it
            patientSearchViewController.tupleSearchResults = patients
            patientSearchViewController.tableView.reloadData()          //update the list in the popup
        }
    }
    
    /**
    *   Updates the table view in the popup for any doctors that match the input
    **/
    @IBAction func userChangedDoctorSearch(sender:UITextField){
        let doctors = doctorSearch(doctorTextField!.text)
        if let doctorSearchViewController = searchTableViewController {
            doctorSearchViewController.doctorSearchResults = doctors
            doctorSearchViewController.tableView.reloadData()
        }
    }
    
    /**
    *   Updates the table view in the popup for any visit codes that match the input
    **/
    @IBAction func userChangedVisitCodeSearch(sender:UITextField) {
        
        var visitCodes:[(String,String)] = []
        
        switch sender.tag {
        case 5:visitCodes = codeSearch("C")
        case 6:visitCodes = codeSearch("M")
        case 7:visitCodes = codeSearch("P")
        default:break
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
    func patientSearch(inputPatient:String) ->[(String, String)] {
        
        var patients:[(String, String)] = []
        
        let patientSearch = "SELECT * FROM Patient WHERE f_name LIKE '%\(inputPatient)%' OR l_name LIKE '%\(inputPatient)%';"//search and update the patients array
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, patientSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let id = sqlite3_column_int(statement, 0)
                
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
        return patients
    }
    
    /**
    *   Searches for any doctors matching the text that was input into the doctor textfield.
    *   @return doctors, a list of doctors matching the user input
    **/
    func doctorSearch(inputDoctor:String) -> [String] {
        
        var doctors:[String] = []
        
        let doctorSearch = "SELECT dID, f_name, l_name FROM Doctor WHERE f_name LIKE '%\(inputDoctor)%' OR l_name LIKE '%\(inputDoctor)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, doctorSearch, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int(statement, 0)
                
                let doctorFName = sqlite3_column_text(statement, 1)
                let doctorFNameString = String.fromCString(UnsafePointer<CChar>(doctorFName))
                
                let doctorLName = sqlite3_column_text(statement, 2)
                let doctorLNameString = String.fromCString(UnsafePointer<CChar>(doctorLName))
                
                let doctorFullName = doctorFNameString! + " " + doctorLNameString!
                doctors.append(doctorFullName)
            }
        }
        return doctors
    }
    
    /**
    *   Searches for any code matching the text or code that was input into the visit code textField
    *   @return visitCodes, a list of code tuples (code, description)
    **/
    func codeSearch(codeType:String) -> [(String,String)]{
        
        var visitCodes:[(String,String)] = []
        var inputSearch = ""
        
        switch codeType {
        case "C":inputSearch = cptTextField.text
        case "M":inputSearch = mcTextField.text
        case "P":inputSearch = pcTextField.text
        default:break
        }
        
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
        return visitCodes
    }


    
    /****************************************** Update text fields ******************************************************************************
    *
    *   NOTE: The notification that calls this function is sent to all bill view controllers on the stack. 
    *   This function updates all of them if the user clicked in the corresponding text box
    **/
    
    /**
    *   Updates the patient text field with selected data when the user selects a row in the patient popup window
    *   Closes the popup after updating the patientTextField
    **/
    func updatePatient(notification: NSNotification){
        if let controller = searchTableViewController { //only update if the searchTableViewController is there
            let tuple = controller.selectedTuple
            let (dob,name) = tuple
            self.patientTextField.text = name
            self.patientDOBTextField.text = dob
            self.dismissViewControllerAnimated(true, completion: nil)
            patientTextField.resignFirstResponder()
        }
    }

    /**
    *   Updates the doctor text field witht the selected doctor
    **/
    func updateDoctor(notification: NSNotification) {
        let doctorName = searchTableViewController?.selectedDoctor
        self.doctorTextField.text = doctorName
        self.dismissViewControllerAnimated(true, completion: nil)
        doctorTextField.resignFirstResponder()
    }
    
    /**
    *   Updates the cpt code text field witht the selected code
    **/
    func updateCPT(notification:NSNotification){
        if let controller = searchTableViewController {
            let tuple = controller.selectedTuple
            var (code_description,updatedCPTCode) = tuple
            
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
    }
    
    //****************************************** Adding to Database ******************************************************************************
    
    /**
    *   Adds the patient to the database
    **/
    @IBAction func addPatient(sender: UIButton) {
        self.addPatientToDatabase(patientTextField.text)
    }
    
    func addPatientToDatabase(inputPatient:String){
        var (firstName, lastName) = split(inputPatient)
        
        var dateOfBirth = patientDOBTextField.text
        println(dateOfBirth)
        let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name, email) VALUES (NULL, '\(dateOfBirth)', '\(firstName)', '\(lastName!)', '')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            println("Saved \(firstName) \(lastName!)")
        }
    }
    
    /**
    *   Adds the doctor to the database
    **/
    @IBAction func addDoctor(sender: UIButton) {
        self.addDoctorToDatabase(doctorTextField.text)
    }
    
    func addDoctorToDatabase(inputDoctor:String) {
        var (firstName, lastName) = split(inputDoctor)
        
        let query = "INSERT INTO Doctor (dID,f_name,l_name, email) VALUES (NULL,'\(firstName)', '\(lastName!)', '')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            println("Saved \(firstName) \(lastName!)")
        }
    }
    
    func addPlaceOfService(placeInput:String){
        let insertPlaceQuery = "INSERT INTO Place_of_service (placeID, place_description) VALUES (NULL, '\(placeInput)');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }

    }
    
    func addRoom(roomInput:String) {
        let insertPlaceQuery = "INSERT INTO Place_of_service (placeID, place_description) VALUES (NULL, '\(roomInput)');"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, insertPlaceQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
    }
    
    /**
    *   Returns the id of the place of service. Adds place of service if it did not match any in the database.
    **/
    func getPlaceOfServiceID(placeInput:String) -> Int {
        
        var placeID = 0
        let placeQuery = "SELECT placeID FROM Place_of_service WHERE place_description='\(placeInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                placeID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addPlaceOfService(placeInput)
                placeID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return placeID
    }
    
    /**
    *   Returns the id of the room. Adds the room if it did not match any in the database.
    **/
    func getRoomID(roomInput:String) -> Int {
        
        var roomID = 0
        let roomQuery = "SELECT roomID FROM Room WHERE room_description='\(roomInput)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {                                  //if we found a room grab it's id
                roomID = Int(sqlite3_column_int(statement, 0))
            } else {
                self.addRoom(roomInput)                                                 //input the room and then get the id
                roomID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return roomID
    }
    
    
    /**
    *   Returns the id of the doctor. Adds the doctor if it did not match any in the database.
    **/
    func getDoctorID(doctorInput:String) -> Int {
        
        var dID = 0
        let (firstName, lastName) = split(doctorInput)
        let doctorQuery = "SELECT dID FROM Doctor WHERE f_name='\(firstName)' AND l_name='\(lastName!)';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                dID = Int(sqlite3_column_int(statement, 0))
            }  else {
                self.addDoctorToDatabase(doctorInput)
                dID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return dID
    }
    
    /**
    *   Returns the id of the patient. Adds the patient if it did not match any in the database.
    **/
    func getPatientID(patientInput:String) -> Int {
        
        var pID = 0
        let (firstName, lastName) = split(patientInput)
        let patientQuery = "SELECT pID FROM Patient WHERE f_name='\(firstName)' AND l_name='\(lastName!)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, patientQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW{
                pID = Int(sqlite3_column_int(statement, 0))
            } else {
                println("Added \(patientInput)")
                self.addPatientToDatabase(patientInput)
                pID = Int(sqlite3_last_insert_rowid(statement))
            }
        }
        return pID
    }
    
    func checkInputs() -> String{
        var error = ""
        
        if patientTextField.text == "" {
            error = "Patient was missing from the bill form. Please add a patient to the bill."
        }
        if patientDOBTextField.text == "" {
            error = "Patient date of birth was missing from the bill form. Please check the form and enter a birth date."
        }
        if doctorTextField.text == "" {
            error = "Doctor was missing from the bill form. Please add a doctor to the bill."
        }
        if siteTextField.text == "" {
            error = "Site was missing from the bill form. Please add a site to the bill"
        }
        if roomTextField.text == "" {
            error = "Room was missing from the bill form. Please add a room to the bill."
        }
        if cptTextField.text == "" {
            if mcTextField.text == "" {
                if pcTextField.text == "" {
                    error = "There was no visit code in the bill form. Please check the form for a cpt, mc, or pc code."
                }
            }
        }
        return error
    }
    
    /**
    *   Splits a string with a space delimeter
    **/
    func split(splitString:String) -> (String, String?){
        
        let fullNameArr = splitString.componentsSeparatedByString(" ")
        var firstName: String = fullNameArr[0]
        var lastName: String =  fullNameArr[1]
        return (firstName, lastName)
    }
}
