//
//  BillsTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/15/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit
import MessageUI

class BillsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    var dbManager:DatabaseManager!
    var patientsInfo:[(id:Int,dob:String, name:String)] = [] //the pID maps to the date of birth and the patient name
    var IDs:[(aptID:Int, placeID:Int, roomID:Int)] = []
    var date:String = ""
    
    var selectedCPT:[String] = []
    var selectedMC:[String] = []
    var selectedPC:[String] = []
    
    var codeTypes:[Int] = []
    var billsComplete:[Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
    }
    
    override func viewWillAppear(animated: Bool) {
        dbManager.checkDatabaseFileAndOpen()
        var (patientBills, IDs, codeType, complete) = dbManager.getBillsForDate(date)
        dbManager.closeDB()
        patientsInfo = patientBills
        self.IDs = IDs
        codeTypes = codeType
        billsComplete = complete
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: "Error!",
            message: msg, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    // MARK: - Mail Functions
    
    @IBAction func sendMail(sender: AnyObject) {
        var picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setSubject("Bills for \(date)")
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        switch result.value {
        case MFMailComposeResultCancelled.value: println("Mail canceled")
        case MFMailComposeResultSaved.value: println("Mail saved")
        case MFMailComposeResultSent.value: println("Mail sent")
        case MFMailComposeResultFailed.value: self.showAlert("No email was detected on your device. Please configure an email in the device settings and submit the bills again.")
        default : break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Formatting Functions
    
    @IBAction func submitAllBills(sender: UIBarButtonItem) {
        
        for var i=0; i<billsComplete.count; i++ {
            if billsComplete[i] == 0 {
                self.showAlert("One or more bills is not ready to be submitted.")
                return
            }
        }
        
        let path = filePathForSelectedExport("html")
        //var csvLine = "Administering Doctor, Date, Patient Name, Patient Date of Birth, Referring Doctor, Place of Service, Room, CPT, MC, PC, ICD10, ICD9 \r\n"
        var htmlLine = "<!DOCTYPE html> <html> <head> <meta charset='UTF-8'> <title>Bills:\(date)</title> </head> <body style='background-color#B2B2B2'> <table border='1' style='width:100%'> <tr><td> Admin Doc </td><td> Date </td><td> Patient Name </td><td> Patient Date of Birth </td><td> Referring Doctor </td><td> Place of Service </td><td> Room </td><td> Visit Code </td><td> ICD10 </td><td> ICD9 </td> </tr>"
        
        var previousAdminDoc = ""
        
        for var i = 0; i<patientsInfo.count; i++ { //for every bill in the list get the information needed to submit
            
            var (id, dob, patientName) = patientsInfo[i]
            var (aptID, placeID, roomID) = IDs[i]
            var codeType = codeTypes[i]
            
            var (adminDoc, referDoc) = getDoctorForBill(aptID)//doctor
            let place = getPlaceForBill(placeID)//place
            let room = getRoomForBill(roomID)//room
            
            if previousAdminDoc == adminDoc {
                
                adminDoc = ""
            } else {
                previousAdminDoc = adminDoc
            }
            
            dbManager.checkDatabaseFileAndOpen()
            let (codesForBill, visitCodePriorityFromDatbase) = dbManager.getVisitCodesForBill(aptID)
            let modifiersForBill = dbManager.getModifiersForBill(aptID)
            dbManager.closeDB()
            
            htmlLine = htmlLine + makeHTMLLine(adminDoc,date: date, patientName: patientName, dob: dob, doctorName: referDoc, place: place, room: room, codesForBill: codesForBill, codeType: codeType, visitCodePriorityFromDatbase: visitCodePriorityFromDatbase, modifiers:modifiersForBill)
        }
        
        htmlLine = htmlLine + "</table></body> </html>"
        
        htmlLine.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
        
        if MFMailComposeViewController.canSendMail() {
            var emailTitle = "Bill"
            var messageBody = "The html file is attached."
            var mc:MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            
            
            var fileData:NSData = NSData(contentsOfFile: path)!
            mc.addAttachmentData(fileData, mimeType: "text/html", fileName: "Bills")
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            self.showAlert("No email account found on your device. Please add an email account in the mail application.")
        }
    }
    
    func makeHTMLLine(adminDoc:String, date:String, patientName:String, dob:String, doctorName:String, place:String, room:String, codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]], codeType:Int, visitCodePriorityFromDatbase: [String], modifiers:[String:Int]) -> String {
        
        var htmlLine = ""
        
        var firstVisitCode = visitCodePriorityFromDatbase[0]
        
        var icdCodesForFirstVisitCode:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = codesForBill[firstVisitCode]!
        
        var (firstICD10, firstICD9, icd10ID, extensionCode) = icdCodesForFirstVisitCode[0]
        
        if extensionCode != "" {
            firstICD10 = extensionCode           //if the extensionCode is available make sure to bill it
        }
        
        if modifiers[firstVisitCode] != nil {
            dbManager.checkDatabaseFileAndOpen()
            firstVisitCode = firstVisitCode + dbManager.getModifierWithID(modifiers[firstVisitCode]!)
            dbManager.closeDB()
        }
        
        htmlLine = htmlLine + "<tr><td> \(adminDoc) </td><td> \(date) </td><td> \(patientName) </td><td> \(dob) </td><td> \(doctorName) </td><td> \(place) </td><td> \(room) </td><td> \(firstVisitCode) </td><td> \(firstICD10) </td><td> \(firstICD9) </td> </tr>"
        
        
        for var k=1; k<icdCodesForFirstVisitCode.count; k++ { //get the rest of the codes from the first visit code
            
            var (icd10, icd9, icd10ID, extensionCode) = icdCodesForFirstVisitCode[k]
            
            if extensionCode != "" {
                icd10 = extensionCode           //if the extensionCode is available make sure to bill it
            }
            
            htmlLine = htmlLine + "<tr> <td>  </td><td>  </td><td>  </td><td> </td><td> </td><td> </td><td> </td><td>  </td><td> \(icd10) </td><td> \(icd9) </td> </tr>"
        }
        
        for var i=1; i<visitCodePriorityFromDatbase.count; i++ {                    //go through the rest of the visit codes
            
            var visitCode = visitCodePriorityFromDatbase[i]
            
            var icdCodes:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = codesForBill[visitCode]!
            
            for var j=0; j<icdCodes.count; j++ { //icdCodes

                var (icd10, icd9, icd10ID, extensionCode) = icdCodes[j]
                
                if extensionCode != "" {
                    icd10 = extensionCode           //if the extensionCode is available make sure to bill it
                }
                
                if modifiers[visitCode] != nil {
                    dbManager.checkDatabaseFileAndOpen()
                    visitCode = visitCode + dbManager.getModifierWithID(modifiers[visitCode]!)
                    dbManager.closeDB()
                }
                
                htmlLine = htmlLine + "<tr> <td>  </td><td>  </td><td>  </td><td> </td><td> </td><td> </td><td> </td><td> \(visitCode) </td><td> \(icd10) </td><td> \(icd9) </td> </tr>"
                visitCode = ""
            }
        }
        return htmlLine
    }
    
    func filePathForSelectedExport(fileExtension:String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("Bills.\(fileExtension)") as String
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var indexPath = self.tableView.indexPathForSelectedRow()
        var (id, dob, name) = patientsInfo[indexPath!.row]
        var (aptID, placeID, roomID) = IDs[indexPath!.row]
        var codeType = codeTypes[indexPath!.row]
        
        if segue.identifier == "showBill" {
            let controller = segue.destinationViewController as! BillViewController
            
            let (adminDoc, referDoc) = getDoctorForBill(aptID)//doctor
            let place = getPlaceForBill(placeID)//place
            let room = getRoomForBill(roomID)//room
            
            dbManager.checkDatabaseFileAndOpen()
            let (codesFromDatabase, visitCodePriorityFromDatabase) = dbManager.getVisitCodesForBill(aptID)
            dbManager.closeDB()
            
            controller.textFieldText.append(name)
            controller.textFieldText.append(dob)
            controller.textFieldText.append(referDoc)
            controller.textFieldText.append(place)
            controller.textFieldText.append(room)
            
            controller.codesForBill = codesFromDatabase
            controller.visitCodePriority = visitCodePriorityFromDatabase
            
            controller.appointmentID = aptID
            controller.administeringDoctor = adminDoc
            
            dbManager.checkDatabaseFileAndOpen()
            controller.modifierCodes = dbManager.getModifiersForBill(aptID)
            dbManager.closeDB()
            
            if codeType == 0{
                controller.icd10On = false
            } else {
                controller.icd10On = true
            }
            if billsComplete[indexPath!.row] == 1{
                controller.billComplete = true
            } else {
                controller.billComplete = false
            }
        }
    }
    
    // MARK: - Retrieve Bill Information
    
    func getDoctorForBill(aptID:Int) -> (String, String){
        var nameString = ""
        var adminString = ""
        var referringString = ""
        
        dbManager.checkDatabaseFileAndOpen()
        
        let doctorQuery = "SELECT f_name, l_name, type FROM Appointment NATURAL JOIN Has_doc NATURAL JOIN Doctor WHERE aptID=\(aptID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, doctorQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var firstName = sqlite3_column_text(statement, 0)
                var firstNameString = String.fromCString(UnsafePointer<CChar>(firstName))
                
                var lastName = sqlite3_column_text(statement, 1)
                var lastNameString = String.fromCString(UnsafePointer<CChar>(lastName))
                nameString = "\(firstNameString!) \(lastNameString!)"
                
                var docType = Int(sqlite3_column_int(statement, 2))
                if docType == 1 {
                    referringString = nameString
                } else {
                    adminString = nameString
                }
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return (adminString, referringString)
    }
    
    func getPlaceForBill(placeID:Int) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var place = ""
        let placeQuery = "SELECT place_description FROM Place_of_service WHERE placeID=\(placeID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, placeQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                
                var resultPlace = sqlite3_column_text(statement, 0)
                place = String.fromCString(UnsafePointer<CChar>(resultPlace))!
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return place
    }
    
    func getRoomForBill(roomID:Int) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var room = ""
        let roomQuery = "SELECT room_description FROM Room WHERE roomID=\(roomID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, roomQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                var resultRoom = sqlite3_column_text(statement, 0)
                room = String.fromCString(UnsafePointer<CChar>(resultRoom))!
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return room
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return patientsInfo.count }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billCell", forIndexPath: indexPath) as! UITableViewCell
        var (id, dob, name) = patientsInfo[indexPath.row]
        var isBillComplete = billsComplete[indexPath.row]
        
        let imageName = "Flag Filled-50.png"
        let image = UIImage(named: imageName)
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        
        if isBillComplete == 0 {
            cell.imageView?.image = imageView.image
        } else {
            cell.imageView?.image = nil
        }
        
        cell.textLabel!.text = name
        cell.detailTextLabel!.text = dob
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showBill", sender: self)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let (aptID, placeID, roomID) = IDs[indexPath.row]
            IDs.removeAtIndex(indexPath.row)
            patientsInfo.removeAtIndex(indexPath.row)
            billsComplete.removeAtIndex(indexPath.row)
            dbManager.checkDatabaseFileAndOpen()
            dbManager.removeAppointmentFromDatabase(aptID)
            dbManager.closeDB()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
}