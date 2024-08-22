//
//  RecordSettingsViewController.swift
//  ARC
//
//  Created by Tobias Schwandt on 23.05.22.
//

import Foundation
import UIKit

class Setting {
    public var identifier: String = ""
    public var title: String = ""
    
    init(identifier: String, title: String) {
        self.identifier = identifier
        self.title = title
    }
}

class SettingSwitchOption : Setting {
    public var isActive: Bool = false
    
    override init(identifier: String, title: String) {
        super.init(identifier: identifier, title: title)
        self.isActive = UserDefaults.standard.bool(forKey: self.identifier)
    }
}

class SettingFloatOption : Setting {
    public var number: Float = 0.0
    public var unit: String = "m"
    
    init(identifier: String, title: String, unit: String) {
        super.init(identifier: identifier, title: title)
        
        self.number = UserDefaults.standard.float(forKey: self.identifier)
        self.unit = unit
    }
}

class RecordSettingsSwitchTableCellController : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var sw: UISwitch!
    
    var data: SettingSwitchOption?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func onChangeValue(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: data?.identifier ?? "")
    }
}

class RecordSettingsFloatTableCellController : UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var number: UITextField!
    @IBOutlet var unit: UILabel!
    
    var data: SettingFloatOption?
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        addDoneButtonOnNumpad(textField: self.number)
    }
    
    @IBAction func onChangeValue(_ sender: UITextField) {
        let floatText = sender.text!.replacingOccurrences(of: ",", with: ".")
        UserDefaults.standard.set(Float(floatText), forKey: data?.identifier ?? "")
    }
    
    private func addDoneButtonOnNumpad(textField: UITextField) {
        let keypadToolbar: UIToolbar = UIToolbar()
        
        // add a done button to the numberpad
        keypadToolbar.items=[
            UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: textField, action: #selector(UITextField.resignFirstResponder)),
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        ]
        
        keypadToolbar.sizeToFit()

        textField.inputAccessoryView = keypadToolbar
    }
}

class RecordSettingsViewController : UITableViewController {
    var settings: [Setting] = [
        SettingSwitchOption(identifier: "showDebug", title: "Show debug gizmo"),
        SettingSwitchOption(identifier: "showFeaturePoints", title: "Show feature points"),
        SettingSwitchOption(identifier: "showAnchorOrigins", title: "Show anchor origins"),
        SettingSwitchOption(identifier: "showAnchorGeometry", title: "Show anchor geometry"),
        SettingSwitchOption(identifier: "showWorldOrigin", title: "Show world origin"),
        SettingSwitchOption(identifier: "hideDebugViewOnRecord", title: "Hide debug view on record"),
        SettingSwitchOption(identifier: "hideDebugViewOnPlaceAnchor", title: "Hide debug view on placing first anchor"),
        SettingFloatOption(identifier: "heightOfObjectAboveAnchor", title: "Object height above anchor", unit: "m")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (settings[indexPath.row] is SettingSwitchOption)
        {
            let switchSettingOption = settings[indexPath.row] as! SettingSwitchOption
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! RecordSettingsSwitchTableCellController
            
            cell.title.text = switchSettingOption.title
            cell.sw.isOn = switchSettingOption.isActive
            cell.data = switchSettingOption
            
            return cell
        }
        
        if (settings[indexPath.row] is SettingFloatOption)
        {
            let textSettingOption = settings[indexPath.row] as! SettingFloatOption
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "FloatCell", for: indexPath) as! RecordSettingsFloatTableCellController
            
            cell.title.text = textSettingOption.title
            cell.unit.text = textSettingOption.unit
            cell.number.text = String(describing: textSettingOption.number)
            cell.data = textSettingOption
            
            return cell
        }
               
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Settings"
    }
}
