//
//  BillDatesTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/15/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit
import MessageUI

class BillDatesTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    var billDates:[String] = []
    var dbManager:DatabaseManager!
    var billFormatter:BillFormatter!
    var hasIncompleteBills:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        billFormatter = BillFormatter()
    }
    
    override func viewWillAppear(animated: Bool) {
        billDates = []
        getDates()
        self.navigationItem.hidesBackButton = true
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() }
    
    func getDates() -> [String:Int] {
        let areBillsIncomplete:[String:Int] = [:]
        
        dbManager.checkDatabaseFileAndOpen()
        
        let dateQuery = "SELECT date FROM Appointment GROUP BY date"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, dateQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                
                let date = sqlite3_column_text(statement, 0)
                let dateString = String.fromCString(UnsafePointer<CChar>(date))
                
                billDates.append(dateString!)                                      //if we got into this step the dateString is good
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return areBillsIncomplete
    }
    
    
    // MARK: - Mail Functions
    
    @IBAction func sendMail(sender: AnyObject) {
        let picker = MFMailComposeViewController()
        picker.mailComposeDelegate = self
        picker.setSubject("Bills")
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
    
    @IBAction func submitAllBills(sender: UIButton) {
        
        for var i=0; i<hasIncompleteBills.count; i++ {
            if(hasIncompleteBills[i] == 0){
                self.showAlert("A bill on \(billDates[i]) is not ready to be submitted.")
                return
            }
        }
        
        let path = filePathForSelectedExport("html")
        let htmlLine = billFormatter.formatBill("")
        
        do{
            try htmlLine.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
        }catch{
            
        }
        
        if MFMailComposeViewController.canSendMail() {
            let emailTitle = "Bills"
            let messageBody = "The bills are attached."
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
    
    func markBillsAsSubmitted(){
        
        dbManager.checkDatabaseFileAndOpen()
        let (patientsInfo, IDs, codeTypes, _, submitted) = dbManager.getBills("")
        
        for var i=0; i<IDs.count; i++ {
            let (aptID, _, _) = IDs[i]
            
            dbManager.updateAppointment(aptID, attributeToUpdate: "submitted", valueOfAttribute: 1)
        }
        
        dbManager.closeDB()
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: "Error!",
            message: msg, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showBillsForDate" {
            dbManager.checkDatabaseFileAndOpen()
            
            let indexPath = self.tableView.indexPathForSelectedRow!
            let date = billDates[indexPath.row]
            
            var (patientBills, IDs, codeType, complete, submitted) = dbManager.getBills(date)
            
            let controller = segue.destinationViewController as! BillsTableViewController
            
            controller.patientsInfo = patientBills
            controller.date = date
            controller.IDs = IDs
            controller.codeTypes = codeType
            controller.billsComplete = complete
            controller.billsSubmitted = submitted
            
        }
        dbManager.closeDB()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return billDates.count }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("billDateCell", forIndexPath: indexPath) 
        let date = billDates[indexPath.row]
        cell.textLabel!.text = date
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) { self.performSegueWithIdentifier("showBillsForDate", sender: self) }
}
