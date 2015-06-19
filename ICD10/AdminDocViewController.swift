//
//  AdminDocViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/18/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class AdminDocViewController: UIViewController {

    @IBOutlet weak var administeringDoctor: UITextField!
    var dbManager = DatabaseManager()
    
    var adminDoc = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        dbManager.checkDatabaseFileAndOpen()
        
        administeringDoctor.text = dbManager.getAdminDoc()
        
        dbManager.closeDB()
        
        if administeringDoctor.text != "" {
            self.performSegueWithIdentifier("beginBill", sender: self)
        }
            // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "beginBill" {
            let controller = segue.destinationViewController as! BillViewController
            controller.administeringDoctor = self.administeringDoctor.text
            
            //dbManager.checkDatabaseFileAndOpen()
            //dbManager.addDoctorToDatabase(self.administeringDoctor.text, email: "")
            //dbManager.closeDB()
        }
    }
    

}
