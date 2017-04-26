//
//  ViewController.swift
//  LHDropDownTextFieldDemo
//
//  Created by 李辉 on 2017/4/23.
//  Copyright © 2017年 codwam. All rights reserved.
//

import UIKit
import LHDropDownTextField

final class ViewController: UIViewController {
    
    @IBOutlet weak var noneTextField: LHDropDownTextField!
    @IBOutlet weak var dateTextField: LHDropDownTextField!
    @IBOutlet weak var timeTextField: LHDropDownTextField!
    @IBOutlet weak var dateAndTimeTextField: LHDropDownTextField!
    @IBOutlet weak var textTextField: LHDropDownTextField!
    
    fileprivate lazy var allTextFields: [LHDropDownTextField] = {
        let allTextFields: [LHDropDownTextField] = [
            self.noneTextField,
            self.dateTextField,
            self.timeTextField,
            self.dateAndTimeTextField,
            self.textTextField
        ]
        return allTextFields
    }()

    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        commonInit()
    }
    
    // MARK: - Memory Manager
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Common Init
    
    fileprivate func commonInit() {
        let flexibleButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneClicked(_:)))
        let toolbar = UIToolbar()
        toolbar.items = [flexibleButton, doneButton]
        toolbar.sizeToFit()
        
        self.allTextFields.forEach { (textField) in
            textField.inputAccessoryView = toolbar
        }
        
        self.textTextField.itemList = [
            "You",
            "Are",
            "a",
            "Pig"
        ]
    }
    
    // MARK: - Event Response
    
    @objc fileprivate func doneClicked(_ sender: Any) {
        self.view.endEditing(true)
        
        print("noneTextField: \(String(describing: noneTextField.selectedItem))")
        print("dateTextField: \(String(describing: dateTextField.selectedItem))")
        print("timeTextField: \(String(describing: timeTextField.selectedItem))")
        print("dateAndTimeTextField: \(String(describing: dateAndTimeTextField.selectedItem))")
        print("textTextField: \(String(describing: textTextField.selectedItem))")
    }
    
    // MARK: - Public Methods
    
    // MARK: - Private Methods


}

