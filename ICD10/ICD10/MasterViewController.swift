//
//  MasterViewController.swift
//  A class to be the drill down navigation of the application. Also contains a direct search to add to bill.
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
  
    @IBOutlet weak var searchBar: UITextField!                              //The text field to search for direct codes
    var directSearchTableViewController:DirectSearchTableViewController?
    var selectedCode:(icd10:String, description:String, icd9:String)?

    var detailViewController: DetailViewController? = nil                   //The detail page of the application
    var objects:[(id:Int,name:String)] = []
    var dbManager:DatabaseManager!
    var billViewController:BillViewController?
    
    private let favoritesCell = "Favorites"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "codeSelected:",name:"loadCode", object: nil)
        
        dbManager.checkDatabaseFileAndOpen()
        if objects.count == 0 {//get the root locations when we load up
            let query = "SELECT * FROM Condition_location cl WHERE NOT EXISTS (SELECT * FROM Sub_location sl WHERE cl.LID = sl.LID) ORDER BY location_name"
            
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    
                    let locationID = Int(sqlite3_column_int(statement, 0))
                    let locationName = sqlite3_column_text(statement, 1)
                    let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                    objects.append(id:locationID,name:locationNameString!)
                }
            }
        }
        dbManager.closeDB()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    /**
    *   Registers the click in the text box and calls the appropriate segue
    **/
    @IBAction func clickedInTextBox(sender: UITextField) {
        self.performSegueWithIdentifier("showDirectSearchPopup", sender: self)
    }

    /**
    *   Registers clicking return and resigns the keyboard
    **/
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    /**
    *   Registers a change in the search bar and updates the search field
    **/
    @IBAction func userChangedCodeSearch(sender: UITextField) {
        
        let codeInformation = searchCodes(sender.text)
        if let codeSearchViewController = directSearchTableViewController {
            codeSearchViewController.codeInfo = codeInformation
            codeSearchViewController.tableView.reloadData()
        }
    }
    
    /**
    *   Searches for code or descriptions that match the input
    **/
    func searchCodes(searchInput:String) -> [(code:String,description:String)]{
        
        var codeInformation:[(code:String,description:String)] = []
        
        dbManager.checkDatabaseFileAndOpen()
        
        let query = "SELECT ICD10_code, description_text FROM ICD10_condition WHERE description_text LIKE '%\(searchInput)%' OR ICD10_code LIKE '%\(searchInput)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let ICD10Code = sqlite3_column_text(statement, 0)
                let ICD10CodeString = String.fromCString(UnsafePointer<CChar>(ICD10Code))
                
                let codeDescription = sqlite3_column_text(statement, 1)
                let codeDescriptionString = String.fromCString(UnsafePointer<CChar>(codeDescription))
            
                codeInformation.append(code:ICD10CodeString!, description:codeDescriptionString!)
            }
        }
        dbManager.closeDB()
        return codeInformation
    }
    
    /**
    *   Notifies this class of the selection made in the directSearchTableViewController
    **/
    func codeSelected(notification: NSNotification) {
        if let controller = directSearchTableViewController {
            let tuple = controller.selectedCode
            let (icd10,description,icd9) = tuple!
            self.searchBar.text = icd10
            self.dismissViewControllerAnimated(true, completion: nil)
            searchBar.resignFirstResponder()
            selectedCode = tuple!
            performSegueWithIdentifier("showDirectSearchCode", sender: self)
        }
    }

    // MARK: - Segues
    
    /**
    *   Fills an array with the sublocations of the selected item
    **/
    func findSubLocations(locationID:Int) -> [(id:Int,name:String)]{
        
        var sub_locations:[(id:Int,name:String)] = []    //make new locations list for the sub_locations of the selected item
        dbManager.checkDatabaseFileAndOpen()
        //get get the sub locations and their names (does an exact match query
        //that only natural joins on one row from the sub_location table
        let query = "SELECT * FROM Condition_location NATURAL JOIN (SELECT * FROM Sub_location WHERE Parent_locationID=\(locationID)) ORDER BY location_name"
        
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW { //for every sub location
                let locationID = Int(sqlite3_column_int(statement, 0))
                let locationName = sqlite3_column_text(statement, 1)
                let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                sub_locations.append(id:locationID,name:locationNameString!)
            }
        }
        dbManager.closeDB()
        return sub_locations
    }
    
    // MARK: - Segue ***************************************************************************************************************************
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDirectSearchPopup" {
            println("Show direct search popup taken")
            let popoverViewController = (segue.destinationViewController as! UINavigationController).topViewController as! DirectSearchTableViewController
            self.directSearchTableViewController = popoverViewController
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            popoverViewController.billViewController = billViewController
            popoverViewController.navigationItem.title = "Direct Search"
            
        } else if segue.identifier == "showDirectSearchCode"{
            println("ShowDirectSearchCode taken")
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            controller.ICD10Text = selectedCode!.icd10
            controller.conditionDescriptionText = selectedCode!.description
            controller.ICD9Text = selectedCode!.icd9
            
            controller.title = selectedCode!.description
            controller.titleName = selectedCode!.description
            
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.billViewController = self.billViewController
        } else {
            
            let indexPath = self.tableView.indexPathForSelectedRow()
            let (id, locationName) = objects[indexPath!.row]
            let newSubLocations = findSubLocations(id)
            
            if newSubLocations.count == 0 && segue.identifier == "showCodes" {
                println("ShowCodes")
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                
                dbManager.checkDatabaseFileAndOpen()
                var statement:COpaquePointer = nil
                //SELECT ICD10_code, description_text, ICD9_code FROM ICD10_condition NATURAL JOIN characterized_by NATURAL JOIN ICD9_condition WHERE ICD10_code=(SELECT ICD10_code FROM located_in WHERE LID =277)
                println(id)
                let query = "SELECT ICD10_code, description_text, ICD9_code FROM ICD10_condition NATURAL JOIN characterized_by NATURAL JOIN ICD9_condition WHERE ICD10_code=(SELECT ICD10_code FROM located_in WHERE LID =\(id))"
                
                if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
                    
                    if sqlite3_step(statement) == SQLITE_ROW { // if we got the row back successfully
                        
                        let icd10Code = sqlite3_column_text(statement, 0)
                        let icd10CodeString = String.fromCString(UnsafePointer<CChar>(icd10Code))!
                        
                        let description = sqlite3_column_text(statement, 1)
                        let descriptionString = String.fromCString(UnsafePointer<CChar>(description))!
                        
                        let icd9Code = sqlite3_column_text(statement, 2)
                        let icd9CodeString = String.fromCString(UnsafePointer<CChar>(icd9Code))!
                        
                        controller.ICD10Text = icd10CodeString
                        controller.conditionDescriptionText = descriptionString
                        controller.ICD9Text = icd9CodeString
                    }
                }
                controller.title = locationName
                controller.titleName = locationName
                controller.navigationItem.title = "Bill"
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.billViewController = self.billViewController
                dbManager.closeDB()
            } else if (segue.identifier == "showLocations" && newSubLocations.count > 0) {
                println("ShowLocations taken")
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! MasterViewController
                controller.objects = newSubLocations
                controller.title = locationName
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.billViewController = self.billViewController
            }
        }
    }
    
    /**
    *   Makes this view popup under the text fields and not in a new window
    **/
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK: - Table View ***************************************************************************************************************************
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return objects.count }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let (id, location_name) = objects[indexPath.row]
        cell.textLabel!.text = location_name
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        let (id, locationName) = objects[indexPath.row]
        let newSubLocations = findSubLocations(id)
        
        if newSubLocations.count == 0 {
            self.performSegueWithIdentifier("showCodes", sender: self)
        }else {
            self.performSegueWithIdentifier("showLocations", sender: self)
        }
    }
}