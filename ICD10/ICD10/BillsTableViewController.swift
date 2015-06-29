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

    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
    }

    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
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
        case MFMailComposeResultFailed.value: println("Mail failed")
        default : break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitAllBills(sender: UIBarButtonItem) {
        
        let path = csvFilePath()
        var csvLine = "Administering Doctor, Date, Patient Name, Patient Date of Birth, Referring Doctor, Place of Service, Room, CPT, MC, PC, ICD10, ICD9 \r\n"
        
        for var i = 0; i<patientsInfo.count; i++ { //for every bill in the list get the information needed to submit
            
            var (id, dob, patientName) = patientsInfo[i]
            var (aptID, placeID, roomID) = IDs[i]
            var codeType = codeTypes[i]
            
            let (adminDoc, referDoc) = getDoctorForBill(aptID)//doctor
            println("admin: \(adminDoc) refer: \(referDoc)")
            let place = getPlaceForBill(placeID)//place
            let room = getRoomForBill(roomID)//room
            
            dbManager.checkDatabaseFileAndOpen()
            let (cpt, mc, pc) = dbManager.getVisitCodesForBill(aptID)//cpt, mc, pc
            dbManager.closeDB()
            
            let icd10Codes:[(icd10:String,icd9:String)] = getDiagnosesCodesForBill(aptID)
            
           // csvLine = csvLine + "\r\n" + makeCSVLine(adminDoc,date: date, patientName: patientName, dob: dob, doctorName: referDoc, place: place, room: room, cpt: cpt, mc: mc, pc: pc, icd10Codes: icd10Codes, codeType: codeType)
        }
        
        csvLine.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
        
        if MFMailComposeViewController.canSendMail() {
            var emailTitle = "Bill"
            var messageBody = "The .csv file is attached."
            var mc:MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            
            var fileData:NSData = NSData(contentsOfFile: path)!
            mc.addAttachmentData(fileData, mimeType: "text/csv", fileName: "Bills")
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            self.showAlert("No email account found on your device. Please add an email account in the mail application.")
        }
    }
    
    func makeCSVLine(adminDoc:String, date:String, patientName:String, dob:String, doctorName:String, place:String, room:String, cpt:String, mc:String, pc:String, icd10Codes:[(icd10:String,icd9:String)], codeType:Int) -> String {
        
        var csvLine = ""
        
        var (icd10, icd9) = icd10Codes[0]
        
        csvLine = " \(adminDoc), \(date), \(patientName), \(dob), \(doctorName), \(place), \(room), \(cpt), \(mc), \(pc), \(icd10), \(icd9)" //put all of the text field in (without the icd10 code)
        
        for var i=1; i<icd10Codes.count; i++ {
            var (ithICD10, ithICD9) = icd10Codes[i]
            csvLine += "\r\n , , , , , , , , , , \(ithICD10), \(ithICD9)" //put a new empty line for any additional icd10 codes
        }
        return csvLine

    }
    
    func csvFilePath() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as! NSString
        return documentsDirectory.stringByAppendingPathComponent("Bills.csv") as String
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
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
            let (cpt, mc, pc) = dbManager.getVisitCodesForBill(aptID)//cpt, mc, pc
            dbManager.closeDB()
            
            let icd10Codes:[(icd10:String,icd9:String)] = getDiagnosesCodesForBill(aptID)//ICD10
            
            controller.textFieldText.append(name)
            controller.textFieldText.append(dob)
            controller.textFieldText.append(referDoc)
            controller.textFieldText.append(place)
            controller.textFieldText.append(room)
            
            controller.cptCodes = cpt
            controller.mcCodes = mc
            controller.pcCodes = pc
            controller.icdCodes = icd10Codes
            
            controller.appointmentID = aptID
            if codeType == 0{
                controller.icd10On = false
            } else {
                controller.icd10On = true
            }
            
            println("Code type\(codeType)")
        }
    }
    
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
        println("Doctors for aptID: \(aptID), admin: \(adminString) refer: \(referringString)")
        return (adminString, referringString)
    }
    
    func getPlaceForBill(placeID:Int) -> String {
        dbManager.checkDatabaseFileAndOpen()
        var place = ""
        println("placeID \(placeID)")
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
        println("RoomID \(roomID)")
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
    
    
    func getDiagnosesCodesForBill(aptID:Int) -> [(icd10:String, icd9:String)] {
        
        dbManager.checkDatabaseFileAndOpen()
        
        var conditionDiagnosed:[(icd10:String, icd9:String)] = []
    
        let conditionQuery = "SELECT ICD10_code, ICD9_code FROM Diagnosed_with NATURAL JOIN Appointment NATURAL JOIN Characterized_by WHERE aptID=\(aptID)"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, conditionQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var conditionICD10 = sqlite3_column_text(statement, 0)
                var conditionString = String.fromCString(UnsafePointer<CChar>(conditionICD10))
                
                var conditionICD9 = sqlite3_column_text(statement, 1)
                var conditionICD9String = String.fromCString(UnsafePointer<CChar>(conditionICD9))
                
                var tuple = (icd10:conditionString!, icd9:conditionICD9String!)
                conditionDiagnosed += [(tuple)]
                println("DiagnosesCodesForBill \(tuple)")
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        
        return conditionDiagnosed
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return patientsInfo.count }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billCell", forIndexPath: indexPath) as! UITableViewCell
        var (id, dob, name) = patientsInfo[indexPath.row]
        cell.textLabel!.text = name
        cell.detailTextLabel!.text = dob
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("showBill", sender: self)
    }
}