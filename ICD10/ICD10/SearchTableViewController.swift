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
    var singleDataSearchResults:[String] = []
    var selectedDoctor:String = ""
    var searchType = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchType == "doctor" || searchType == "site" || searchType == "room" {
            return singleDataSearchResults.count
        }else {
            return tupleSearchResults.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("searchResultCell", forIndexPath: indexPath) as! UITableViewCell
    
        if searchType == "doctor" || searchType == "site" || searchType == "room"{
            let doctorName = singleDataSearchResults[indexPath.row]
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
            selectedDoctor = singleDataSearchResults[indexPath.row]
            NSNotificationCenter.defaultCenter().postNotificationName("loadDoctor", object: selectedDoctor)
        }else if searchType == "patient"{
            let (dob, name) = tupleSearchResults[indexPath.row]
            self.selectedTuple = (dob,name)
            NSNotificationCenter.defaultCenter().postNotificationName("loadPatient", object: name)
        }else if searchType == "site"{
            selectedDoctor = singleDataSearchResults[indexPath.row]
            NSNotificationCenter.defaultCenter().postNotificationName("loadSite", object: selectedDoctor)
        }else if searchType == "room" {
            selectedDoctor = singleDataSearchResults[indexPath.row]
            NSNotificationCenter.defaultCenter().postNotificationName("loadRoom", object: selectedDoctor)
        } else {
            let (code_description, code) = tupleSearchResults[indexPath.row]
            selectedTuple = (code_description,code)
            NSNotificationCenter.defaultCenter().postNotificationName("loadTuple", object: code)
        }
    }
}
