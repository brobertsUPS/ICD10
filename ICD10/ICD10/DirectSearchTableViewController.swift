/*
//  DirectSearchTableViewController.swift
//  A class to bring up all of the codes from a direct code search
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class DirectSearchTableViewController: UITableViewController{
    
    var dbManager:DatabaseManager!
    var codeInfo:[(code:String, description:String)] = []
    var selectedCode:(icd10:String, description:String, icd9:String)?
    var billViewController:BillViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return codeInfo.count }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("directSearchCell", forIndexPath: indexPath) as! UITableViewCell
        let tuple = codeInfo[indexPath.row]
        let (code, codeDescription) = tuple
        cell.textLabel!.text = codeDescription
        cell.detailTextLabel!.text = code
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let tuple = codeInfo[indexPath.row]
        let (code,codeDescription) = tuple
        
        dbManager.checkDatabaseFileAndOpen()
        let query = "SELECT ICD9_code FROM ICD10_condition NATURAL JOIN Characterized_by WHERE ICD10_code='\(code)'"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            
            let icd9Code = sqlite3_column_text(statement, 0)
            let icd9CodeString = String.fromCString(UnsafePointer<CChar>(icd9Code))!
            selectedCode = (code, codeDescription, icd9CodeString)
            
            NSNotificationCenter.defaultCenter().postNotificationName("loadCode", object: code)
        }
        self.resignFirstResponder()
        sqlite3_finalize(statement)
        dbManager.closeDB()
    }  
}