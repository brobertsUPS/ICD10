//
//  AdminDocViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/18/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class AdminDocViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var administeringDoctor: UITextField!
    var dbManager = DatabaseManager()
    var searchTableViewController:SearchTableViewController?
    
    var adminDoc = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func userChangedDocSearch(sender: UITextField) {
        dbManager.checkDatabaseFileAndOpen()
        
        let doctors = dbManager.doctorSearch(administeringDoctor.text)
        if let doctorSearchViewController = searchTableViewController {
            doctorSearchViewController.singleDataSearchResults = doctors
            doctorSearchViewController.tableView.reloadData()
        }
        dbManager.closeDB()
    }
    
    func updateDoctor(notification: NSNotification) {
        let doctorName = searchTableViewController?.selectedDoctor
        self.administeringDoctor.text = doctorName
        self.dismissViewControllerAnimated(true, completion: nil)
        administeringDoctor.resignFirstResponder()
    }
    
    /**
    *   Stops any segue that is not directly called by a user action
    */
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if identifier == "beginBill" {
            return true
        }
        return false
    }
    
    @IBAction func clickedInTextBox(sender: UITextField) {
        self.performSegueWithIdentifier("doctorSearchPopover", sender: self)
    }
    
    /**
    *   Registers clicking return and resigns the keyboard
    **/
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func checkForDoctorAndAdd(inputDoctor:String){
        dbManager.checkDatabaseFileAndOpen()
        
        dbManager.closeDB()
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "beginBill" {
            let controller = segue.destinationViewController as! BillViewController
            controller.administeringDoctor = self.administeringDoctor.text
            
            
            
        }
        
        if segue.identifier == "doctorSearchPopover" {
            dbManager.checkDatabaseFileAndOpen()
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            self.searchTableViewController = popoverViewController                          //set our view controller as the SearchPopover
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            popoverViewController.searchType = "doctor"
            popoverViewController.singleDataSearchResults = dbManager.doctorSearch(administeringDoctor!.text)
        }
    }
    

}
