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
    var billViewController:BillViewController?                  //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var codeVersion: UISwitch!                   //Determines what version of codes to use in the bill (ICD10 default)
    @IBOutlet weak var icdType: UILabel!
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
    @IBOutlet weak var saveBillButton: UIButton!
    @IBOutlet weak var beginICD10SearchButton: UIButton!
    
    var textFieldText:[String] = []                             //A list of saved items for the bill
    var icdCodes:[(icd10:String,icd9:String)] = []              //A list of saved codes for the bill
    var cptCodes:[String] = []
    var mcCodes:[String] = []
    var pcCodes:[String] = []
    
    var appointmentID:Int?                                      //The appointment id if this is a saved bill
    var administeringDoctor:String!
    var icd10On:Bool!
    
    // MARK: - Default override methods 
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        dbManager = DatabaseManager()                           //make our database manager
        self.navigationItem.title = "Bill"
        self.fillFormTextFields()
        
        if let icd10CodesChosen = icd10On {                     //if icd10 is set make sure to display it correctly
            if icd10CodesChosen {
                codeVersion.on = true
            } else {
                codeVersion.on = false
            }
        }
        self.fillCodeTextField()
        
        if let aptIDExists = appointmentID {
            saveBillButton.setTitle("", forState: UIControlState.Normal)
            beginICD10SearchButton.setTitle("", forState: UIControlState.Normal)
        }
        fillVisitCodeFields()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.addNotifications()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePatient:",name:"loadPatient", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCPT:",name:"loadTuple", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSite:",name:"loadSite", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRoom:",name:"loadRoom", object: nil)
    }
    
    func fillFormTextFields(){
        
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        dateTextField.text = formatter.stringFromDate(date)
        
        if self.textFieldText.count > 0 {
            patientTextField.text = textFieldText[0]
            patientDOBTextField.text = textFieldText[1]
            doctorTextField.text = textFieldText[2]
            siteTextField.text = textFieldText[3]
            roomTextField.text = textFieldText[4]
        }
    }
    
    func fillCodeTextField() {
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
    
    func fillVisitCodeFields(){
        
        for var i=0; i<cptCodes.count; i++ {
            switch i {
            case 0:cptTextField.text = "\(cptCodes[i]),"
            default: cptTextField.text = "\(cptTextField.text) \(cptCodes[i]),"
            }
        }
        
        for var i=0; i<mcCodes.count; i++ {
            switch i {
            case 0:mcTextField.text = "\(mcCodes[i]),"
            default: mcTextField.text = "\(mcTextField.text) \(mcCodes[i]),"
            }
        }
        
        for var i=0; i<pcCodes.count; i++ {
            switch i {
            case 0:pcTextField.text = "\(pcCodes[i]),"
            default: pcTextField.text = "\(pcTextField.text) \(pcCodes[i]),"
            }
        }

    }
    
    @IBAction func switchCodeVersion(sender: UISwitch) { self.fillCodeTextField() }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle { return UIModalPresentationStyle.None }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }

    
    // MARK: -  Clicks and Actions
    
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
                //update icd9 or icd10
            }else {
                let placeID = getPlaceOfServiceID(siteTextField.text) //get the ids to input into the bill
                let roomID = getRoomID(roomTextField.text)
                let patientID = getPatientID(patientTextField.text, dateOfBirth: patientDOBTextField.text)
                let referringDoctorID = getDoctorID(doctorTextField.text)
                let adminDoctorID = getDoctorID(administeringDoctor)
                
                var codeType = Int(codeVersion.on)
                var (aptID, result) = addAppointmentToDatabase(patientID, date: dateTextField.text, placeID: placeID, roomID: roomID, codeType: codeType)
                
                self.addHasDoc(aptID, dID: referringDoctorID)//insert hasdoc for referring
                self.addHasDoc(aptID, dID: adminDoctorID)//insert hasdoc for admin
                
                //Insert into has_type for all types there were
                if cptTextField.text != "" {
                    let cptArr = cptTextField.text.componentsSeparatedByString(",")
                    for var i=0; i<cptArr.count; i++ {
                        let cleanCPT = cptArr[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                        self.addHasType(aptID, visitCodeText: cleanCPT)
                    }
                }
                
                if mcTextField.text != "" {
                    let mcArr = mcTextField.text.componentsSeparatedByString(",")
                    for var i=0; i<mcArr.count;i++ {
                        let cleanMC = mcArr[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                        self.addHasType(aptID, visitCodeText: cleanMC)
                    }
                }
                
                if pcTextField.text != "" {
                    let pcArr = pcTextField.text.componentsSeparatedByString(",")
                    for var i = 0; i<pcArr.count; i++ {
                        let cleanPC = pcArr[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                        self.addHasType(aptID, visitCodeText: cleanPC)
                    }
                }
                
                let icd10Arr = ICD10TextField.text.componentsSeparatedByString(",")
                for var i=0; i<icd10Arr.count; i++ {
                    let cleanString = icd10Arr[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                    self.addDiagnosedWith(aptID, ICD10Text: cleanString)
                }
                
                self.performSegueWithIdentifier("newBill", sender: self)
            }
        } else {
            showAlert(error)//popup with the error message
        }
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "beginICD10Search" {
            return true
        }
        return false
    }
    
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
                popoverViewController.singleDataSearchResults = dbManager.doctorSearch(doctorTextField!.text, type: 1)
                popoverViewController.searchType = "doctor"
            case "siteSearchPopover":
                popoverViewController.singleDataSearchResults = dbManager.siteSearch(siteTextField.text)
                popoverViewController.searchType = "site"
            case "roomSearchPopover":
                popoverViewController.singleDataSearchResults = dbManager.roomSearch(roomTextField.text)
                popoverViewController.searchType = "room"
            case "cptSearch":
                var fullCPTArr = cptTextField.text.componentsSeparatedByString(",")
                if fullCPTArr.isEmpty { fullCPTArr.append("") }
                //get the last piece in the cpt array and search on that
                popoverViewController.tupleSearchResults = dbManager.codeSearch("C", cptTextFieldText: fullCPTArr[(fullCPTArr.count-1)], mcTextFieldText: "", pcTextFieldText: "")
                
                
            case "mcSearch":
                var fullMCArr = mcTextField.text.componentsSeparatedByString(",")
                if fullMCArr.isEmpty { fullMCArr.append("") }
                popoverViewController.tupleSearchResults = dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: fullMCArr[(fullMCArr.count-1)], pcTextFieldText: "")
            case "pcSearch":
                var fullPCArr = pcTextField.text.componentsSeparatedByString(",")
                if fullPCArr.isEmpty { fullPCArr.append("") }
                popoverViewController.tupleSearchResults = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: fullPCArr[(fullPCArr.count-1)], pcTextFieldText: "")
            default:break
            }
            dbManager.closeDB()
        }
        
    }
    
    // MARK: -  Changes in text fields 
    
    @IBAction func userChangedPatientSearch(sender: UITextField) {
        dbManager.checkDatabaseFileAndOpen()
        
        let patients = dbManager.patientSearch(patientTextField!.text)                          //retrieve any patients that match the input
        if let patientSearchViewController = searchTableViewController {                        //only update the view if we have selected it
            patientSearchViewController.tupleSearchResults = patients
            patientSearchViewController.tableView.reloadData()                                  //update the list in the popup
        }
        dbManager.closeDB()
    }
    
    @IBAction func userChangedDoctorSearch(sender:UITextField){
        dbManager.checkDatabaseFileAndOpen()
        
        let doctors = dbManager.doctorSearch(doctorTextField!.text, type: 1)
        if let doctorSearchViewController = searchTableViewController {
            doctorSearchViewController.singleDataSearchResults = doctors
            doctorSearchViewController.tableView.reloadData()
        }
        
        dbManager.closeDB()
    }

    @IBAction func userChangedVisitCodeSearch(sender:UITextField) {
        
        dbManager.checkDatabaseFileAndOpen()
        
        var visitCodes:[(String,String)] = []
        
        switch sender.tag {
        case 5:
            var fullCPTArr = cptTextField.text.componentsSeparatedByString(",")
            if fullCPTArr.isEmpty { fullCPTArr.append("") }
            visitCodes = dbManager.codeSearch("C", cptTextFieldText: fullCPTArr[(fullCPTArr.count-1)], mcTextFieldText: "", pcTextFieldText: "")
        case 6:
            var fullMCArr = mcTextField.text.componentsSeparatedByString(",")
            if fullMCArr.isEmpty { fullMCArr.append("") }
            visitCodes =  dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: fullMCArr[(fullMCArr.count-1)], pcTextFieldText: "")
        case 7:
            var fullPCArr = pcTextField.text.componentsSeparatedByString(",")
            if fullPCArr.isEmpty { fullPCArr.append("") }
            visitCodes = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: "", pcTextFieldText: fullPCArr[(fullPCArr.count-1)])
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
    
    
    // MARK: -  Update text fields
    
    func updatePatient(notification: NSNotification){
        if let controller = searchTableViewController { //only update if the searchTableViewController is there
            let tuple = controller.selectedTuple
            let (dob,name) = tuple
            self.patientTextField.text = name
            
            self.patientDOBTextField.text = dob
            var pID = getPatientID(name, dateOfBirth: dob)

            updateFromPreviousBill(pID)
            self.dismissViewControllerAnimated(true, completion: nil)
            patientTextField.resignFirstResponder()
        }
    }
    
    func updateFromPreviousBill(patientID:Int) {
        dbManager.checkDatabaseFileAndOpen()
        
        var aptID:Int!
        var placeID:Int!
        var roomID:Int!
        
        let aptQuery = "SELECT aptID, placeID, roomID FROM Appointment WHERE pID=\(patientID) ORDER BY DATE"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, aptQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                aptID = Int(sqlite3_column_int(statement, 0))
                placeID = Int(sqlite3_column_int(statement, 1))
                roomID = Int(sqlite3_column_int(statement, 2))
            } else {
                aptID = -1
                placeID = -1
                roomID = -1
            }
        }
        sqlite3_finalize(statement)
        
        let docQuery = "SELECT dID FROM Has_doc NATURAL JOIN Doctor WHERE aptID=\(aptID) AND Type=1"
        var docstatement:COpaquePointer = nil
        var dID:Int?
        if sqlite3_prepare_v2(dbManager.db, docQuery, -1, &docstatement, nil) == SQLITE_OK {
            var result = sqlite3_step(docstatement)
            if result == SQLITE_ROW {
                dID = Int(sqlite3_column_int(docstatement, 0))
            }
        }
        sqlite3_finalize(docstatement)
        
        doctorTextField.text = dbManager.getDoctorWithID(dID!)
        
        siteTextField.text = dbManager.getPlaceWithID(placeID)        //Site
        roomTextField.text = dbManager.getRoomWithID(roomID)          //Room
        
        var (consult, mc, pc) = dbManager.getVisitCodesForBill(aptID)
        cptCodes = consult
        mcCodes = mc
        pcCodes = pc
        self.fillVisitCodeFields()
        
        icdCodes = dbManager.getDiagnosesCodesForBill(aptID)
        self.fillCodeTextField()
        
        dbManager.closeDB()
    }

    func updateDoctor(notification: NSNotification) {
        let doctorName = searchTableViewController?.selectedDoctor
        self.doctorTextField.text = doctorName
        self.dismissViewControllerAnimated(true, completion: nil)
        doctorTextField.resignFirstResponder()
    }
    
    func updateCPT(notification:NSNotification){
        if let controller = searchTableViewController {
            let tuple = controller.selectedTuple
            var (code_description,updatedCPTCode) = tuple
            
            if cptTextField.isFirstResponder() {
                cptCodes.append(code_description)
                //self.cptTextField.text = code_description
                cptTextField.resignFirstResponder()
            } else if mcTextField.isFirstResponder(){
                mcCodes.append(code_description)
                //self.mcTextField.text = code_description
                mcTextField.resignFirstResponder()
            } else if pcTextField.isFirstResponder() {
                pcCodes.append(code_description)
                //self.pcTextField.text = code_description
                pcTextField.resignFirstResponder()
            }
            self.fillVisitCodeFields()
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
    
    // MARK: - Adding to Database
    
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
    
    func getPlaceOfServiceID(placeInput:String) -> Int {
        var placeID = 0
        dbManager.checkDatabaseFileAndOpen()
        placeID = dbManager.getPlaceOfServiceID(placeInput)
        dbManager.closeDB()
        return placeID
    }
    
    func getRoomID(roomInput:String) -> Int {
        
        var roomID = 0
        dbManager.checkDatabaseFileAndOpen()
        roomID = dbManager.getRoomID(roomInput)
        dbManager.closeDB()
        return roomID
    }
    
    func getDoctorID(doctorInput:String) -> Int {
        var dID = 0
        dbManager.checkDatabaseFileAndOpen()
        dID = dbManager.getDoctorID(doctorInput)
        dbManager.closeDB()
        return dID
    }
    
    func getPatientID(patientInput:String, dateOfBirth:String) -> Int {
        
        var pID = 0
        dbManager.checkDatabaseFileAndOpen()
        pID = dbManager.getPatientID(patientInput, dateOfBirth: dateOfBirth)
        dbManager.closeDB()
        return pID
    }
    
    func addAppointmentToDatabase(patientID:Int, date:String, placeID:Int, roomID:Int, codeType:Int) -> (Int, String) {
        
        dbManager.checkDatabaseFileAndOpen()
        var (aptID, result) = dbManager.addAppointmentToDatabase(patientID, date: date, placeID: placeID, roomID: roomID, codeType:codeType)
        dbManager.closeDB()
        return (aptID,result)
    }
    
    func addHasType(aptID:Int, visitCodeText:String) {
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addHasType(aptID, visitCodeText: visitCodeText)
        dbManager.closeDB()
    }
    
    func addHasDoc(aptID:Int, dID:Int){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addHasDoc(aptID, dID: dID)
        dbManager.closeDB()
    }
    
    func addDiagnosedWith(aptID:Int, ICD10Text:String){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addDiagnosedWith(aptID, ICD10Text: ICD10Text)
        dbManager.closeDB()
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
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
}
