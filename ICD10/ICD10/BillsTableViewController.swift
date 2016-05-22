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
    var billFormatter:BillFormatter!
    
    
    var patientsInfo:[(id:Int,dob:String, name:String)] = [] //the pID maps to the date of birth and the patient name
    var IDs:[(aptID:Int, placeID:Int, roomID:Int)] = []
    var date:String = ""
    
    var selectedCPT:[String] = []
    var selectedMC:[String] = []
    var selectedPC:[String] = []
    
    var codeTypes:[Int] = []
    var billsComplete:[Int] = []
    var billsSubmitted:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        billFormatter = BillFormatter()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        dbManager.checkDatabaseFileAndOpen()
        let (patientBills, IDs, codeType, complete, submitted) = dbManager.getBills(date)
        dbManager.closeDB()
        patientsInfo = patientBills
        self.IDs = IDs
        codeTypes = codeType
        billsComplete = complete
        billsSubmitted = submitted
        
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
        let picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setSubject("Bills for \(date)")
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue: print("Mail canceled")
        case MFMailComposeResultSaved.rawValue: print("Mail saved")
        case MFMailComposeResultSent.rawValue: markBillsAsSubmitted()
        case MFMailComposeResultFailed.rawValue: self.showAlert("No email was detected on your device. Please configure an email in the device settings and submit the bills again.")
        default : break
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func markBillsAsSubmitted(){

        dbManager.checkDatabaseFileAndOpen()
        
        for var i=0; i<IDs.count; i++ {
            let (aptID, _, _) = IDs[i]
            
            dbManager.updateAppointment(aptID, attributeToUpdate: "submitted", valueOfAttribute: 1)
        }
        
        dbManager.closeDB()
    }
    
    // MARK: - Formatting Functions
    
    @IBAction func submitAllBills(sender: UIBarButtonItem) {
        
        //billSubmitter.submitBills(date);
        
        for var i=0; i<billsComplete.count; i++ {
            if billsComplete[i] == 0 {
                self.showAlert("One or more bills is not ready to be submitted.")
                return
            }
        }
        
        let path = filePathForSelectedExport("html")
        let htmlLine = billFormatter.formatBill(date)
        //print(htmlLine)
        
        do{
            try htmlLine.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
        }catch{
            
        }
        
        if MFMailComposeViewController.canSendMail() {
            let emailTitle = "Bills For \(date)"
            let messageBody = "The bills for \(date) are attached."
            let mc:MFMailComposeViewController = MFMailComposeViewController()
            
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            
            
            let fileData:NSData = NSData(contentsOfFile: path)!
            mc.addAttachmentData(fileData, mimeType: "text/html", fileName: "Bills")
            self.presentViewController(mc, animated: true, completion: nil)
        } else {
            self.showAlert("No email account found on your device. Please add an email account in the mail application.")
        }
    }
    
    func filePathForSelectedExport(fileExtension:String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory = paths[0] as NSString
        return documentsDirectory.stringByAppendingPathComponent("Bills.\(fileExtension)") as String
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let indexPath = self.tableView.indexPathForSelectedRow
        let (_, dob, name) = patientsInfo[indexPath!.row]
        let (aptID, placeID, roomID) = IDs[indexPath!.row]
        let codeType = codeTypes[indexPath!.row]
        
        if segue.identifier == "showBill" {
            let controller = segue.destinationViewController as! BillViewController
            
            dbManager.checkDatabaseFileAndOpen()
            let (adminDoc, referDoc) = dbManager.getDoctorForBill(aptID)//doctor
            let place = dbManager.getPlaceForBill(placeID)//place
            let room = dbManager.getRoomForBill(roomID)//room
            let (codesFromDatabase, visitCodePriorityFromDatabase) = dbManager.getVisitCodesForBill(aptID)
            dbManager.closeDB()
            
            let bill:Bill = Bill()
            
            bill.textFieldText[0] = (name)
            bill.textFieldText[1] = (dob)
            bill.textFieldText[2] = (referDoc)
            bill.textFieldText[3] = (place)
            bill.textFieldText[4] = (room)
            
            bill.codesForBill = codesFromDatabase
            bill.visitCodePriority = visitCodePriorityFromDatabase
            
            bill.appointmentID = aptID
            bill.administeringDoctor = adminDoc
            
            dbManager.checkDatabaseFileAndOpen()
            bill.modifierCodes = dbManager.getModifiersForBill(aptID)
            dbManager.closeDB()
            
            if codeType == 0{
                bill.icd10On = false
            } else {
                bill.icd10On = true
            }
            if billsComplete[indexPath!.row] == 1{
                bill.billComplete = true
            } else {
                bill.billComplete = false
            }
            controller.bill = bill
        }
    }
        
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return patientsInfo.count }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billCell", forIndexPath: indexPath)
        let (_, dob, name) = patientsInfo[indexPath.row]
        let isBillComplete = billsComplete[indexPath.row]
        
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
            let (aptID, _, _) = IDs[indexPath.row]
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