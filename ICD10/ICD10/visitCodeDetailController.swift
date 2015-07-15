//
//  visitCodeDetailController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/14/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class visitCodeDetailController: UIViewController {
    
    @IBOutlet weak var visitCodeDetailLabel: UILabel!
    
    
    var visitCodeDetail:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        visitCodeDetailLabel.text = visitCodeDetail
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
