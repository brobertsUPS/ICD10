//
//  BillDatesTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/15/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class BillDatesTableViewController: UITableViewController {

    var billDates:[String] = []
    var dbManager:DatabaseManager!
    var hasIncompleteBills:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showBillsForDate" {
            dbManager.checkDatabaseFileAndOpen()
            
            let indexPath = self.tableView.indexPathForSelectedRow!
            let date = billDates[indexPath.row]
            
            var (patientBills, IDs, codeType, complete) = dbManager.getBillsForDate(date)
            
            let controller = segue.destinationViewController as! BillsTableViewController
            controller.patientsInfo = patientBills
            controller.date = date
            controller.IDs = IDs
            controller.codeTypes = codeType
            controller.billsComplete = complete
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
