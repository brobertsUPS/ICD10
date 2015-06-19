/*
*  BillViewController.swift
*   A class to represent a bill/visit in a medical practice
*
*  Created by Brandon S Roberts on 6/4/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class BillViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    var dbManager:DatabaseManager!
    var searchTableViewController: SearchTableViewController?   //A view controller for the popup table view
    var billViewController:BillViewController?    //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var codeVersion: UISwitch!   //Determines what version of codes to use in the bill (ICD10 default)
    @IBOutlet weak var icdType: UILabel!
    
    var administeringDoctor:String = ""
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
    
    var appointmentID:Int?                                       //The appointment id if this is a saved bill
    
    //****************************************** Default override methods ******************************************************************************
    
    /**
    *   Open the database and adds a notification ovserver to this view controller.
    *   Observer listens for a click on the patient popup
    **/
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager() //make our database manager
        
        self.navigationItem.title = "Bill"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePatient:",name:"loadPatient", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCPT:",name:"loadTuple", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSite:",name:"loadSite", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRoom:",name:"loadRoom", object: nil)
        
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
    
    @IBAction func switchCodeVersion(sender: UISwitch) {
        
        println("Switch code versions")
        
        if codeVersion.on {
            //icd10
            icdType.text = "ICD10"
            ICD10TextField.text = ""
            for var i=0; i<icdCodes.count; i++ {
                let (icd10, icd9) = icdCodes[i]
                switch i {
                case 0:ICD10TextField.text = "\(icd10)"
                default: ICD10TextField.text = "\(ICD10TextField.text), \(icd10)"
                }
            }
        } else {
            icdType.text = "ICD9"
            ICD10TextField.text = ""
            for var i=0; i<icdCodes.count; i++ {
                let (icd10, icd9) = icdCodes[i]
                switch i {
                case 0:ICD10TextField.text = "\(icd9)"
                default: ICD10TextField.text = "\(ICD10TextField.text), \(icd9)"
                }
            }
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

    
    //****************************************** Clicks and Actions ******************************************************************************
    
    /**
    *   Registers the click in the text box and calls the appropriate segue
    **/
    @IBAction func clickedInTextBox(sender: UITextField) {
        
        switch sender.tag {
        case 0:self.performSegueWithIdentifier("patientSearchPopover", sender: self)
        case 2:self.performSegueWithIdentifier("doctorSearchPopover", sender: self)
        case 3:self.performSegueWithIdentifier("siteSearchPopover", sender: self)
        case 4:self.performSegueWithIdentifier("roomSearchPopover", sender: self)
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
            
            if let hasAptID = appointmentID {
                println("Saved bill")
            }else {
                let placeID = getPlaceOfServiceID(siteTextField.text) //get the ids to input into the bill
                let roomID = getRoomID(roomTextField.text)
                let patientID = getPatientID(patientTextField.text, dateOfBirth: patientDOBTextField.text)
                let referringDoctorID = getDoctorID(doctorTextField.text)
                
                var (aptID, result) = addAppointmentToDatabase(patientID, doctorID: referringDoctorID, date: dateTextField.text, placeID: placeID, roomID: roomID)
                
                //Insert into has_type for all types there were
                if cptTextField.text != "" {
                    self.addHasType(aptID, visitCodeText: cptTextField.text)
                }
                
                if mcTextField.text != "" {
                    self.addHasType(aptID, visitCodeText: mcTextField.text)
                }
                
                if pcTextField.text != "" {
                    self.addHasType(aptID, visitCodeText: pcTextField.text)
                }
                
                let icd10Arr = ICD10TextField.text.componentsSeparatedByString(",") //make the diagnoses run off of the text field and not the array (a user could just type in a code)
                
                //loop to add all ICD10 codes
                for var i=0; i<icd10Arr.count; i++ {
                    let cleanString = icd10Arr[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    self.addDiagnosedWith(aptID, ICD10Text: cleanString)
                }
                
                println(icd10Arr)
                
                self.performSegueWithIdentifier("newBill", sender: self)
            }
        } else {
            showAlert(error)//popup with the error message
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
        }else if segue.identifier == "newBill"{
            let controller = segue.destinationViewController as! AdminDocViewController
        }else{
            dbManager.checkDatabaseFileAndOpen()
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            self.searchTableViewController = popoverViewController                          //set our view controller as the SearchPopover
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            
            //do the initial empty searches
            
            switch segue.identifier! {
            case "patientSearchPopover":
                popoverViewController.tupleSearchResults = dbManager.patientSearch(patientTextField!.text)
                popoverViewController.searchType = "patient"
            case "doctorSearchPopover":
                popoverViewController.singleDataSearchResults = dbManager.doctorSearch(doctorTextField!.text)
                popoverViewController.searchType = "doctor"
            case "siteSearchPopover":
                popoverViewController.singleDataSearchResults = dbManager.siteSearch(siteTextField.text)
                popoverViewController.searchType = "site"
            case "roomSearchPopover":
                popoverViewController.singleDataSearchResults = dbManager.roomSearch(roomTextField.text)
                popoverViewController.searchType = "room"
            case "cptSearch":popoverViewController.tupleSearchResults = dbManager.codeSearch("C", cptTextFieldText: cptTextField.text, mcTextFieldText: "", pcTextFieldText: "")
            case "mcSearch":popoverViewController.tupleSearchResults = dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: mcTextField.text, pcTextFieldText: "")
            case "pcSearch":popoverViewController.tupleSearchResults = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: "", pcTextFieldText: pcTextField.text)
            default:break
            }
            dbManager.closeDB()
        }
        
    }
    
    //****************************************** Changes in text fields ******************************************************************************
    
    /**
    ** Updates the table view in the popup for any patients that match the patient input
    **/
    @IBAction func userChangedPatientSearch(sender: UITextField) {
        dbManager.checkDatabaseFileAndOpen()
        
        let patients = dbManager.patientSearch(patientTextField!.text)                                  //retrieve any patients that match the input
        if let patientSearchViewController = searchTableViewController {//only update the view if we have selected it
            patientSearchViewController.tupleSearchResults = patients
            patientSearchViewController.tableView.reloadData()          //update the list in the popup
        }
        dbManager.closeDB()
    }
    
    /**
    *   Updates the table view in the popup for any doctors that match the input
    **/
    @IBAction func userChangedDoctorSearch(sender:UITextField){
        dbManager.checkDatabaseFileAndOpen()
        
        let doctors = dbManager.doctorSearch(doctorTextField!.text)
        
        if let doctorSearchViewController = searchTableViewController {
            doctorSearchViewController.singleDataSearchResults = doctors
            doctorSearchViewController.tableView.reloadData()
        }
        
        dbManager.closeDB()
    }
    
    /**
    *   Updates the table view in the popup for any visit codes that match the input
    **/
    @IBAction func userChangedVisitCodeSearch(sender:UITextField) {
        
        dbManager.checkDatabaseFileAndOpen()
        
        var visitCodes:[(String,String)] = []
        
        switch sender.tag {
        case 5:visitCodes = dbManager.codeSearch("C", cptTextFieldText: cptTextField.text, mcTextFieldText: "",pcTextFieldText: "")
        case 6:visitCodes = dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: mcTextField.text,pcTextFieldText: "")
        case 7:visitCodes = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: "", pcTextFieldText: pcTextField.text)
        default:break
        }
        
        if let visitCodeViewController = searchTableViewController {
            visitCodeViewController.tupleSearchResults = visitCodes
            visitCodeViewController.tableView.reloadData()
        }
        dbManager.closeDB()
    }
    
    @IBAction func userChangedSiteSearch(sender: UITextField) {
        
        dbManager.checkDatabaseFileAndOpen()
        
        let siteResults = dbManager.siteSearch(siteTextField.text)
        
        if let siteSearchViewController = searchTableViewController {
            siteSearchViewController.singleDataSearchResults = siteResults
            siteSearchViewController.tableView.reloadData()
        }
        dbManager.closeDB()
    }
    
    @IBAction func userChangedRoomSearch(sender: UITextField) {
        
        dbManager.checkDatabaseFileAndOpen()
        
        let roomResults = dbManager.roomSearch(roomTextField.text)
        
        if let roomSearchViewController = searchTableViewController {
            roomSearchViewController.singleDataSearchResults = roomResults
            roomSearchViewController.tableView.reloadData()
        }
        dbManager.closeDB()
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
    
    func updateSite(notification:NSNotification) {
        if let controller = searchTableViewController {
            let site = controller.selectedDoctor
            self.siteTextField.text = site
            self.dismissViewControllerAnimated(true, completion: nil)
            self.resignFirstResponder()
        }
    }
    
    func updateRoom(notification:NSNotification) {
        if let controller = searchTableViewController {
            let room = controller.selectedDoctor
            self.roomTextField.text = room
            self.dismissViewControllerAnimated(true, completion: nil)
            self.resignFirstResponder()
        }
    }
    
    //****************************************** Adding to Database ******************************************************************************
    
    /**
    *   Adds the patient to the database
    **/
    @IBAction func addPatient(sender: UIButton) {
        showAlert(self.addPatientToDatabase(patientTextField.text, email: ""))
    }
    
    func addPatientToDatabase(inputPatient:String, email:String) -> String{
        var dateOfBirth = patientDOBTextField.text
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addPatientToDatabase(inputPatient, dateOfBirth: dateOfBirth, email:email)
        dbManager.closeDB()
        return result
    }
    
    /**
    *   Adds the doctor to the database
    **/
    @IBAction func addDoctor(sender: UIButton) {
        showAlert(self.addDoctorToDatabase(doctorTextField.text, email: ""))
    }
    
    func addDoctorToDatabase(inputDoctor:String, email:String) -> String{
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addDoctorToDatabase(inputDoctor, email: email, type: 1)
        dbManager.closeDB()
        return result
    }
    
    func addPlaceOfService(placeInput:String) -> String{
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addPlaceOfService(placeInput)
        dbManager.closeDB()
        return result
    }
    
    func addRoom(roomInput:String) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addRoom(roomInput)
        dbManager.closeDB()
        return result
    }
    
    /**
    *   Returns the id of the place of service. Adds place of service if it did not match any in the database.
    **/
    func getPlaceOfServiceID(placeInput:String) -> Int {
        var placeID = 0
        dbManager.checkDatabaseFileAndOpen()
        placeID = dbManager.getPlaceOfServiceID(placeInput)
        dbManager.closeDB()
        return placeID
    }
    
    /**
    *   Returns the id of the room. Adds the room if it did not match any in the database.
    **/
    func getRoomID(roomInput:String) -> Int {
        
        var roomID = 0
        dbManager.checkDatabaseFileAndOpen()
        roomID = dbManager.getRoomID(roomInput)
        dbManager.closeDB()
        return roomID
    }
    
    /**
    *   Returns the id of the doctor. Adds the doctor if it did not match any in the database.
    **/
    func getDoctorID(doctorInput:String) -> Int {
        var dID = 0
        dbManager.checkDatabaseFileAndOpen()
        dID = dbManager.getDoctorID(doctorInput)
        dbManager.closeDB()
        return dID
    }
    
    /**
    *   Returns the id of the patient. Adds the patient if it did not match any in the database.
    **/
    func getPatientID(patientInput:String, dateOfBirth:String) -> Int {
        
        var pID = 0
        dbManager.checkDatabaseFileAndOpen()
        pID = dbManager.getPatientID(patientInput, dateOfBirth: dateOfBirth)
        dbManager.closeDB()
        return pID
    }
    
    func addAppointmentToDatabase(patientID:Int, doctorID:Int, date:String, placeID:Int, roomID:Int) -> (Int, String) {
        
        dbManager.checkDatabaseFileAndOpen()
        var (aptID, result) = dbManager.addAppointmentToDatabase(patientID, doctorID: doctorID, date: date, placeID: placeID, roomID: roomID)
        dbManager.closeDB()
        return (aptID,result)
    }
    
    func addHasType(aptID:Int, visitCodeText:String) {
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addHasType(aptID, visitCodeText: visitCodeText)
        dbManager.closeDB()
    }
    
    func addDiagnosedWith(aptID:Int, ICD10Text:String){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addDiagnosedWith(aptID, ICD10Text: ICD10Text)
        dbManager.closeDB()
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
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
