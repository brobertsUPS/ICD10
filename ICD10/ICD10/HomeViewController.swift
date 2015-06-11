//
//  HomeViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/8/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Home"
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
        
        if segue.identifier == "showPatients" {
            let controller = segue.destinationViewController as! PatientsTableViewController
        }
        
        if segue.identifier == "showDoctors" {
            let controller = segue.destinationViewController as! DoctorsTableViewController
        }
        
        if segue.identifier == "directCodeSearch"{
            let controller = segue.destinationViewController as! DirectSearchTableViewController
        }
    }
    

}
