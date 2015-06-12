//
//  SearchTableViewController.swift
//  A class to display search results for the bill page
//
//  Created by Brandon S Roberts on 6/5/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController {
    
    var tupleSearchResults:[(String,String)]=[]          //The list of results from the text field
    var selectedTuple:(String,String) = ("","")         //The DOB and the patient's full name
    var doctorSearchResults:[String] = []
    var selectedDoctor:String = ""
    var searchType = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchType == "doctor" {
            return doctorSearchResults.count
        }else {
            return tupleSearchResults.count
        }
    }

    /**
    *   Displays the cell's title and detail
    **/
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as! UITableViewCell
    
        if searchType == "doctor" {
            let doctorName = doctorSearchResults[indexPath.row]
            cell.textLabel!.text = doctorName
        } else {
            let (dob, patientName) = tupleSearchResults[indexPath.row]
            cell.textLabel!.text = patientName
            cell.detailTextLabel!.text = dob
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        if searchType == "doctor" {
            selectedDoctor = doctorSearchResults[indexPath.row]
            NSNotificationCenter.defaultCenter().postNotificationName("loadDoctor", object: selectedDoctor)
        }else if searchType == "patient"{
            let (dob, name) = tupleSearchResults[indexPath.row]
            self.selectedTuple = (dob,name)
            NSNotificationCenter.defaultCenter().postNotificationName("loadPatient", object: name)
        }else {
            let (code_description, code) = tupleSearchResults[indexPath.row]
            selectedTuple = (code_description,code)
            NSNotificationCenter.defaultCenter().postNotificationName("loadTuple", object: code)

        }
    }
}
