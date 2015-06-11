//
//  DirectSearchTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class DirectSearchTableViewController: UITableViewController, UISearchResultsUpdating {
    
    let searchContr = UISearchController(searchResultsController: nil)
    var codeInfo:[(String, String)] = []
    var codes:[String] = []
    var codeDescriptions:[String] = []
    var database:COpaquePointer = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        
        searchContr.searchResultsUpdater = self
        searchContr.hidesNavigationBarDuringPresentation = false
        searchContr.dimsBackgroundDuringPresentation = false
        searchContr.searchBar.sizeToFit()
        self.tableView.tableHeaderView = searchContr.searchBar
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController){
        codeInfo = searchCodes(searchController.searchBar.text)//upate data
        self.tableView.reloadData()//reload table view
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return codeInfo.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("directSearchCell", forIndexPath: indexPath) as! UITableViewCell
        let tuple = codeInfo[indexPath.row]
        let (code, codeDescription) = tuple
        cell.textLabel!.text = codeDescription
        cell.detailTextLabel!.text = code
        
        return cell
    }
    
    func searchCodes(searchInput:String) -> [(String,String)]{
        println("searching \(searchInput)")
        var codeInformation:[(String,String)] = []
        
        let query = "SELECT ICD10_code, description_text FROM ICD10_condition WHERE description_text LIKE '%\(searchInput)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let ICD10Code = sqlite3_column_text(statement, 0)
                let ICD10CodeString = String.fromCString(UnsafePointer<CChar>(ICD10Code))
                
                let codeDescription = sqlite3_column_text(statement, 1)
                let codeDescriptionString = String.fromCString(UnsafePointer<CChar>(codeDescription))
                
                let tuple = (ICD10CodeString!, codeDescriptionString!)
                codeInformation.append(tuple)
            }
        }
        return codeInformation
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
