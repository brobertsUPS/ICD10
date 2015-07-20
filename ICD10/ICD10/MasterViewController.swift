//
//  MasterViewController.swift
//  A class to be the drill down navigation of the application. 
//  Also contains a direct search to add to bill.
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
  
    @IBOutlet weak var searchBar: UITextField!                              //The text field to search for direct codes
    var directSearchTableViewController:DirectSearchTableViewController?
    var selectedCode:(icd10:String, description:String, icd9:String, icd10id:Int)?

    var detailViewController: DetailViewController? = nil                   //The detail page of the application
    var objects:[(id:Int,name:String)] = []
    var dbManager:DatabaseManager!
    var billViewController:BillViewController?
    
    var favoritesCell:Bool = false
    var visitCodeToAddICDTo:String!
    var rootMasterViewController:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        
        
        dbManager.checkDatabaseFileAndOpen()
        if objects.count == 0 {//get the root locations when we load up
            let query = "SELECT * FROM Condition_location cl WHERE NOT EXISTS (SELECT * FROM Sub_location sl WHERE cl.LID = sl.LID) ORDER BY LID"
            
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    
                    let locationID = Int(sqlite3_column_int(statement, 0))
                    let locationName = sqlite3_column_text(statement, 1)
                    let locationNameString = String.fromCString(UnsafePointer<CChar>(locationName))
                    objects.append(id:locationID,name:locationNameString!)
                }
            }
            sqlite3_finalize(statement)
        }
        dbManager.closeDB()
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "codeSelected:",name:"loadCode", object: nil)
        self.tableView.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    //MARK: - TextBox Changes
    
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
    
    func searchCodes(searchInput:String) -> [(code:String,description:String, icd10id:Int)]{
        
        var codeInformation:[(code:String,description:String, icd10id:Int)] = []
        
        dbManager.checkDatabaseFileAndOpen()
        
        let query = "SELECT ICD10_code, description_text, ICD10_ID FROM ICD10_condition WHERE description_text LIKE '%\(searchInput)%' OR ICD10_code LIKE '%\(searchInput)%';"
        var statement:COpaquePointer = nil
        
        if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let ICD10Code = sqlite3_column_text(statement, 0)
                let ICD10CodeString = String.fromCString(UnsafePointer<CChar>(ICD10Code))
                
                let codeDescription = sqlite3_column_text(statement, 1)
                let codeDescriptionString = String.fromCString(UnsafePointer<CChar>(codeDescription))
                
                let icd10ID = Int(sqlite3_column_int(statement, 2))
            
                codeInformation.append(code:ICD10CodeString!, description:codeDescriptionString!, icd10id: icd10ID)
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return codeInformation
    }
    
    func codeSelected(notification: NSNotification) {
        if let controller = directSearchTableViewController {
            if let tuple = controller.selectedCode {
                let (icd10,description,icd9, icd10ID) = tuple
                self.searchBar.text = icd10
                self.dismissViewControllerAnimated(true, completion: nil)
                searchBar.resignFirstResponder()
                selectedCode = tuple
                
                performSegueWithIdentifier("showDirectSearchCode", sender: self)
            }
        }
    }
    
    func findSubLocations(locationID:Int) -> [(id:Int,name:String)]{
        
        var sub_locations:[(id:Int,name:String)] = []    //make new locations list for the sub_locations of the selected item
        dbManager.checkDatabaseFileAndOpen()

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
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return sub_locations
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "showDirectSearchPopup" { //stop the direct search popup unless explicitly called
            return false
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDirectSearchPopup" {
            
            let popoverViewController = segue.destinationViewController as! DirectSearchTableViewController
            
            self.directSearchTableViewController = popoverViewController
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            popoverViewController.billViewController = billViewController
            popoverViewController.navigationItem.title = "Direct Search"
            
        } else if segue.identifier == "showDirectSearchCode"{  //The user searched for the direct code
            
            let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
            
            controller.ICD10Text = selectedCode!.icd10
            controller.conditionDescriptionText = selectedCode!.description
            controller.ICD9Text = selectedCode!.icd9
            controller.ICD10ID = selectedCode!.icd10id
            
            controller.title = selectedCode!.description
            controller.titleName = selectedCode!.description
            
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.billViewController = self.billViewController
            controller.visitCodeToAddICDTo = self.visitCodeToAddICDTo
        } else {
            
            let indexPath = self.tableView.indexPathForSelectedRow()
            let (id, locationName) = objects[indexPath!.row]
            let newSubLocations = findSubLocations(id)
            
            if newSubLocations.count == 0 && segue.identifier == "showCodes" {
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
                
                dbManager.checkDatabaseFileAndOpen()
                var statement:COpaquePointer = nil
                let query = "SELECT ICD10_code, description_text, ICD9_code, ICD10_ID FROM ICD10_condition NATURAL JOIN characterized_by NATURAL JOIN ICD9_condition WHERE ICD10_ID=(SELECT ICD10_ID FROM Located_in WHERE LID=\(id))"
                
                if sqlite3_prepare_v2(dbManager.db, query, -1, &statement, nil) == SQLITE_OK {
                    var result = sqlite3_step(statement)
                    if result == SQLITE_ROW { // if we got the row back successfully
                        let icd10Code = sqlite3_column_text(statement, 0)
                        let icd10CodeString = String.fromCString(UnsafePointer<CChar>(icd10Code))!
                        
                        let description = sqlite3_column_text(statement, 1)
                        let descriptionString = String.fromCString(UnsafePointer<CChar>(description))!
                        
                        let icd9Code = sqlite3_column_text(statement, 2)
                        let icd9CodeString = String.fromCString(UnsafePointer<CChar>(icd9Code))!
                        
                        let icd10ID = Int(sqlite3_column_int(statement, 3))
                        
                        controller.ICD10Text = icd10CodeString
                        controller.conditionDescriptionText = descriptionString
                        controller.ICD9Text = icd9CodeString
                        controller.ICD10ID = icd10ID
                    }
                }
                sqlite3_finalize(statement)
                controller.title = locationName
                controller.titleName = locationName
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.billViewController = self.billViewController
                controller.visitCodeToAddICDTo = self.visitCodeToAddICDTo
                dbManager.closeDB()
                
            } else if (segue.identifier == "showLocations" && newSubLocations.count > 0) {
                
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! MasterViewController
                
                controller.objects = newSubLocations
                controller.title = locationName
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.billViewController = self.billViewController
                controller.favoritesCell = self.favoritesCell
                controller.visitCodeToAddICDTo = self.visitCodeToAddICDTo
                controller.rootMasterViewController = self.rootMasterViewController
            }
        }
    }
    
    /**
    *   Makes this view popup under the text fields and not in a new window
    **/
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return objects.count }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let (id, location_name) = objects[indexPath.row]
        cell.textLabel!.text = location_name
        var arr = cell.contentView.subviews
        for var i=0; i<arr.count; i++ {
            if arr[i].isKindOfClass(UIButton) {
                var button:UIButton = arr[i] as! UIButton
                button.tag = id + 1
                
                if favoritesCell  || button.tag == 221 || button.tag < 10 {
                    self.view.viewWithTag(button.tag)!.removeFromSuperview()
                }
            }
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        let (id, locationName) = objects[indexPath.row]
        
        let newSubLocations = findSubLocations(id)
        if id == 0{
            favoritesCell = true
        } else {
            favoritesCell = false
        }
        
        if newSubLocations.count == 0 {
            self.performSegueWithIdentifier("showCodes", sender: self)
        }else {
            self.performSegueWithIdentifier("showLocations", sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete && favoritesCell{
            let (id, locationName) = objects[indexPath.row]
            objects.removeAtIndex(indexPath.row)
            dbManager.checkDatabaseFileAndOpen()
            var result = dbManager.removeFavoriteFromDatabase(id)
            dbManager.closeDB()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
    }
    
    @IBAction func addCellToFavorites(sender: UIButton) {
        
        
        
        dbManager.checkDatabaseFileAndOpen()
        var locationName = dbManager.getConditionLocationWithID(sender.tag-1)
        
        let addFavoriteQuery = "INSERT INTO Sub_location (LID, Parent_locationID) VALUES (\(sender.tag - 1), 0)"
        
        var statement:COpaquePointer = nil
        var result = "The query could not complete. Please try again."
        if sqlite3_prepare_v2(dbManager.db, addFavoriteQuery, -1, &statement, nil) == SQLITE_OK {
            
            if sqlite3_step(statement) == SQLITE_DONE {
                result = "Successfully added \(locationName) to favorites"
            } else {
                result = "Failed add location with id \(sender.tag). Please try again."
            }
        }
        sqlite3_finalize(statement)
        dbManager.closeDB()
        showAlert(result)
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
}