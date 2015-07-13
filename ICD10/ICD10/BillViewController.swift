/*
*  BillViewController.swift
*   A class to represent a bill/visit in a medical practice
*
*  Created by Brandon S Roberts on 6/4/15.
*  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class BillViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, DidBeginBillWithPatientInformationDelegate, LXReorderableCollectionViewDataSource, LXReorderableCollectionViewDelegateFlowLayout{
    
    var dbManager:DatabaseManager!
    var searchTableViewController: SearchTableViewController?               //A view controller for the popup table view
    var billViewController:BillViewController?                              //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var codeVersion: UISwitch!                               //Determines what version of codes to use in the bill (ICD10 default)
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
    
    @IBOutlet weak var codeCollectionView: UICollectionView!
    
    var textFieldText:[String] = []                                         //A list of saved items for the bill
    
    var codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int)]] = [:]
    var visitCodePriority:[String] = []
    
    var appointmentID:Int?                                                  //The appointment id if this is a saved bill
    var administeringDoctor:String!
    var icd10On:Bool!
    var newPatient:String?
    var newPatientDOB:String?
    var selectedVisitCodeToAddTo:String?
    
    // MARK: - Default override methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        dbManager = DatabaseManager()                                       //make our database manager
        self.navigationItem.title = "Bill"
        self.fillFormTextFields()
        
        if let icd10CodesChosen = icd10On {                                 //if icd10 is set make sure to display it correctly
            if icd10CodesChosen {
                codeVersion.on = true
            } else {
                codeVersion.on = false
            }
        }
        
        if let aptIDExists = appointmentID {
            saveBillButton.setTitle("", forState: UIControlState.Normal)
        }
        
        if let billPatient = newPatient {
            patientTextField.text = billPatient
            
            if let patientDOB = newPatientDOB {
                patientDOBTextField.text = patientDOB
            }
        }
        
        codeCollectionView.delegate = self
        codeCollectionView.dataSource = self
        codeCollectionView.collectionViewLayout = LXReorderableCollectionViewFlowLayout()
        
        let layout = codeCollectionView.collectionViewLayout
        let flow  = layout as! LXReorderableCollectionViewFlowLayout
        flow.headerReferenceSize = CGSizeMake(100, 35)
    }
    
    override func viewWillAppear(animated: Bool) {                      //Fill the collectionView with any new data
        self.addNotifications()
        self.codeCollectionView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addNotifications() {                                          //listen for when a user selects an item from a popup
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePatient:",name:"loadPatient", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCPT:",name:"loadTuple", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateSite:",name:"loadSite", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateRoom:",name:"loadRoom", object: nil)
    }
    
    func fillFormTextFields(){                                          //Load data into the text fields
        
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
    
    @IBAction func switchCodeVersion(sender: UISwitch) {                //Switch the display of the icd10/icd9 code
        
        if codeVersion.on {
            icdType.text = "ICD10"
        }else {
            icdType.text = "ICD9"
        }
        codeCollectionView.reloadData()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle { return UIModalPresentationStyle.None }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    // MARK: - DidBeginBillWithPatientInformationDelegate
    
    func userEnteredPatientInformationForBill(fName:String, lName:String, dateOfBirth:String){
        patientTextField.text = fName + " " + lName
        patientDOBTextField.text = dateOfBirth
    }
    
    
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
    
    // MARK: - Save Bill
    
    @IBAction func saveBill(sender: UIButton) {
        
        let error = checkInputs()//check that everything is there
        
        if error == "" {
            
            let placeID = getPlaceOfServiceID(siteTextField.text)       //get the ids to input into the bill
            let roomID = getRoomID(roomTextField.text)
            let patientID = getPatientID(patientTextField.text, dateOfBirth: patientDOBTextField.text)
            let referringDoctorID = getDoctorID(doctorTextField.text)
            let adminDoctorID = getDoctorID(administeringDoctor)
            
            var codeType = Int(codeVersion.on)
            var (aptID, result) = addAppointmentToDatabase(patientID, date: dateTextField.text, placeID: placeID, roomID: roomID, codeType: codeType)
            
            self.addHasDoc(aptID, dID: referringDoctorID)               //insert hasdoc for referring
            self.addHasDoc(aptID, dID: adminDoctorID)                   //insert hasdoc for admin
            
            for var i=0; i<visitCodePriority.count; i++ {
                
                var visitCode = visitCodePriority[i]                    //retrieve visitCodes in the correct order
                var diagnosesForVisitCode:[(icd10:String, icd9:String, icd10id:Int)] = codesForBill[visitCode]!

                for var j=0; j<diagnosesForVisitCode.count; j++ {
                    var (icd10, icd9, icd10id) = diagnosesForVisitCode[j]
                    
                    self.addHasType(aptID, visitCodeText: visitCode, icd10CodeID: icd10id, visitPriority: i, icdPriority: j, extensionCode: "")
                }
            }
            //pop everything off of the stack
            self.navigationController!.viewControllers.first
            var viewControllers = self.navigationController!.viewControllers
            self.performSegueWithIdentifier("newBill", sender: self)
        } else {
            showAlert(error)//popup with the error message
        }
    }
    
    func checkInputs() -> String{
        var error = ""
        
        if codesForBill.keys.array.isEmpty {
            error = "There were no visit codes for the bill. Please add a visitCode and an ICD code to the bill."
            if codesForBill.values.array.isEmpty {
                error = "There were no ICD codes for the bill. Please add an ICD code to the bill"
            }
        }
        
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
        return error
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "beginICD10Search" {
            let controller = segue.destinationViewController as! MasterViewController
            controller.billViewController = self
            controller.visitCodeToAddICDTo = selectedVisitCodeToAddTo!
            controller.billViewController?.visitCodePriority = self.visitCodePriority
        }else if segue.identifier == "newBill"{
            let controller = segue.destinationViewController as! AdminDocViewController
        }else{
            
            dbManager.checkDatabaseFileAndOpen()
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            self.searchTableViewController = popoverViewController
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            
            switch segue.identifier! {                                       //Do the initial empty searches
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
                popoverViewController.tupleSearchResults = dbManager.codeSearch("C", cptTextFieldText: cptTextField.text, mcTextFieldText: "", pcTextFieldText: "")
            case "mcSearch":
                popoverViewController.tupleSearchResults = dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: mcTextField.text, pcTextFieldText: "")
            case "pcSearch":
                popoverViewController.tupleSearchResults = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: "", pcTextFieldText: pcTextField.text)
            default:break
            }
            dbManager.closeDB()
        }
        
    }
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        return false
    }
    
    // MARK: -  Changes in search fields
    
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
            visitCodes = dbManager.codeSearch("C", cptTextFieldText: cptTextField.text, mcTextFieldText: "", pcTextFieldText: "")
        case 6:
            visitCodes =  dbManager.codeSearch("M", cptTextFieldText: "", mcTextFieldText: mcTextField.text, pcTextFieldText: "")
        case 7:
            visitCodes = dbManager.codeSearch("P", cptTextFieldText: "", mcTextFieldText: "", pcTextFieldText: pcTextField.text)
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
    
    // MARK: -  Update search fields
    
    func updatePatient(notification: NSNotification){
        if let controller = searchTableViewController { //only update if the searchTableViewController is there
            
            let tuple = controller.selectedTuple
            let (dob,name) = tuple
            self.patientTextField.text = name
            
            self.patientDOBTextField.text = dob
            var pID = getPatientID(name, dateOfBirth: dob)
            
            updateFromPreviousBill(pID)                 //grab the patients previous information
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
        
        if sqlite3_prepare_v2(dbManager.db, aptQuery, -1, &statement, nil) == SQLITE_OK { //retrieve the most recent ids for the patient
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
        
        if aptID != -1 && placeID != -1 && roomID != -1 {
            let docQuery = "SELECT dID FROM Has_doc NATURAL JOIN Doctor WHERE aptID=\(aptID) AND Type=1" //retrieve the referring doctor
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
            siteTextField.text = dbManager.getPlaceWithID(placeID)                  //Site
            roomTextField.text = dbManager.getRoomWithID(roomID)                    //Room
            
            var (codesFromDatabase, visitCodePriorityFromDatabase) = dbManager.getVisitCodesForBill(aptID)
            codesForBill = codesFromDatabase
            visitCodePriority = visitCodePriorityFromDatabase                       //Find the correct order from the database
            dbManager.closeDB()
            
            self.codeCollectionView.reloadData()

        }
        
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
            
            
            cptTextField.resignFirstResponder()
            mcTextField.resignFirstResponder()
            pcTextField.resignFirstResponder()
            
            let inBillAlready = codesForBill[code_description] != nil
            println("in bill already? \(inBillAlready)")
            
            if !inBillAlready {                                             //only add a new code if it isn't already in the bill
                codesForBill[code_description] = []
                visitCodePriority.append(code_description)
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
            self.codeCollectionView.reloadData()
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
    
    func addPatientToDatabase(inputPatient:String, email:String) -> String{
        var dateOfBirth = patientDOBTextField.text
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addPatientToDatabase(inputPatient, dateOfBirth: dateOfBirth, email:email)
        dbManager.closeDB()
        return result
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
    
    func addHasType(aptID:Int, visitCodeText:String, icd10CodeID:Int, visitPriority:Int, icdPriority:Int, extensionCode:String) {
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addHasType(aptID, visitCodeText: visitCodeText, icd10CodeID: icd10CodeID, visitPriority: visitPriority, icdPriority: icdPriority, extensionCode: extensionCode)
        dbManager.closeDB()
    }
    
    func addHasDoc(aptID:Int, dID:Int){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addHasDoc(aptID, dID: dID)
        dbManager.closeDB()
    }

    func split(splitString:String) -> (String, String?){            //Splits a string with a space delimeter
        
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
    
    //MARK: - Collection View
    //NOTE: Collection view runs off of a visitCode priority list for ordering and a dictionary lookup for icd codes. 
    //To display, visit code cells are retrieved from the priority list and icd cells are retrieved with the visitcode (using the dictionary lookup)
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return codesForBill.keys.array.count
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var visitCodeForSection = visitCodePriority[section]
        return codesForBill[visitCodeForSection]!.count
    }
    
    func collectionView(collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            return CGSize(width: 160  , height: 35)                 //A header size needs to be specified for the special layout
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CONTENT", forIndexPath: indexPath) as! ICD10Cell
        var visitCodeForPriority = visitCodePriority[indexPath.section] //get the item we should display based on priority
        
        let sectionCodes:[(icd10:String, icd9:String, icd10id:Int)]  = codesForBill[visitCodeForPriority]! //lookup the icd codes in the dictionary
        
        println("ICDCELL: visit code for priority \(visitCodeForPriority) section \(indexPath.section)")
        println("ICDCELL: ICDCodes \(sectionCodes) for section \(indexPath.section) and indexPath.row \(indexPath.row)")
        println("codesForBill \(codesForBill)")
        
        let (icd10String, icd9String, icd10id) = sectionCodes[indexPath.row]
        
        if codeVersion.on {                                         //determine what codes to display
            cell.ICDLabel.text = icd10String
        }else {
            cell.ICDLabel.text = icd9String
        }
        
        cell.importanceLabel.text = String(indexPath.row + 1)       //show the priority for the icd codes
        cell.deleteICDButton.tag = indexPath.row
        cell.deleteICDButton.section = indexPath.section
        cell.deleteICDButton.codeToAddTo = visitCodeForPriority

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let cell = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "HEADER", forIndexPath: indexPath) as! CodeTokenCollectionViewCell
            
            var visitCodeForPriority = visitCodePriority[indexPath.section] //get the item we should display based on priority
            println("VISITCELL: visit code for priority \(visitCodeForPriority) section \(indexPath.section)")
            
            cell.visitCodeLabel.text = visitCodeForPriority
            
            dbManager.checkDatabaseFileAndOpen()
            cell.visitCodeDescriptionLabel.text = dbManager.getVisitCodeDescription(cell.visitCodeLabel.text!)
            dbManager.closeDB()
            
            
            cell.deleteCodeButton.tag = indexPath.section
            cell.addICDCodeButton.tag = indexPath.section
            cell.addICDCodeButton.codeToAddTo = visitCodeForPriority
            cell.shiftDownButton.tag = indexPath.section
            cell.shiftUpButton.tag = indexPath.section
            
            return cell
        }
        abort()
    }
    
    // MARK: - LXReorderableCollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, willMoveToIndexPath toIndexPath: NSIndexPath!) {
        println("WillMoveTo \(toIndexPath) from \(fromIndexPath)")
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, didMoveToIndexPath toIndexPath: NSIndexPath!) {
        println("didMoveToIndexPath section: \(toIndexPath.section) row: \(toIndexPath.row) from section: \(fromIndexPath.section) row: \(fromIndexPath.row)")
        
        var visitCode = visitCodePriority[toIndexPath.section]
        
        var icdCodesForKey:[(icd10:String, icd9:String, icd10id:Int)] = codesForBill[visitCode]!
        
        var fromICDCode = icdCodesForKey[fromIndexPath.row]
        
        if fromIndexPath.row < toIndexPath.row {                            //moving a cell to the right
            
            for var i=fromIndexPath.row; i<toIndexPath.row; i++ {           //shift all cells up to the new index, to the left
                icdCodesForKey[i] = icdCodesForKey[i+1]
            }
        }
        
        if fromIndexPath.row > toIndexPath.row {                            //moving a cell to the left
            
            for var i=fromIndexPath.row; i>toIndexPath.row; i = i-1{        //shift all cells down to the new index, to the right
                icdCodesForKey[i] = icdCodesForKey[i-1]
            }
        }
        
        icdCodesForKey[toIndexPath.row] = fromICDCode
        codesForBill[visitCode] = icdCodesForKey
        
        self.codeCollectionView.reloadData()
        
    }
    
    func collectionView(collectionView: UICollectionView!, canMoveItemAtIndexPath indexPath: NSIndexPath!) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView!, itemAtIndexPath fromIndexPath: NSIndexPath!, canMoveToIndexPath toIndexPath: NSIndexPath!) -> Bool {
        if toIndexPath.section != fromIndexPath.section{
            return false
        }
        return true
    }
    
    // MARK: - LXReorderableCollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, willBeginDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        println("willBeginDragging")
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didBeginDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        println("didBeginDragging")
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, willEndDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        println("willEndDragging")
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAtIndexPath indexPath: NSIndexPath!) {
        println("didEndDragging")
    }
    
    
    // MARK: - Cell actions
    @IBAction func userClickedDeleteVisitCode(sender: ICDDeleteButton) {
        
        println("Deleted visitCode button \(sender.tag)")
        
        
        var visitCode = visitCodePriority[sender.tag]
        codesForBill.removeValueForKey(visitCode)
        
        println("Deleting visit code \(visitCodePriority[sender.tag])")
        var deleteResult = visitCodePriority.removeAtIndex(sender.tag)
        println("delete result \(deleteResult)")
        println("visitCodePriority in delete visitCode \(visitCodePriority)")

        
        self.codeCollectionView.reloadData()
    }
    
    @IBAction func userClickedICD10Add(sender: ICDDeleteButton) {
        selectedVisitCodeToAddTo = sender.codeToAddTo!
        self.performSegueWithIdentifier("beginICD10Search", sender: sender)
    }
    
    
    @IBAction func userClickedDeleteICDCode(sender: ICDDeleteButton) {
        
        var section = sender.section
        var itemInSection = sender.tag
        println("section \(section)")
        println("ItemInSection \(itemInSection)")
        var visitCode = visitCodePriority[section]
        
        var icdCodes:[(icd10:String, icd9:String, icd10id:Int)] = codesForBill[visitCode]!
        println("icdCodes \(icdCodes)")
        icdCodes.removeAtIndex(itemInSection)
        
        codesForBill[sender.codeToAddTo!] = icdCodes
        
        self.codeCollectionView.reloadData()
    }
    
    @IBAction func shiftVisitCodeUp(sender: ICDDeleteButton) {
        println("shift up at index \(sender.tag)")
        
        if sender.tag > 0 {                         //don't shift up if already at the top
            
            println("codesForBill \(codesForBill)")
            var oldCodeForPriority = visitCodePriority[sender.tag]
            visitCodePriority[sender.tag] = visitCodePriority[sender.tag-1]
            visitCodePriority[sender.tag-1] = oldCodeForPriority
            
            self.codeCollectionView.reloadData()
        }
    }
    
    @IBAction func shiftVisitCodeDown(sender: ICDDeleteButton) {
        println("Shift down at index \(sender.tag)")
        
        if sender.tag < (codesForBill.count - 1) {         //don't shift down if already at the bottom
            var codeToMoveDown = visitCodePriority[sender.tag]
            visitCodePriority[sender.tag] = visitCodePriority[sender.tag + 1]
            visitCodePriority[sender.tag + 1] = codeToMoveDown
            
            self.codeCollectionView.reloadData()
        }
    }
}