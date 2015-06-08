//
//  SearchTableViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/5/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController {
    
    var searchResults:[(String,String)]=[]          //The list of results from the text field
    var selectedPatient:(String,String) = ("","")   //The DOB and the patient's full name

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }

    /**
    *   Displays the patient's full name as the title and the date of birth for the detail
    **/
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as UITableViewCell
        let (dob, patientName) = searchResults[indexPath.row]
        cell.textLabel!.text = patientName
        cell.detailTextLabel!.text = dob
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let (dob, name) = searchResults[indexPath.row]
        selectedPatient = (dob,name)
        let parentController = self.parentViewController
        NSNotificationCenter.defaultCenter().postNotificationName("loadPatient", object: name)
        
    }
}
