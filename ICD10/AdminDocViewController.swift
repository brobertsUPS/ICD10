//
//  AdminDocViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/18/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class AdminDocViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, DidBeginBillWithPatientInformationDelegate  {

    @IBOutlet weak var administeringDoctor: UITextField!
    var dbManager = DatabaseManager()
    var searchTableViewController:SearchTableViewController?
    var adminDoc:String?
    
    var patientFName:String?
    var patientLName:String?
    var patientDOB:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        
        if let adminDoctor = adminDoc {
            administeringDoctor.text = adminDoctor
            self.performSegueWithIdentifier("beginBill", sender: self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateDoctor:",name:"loadDoctor", object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func userEnteredPatientInformationForBill(fName: String, lName: String, dateOfBirth: String) {
        patientFName = fName
        patientLName = lName
        patientDOB = dateOfBirth
    }
    
    // MARK: - Doctor Text Box Changes
    
    @IBAction func userChangedDocSearch(sender: UITextField) {
        dbManager.checkDatabaseFileAndOpen()
        
        let doctors = dbManager.doctorSearch(administeringDoctor.text, type: 0)
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
    
    @IBAction func checkForDoctorAndAdd(sender: UIButton) {
        
        let fullNameArr = administeringDoctor.text.componentsSeparatedByString(" ")
        if fullNameArr.count > 2 && fullNameArr[2] != ""{
            self.showAlert("An error occured when saving the doctor. Please enter a first name and last name separated by a space.")
            return
        }

        
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.checkForDoctorAndAdd(administeringDoctor.text)
        dbManager.closeDB()
        
        if result == "" {
            self.performSegueWithIdentifier("beginBill", sender: self)
        }else {
            showAlert(result)
        }
    }
    
    // MARK: - TextBox and Presentation
    
    @IBAction func clickedInTextBox(sender: UITextField) {
        self.performSegueWithIdentifier("doctorSearchPopover", sender: self)
    }
    
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: "Error!",
            message: msg, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    func setTabBarVisible(visible:Bool, animated:Bool) {
        
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (tabBarIsVisible() == visible) { return }
        
        // get a frame calculation ready
        let frame = self.tabBarController?.tabBar.frame
        let height = frame?.size.height
        let offsetY = (visible ? -height! : height)
        
        // zero duration means no animation
        let duration:NSTimeInterval = (animated ? 0.3 : 0.0)
        
        //  animate the tabBar
        if frame != nil {
            UIView.animateWithDuration(duration) {
                self.tabBarController?.tabBar.frame = CGRectOffset(frame!, 0, offsetY!)
                return
            }
        }
    }
    
    func tabBarIsVisible() ->Bool {
        return self.tabBarController?.tabBar.frame.origin.y < CGRectGetMaxY(self.view.frame)
    }

    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        return false
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        setTabBarVisible(true, animated: true)
        
        if segue.identifier == "beginBill" {
            let controller = segue.destinationViewController as! BillViewController
            controller.administeringDoctor = self.administeringDoctor.text
            
            if let patintFirstName = patientFName{
                controller.newPatient = patientFName! + " " + patientLName!
                controller.newPatientDOB = patientDOB
            }
        }
        
        if segue.identifier == "doctorSearchPopover" {
            dbManager.checkDatabaseFileAndOpen()
            let popoverViewController = (segue.destinationViewController as! UIViewController) as! SearchTableViewController
            self.searchTableViewController = popoverViewController                          //set our view controller as the SearchPopover
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
            popoverViewController.searchType = "doctor"
            popoverViewController.singleDataSearchResults = dbManager.doctorSearch(administeringDoctor!.text, type: 0)
        }
    }
}