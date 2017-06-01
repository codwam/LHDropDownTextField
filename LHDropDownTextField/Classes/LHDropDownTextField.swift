//
//  LHDropDownTextField.swift
//  LHDropDownTextFieldDemo
//
//  Created by 李辉 on 2017/4/23.
//  Copyright © 2017年 codwam. All rights reserved.
//

import UIKit

public enum LHDropDownMode: Int {
    case none
    case date
    case time
    case dateAndTime
    case text
    
    func transToUIDatePickerMode() -> UIDatePickerMode {
        var mode: UIDatePickerMode!
        switch self {
        case .date:
            mode = .date
        case .time:
            mode = .time
        case .dateAndTime:
            mode = .dateAndTime
        default:
            assert(false, "Can't invoke trans with \(self) \(self.rawValue)")
        }
        return mode
    }
}

@objc
public enum LHProposedSelection : Int {
    case both
    case above
    case below
}

/**
 Integer constant to use with `selectedRow` property, this will select `Select` option in optional textField.
 */
public let LHOptionalTextFieldIndex: Int = -1

/**
 Drop down text field delegate.
 */
@objc
public protocol LHDropDownTextFieldDelegate : UITextFieldDelegate {
    
    @objc
    optional func textField(_ textField: LHDropDownTextField, didSelectItem item: String?) //Called when textField changes it's selected item. Supported for IQDropDownModeTextPicker
    
    @objc
    optional func textField(_ textField: LHDropDownTextField, didSelect date: Date?) //Called when textField changes it's selected item. Supported for IQDropDownModeTimePicker, IQDropDownModeDatePicker, IQDropDownModeDateTimePicker
}

/**
 Drop down text field data source. This is only valid for IQDropDownModeTextField mode
 */
@objc
public protocol LHDropDownTextFieldDataSource : NSObjectProtocol {
    
    @objc
    optional func textField(_ textField: LHDropDownTextField, canSelectItem item: String?) -> Bool //Check if an item can be selected by dropdown texField.
    
    @objc
    optional func textField(_ textField: LHDropDownTextField, proposedSelectionModeForItem item: String?) -> LHProposedSelection //If canSelectItem return NO, then textField:proposedSelectionModeForItem: asked for propsed selection mode.
}

open class LHDropDownTextField: UITextField {
    
    // default is nil. weak reference
    override open var delegate: UITextFieldDelegate? /* LHDropDownTextFieldDelegate? */ {
        get {
            return super.delegate as? LHDropDownTextFieldDelegate
        }
        set {
            if self.delegate != nil && !(newValue is LHDropDownTextFieldDelegate) {
                assert(false, "delegate must be LHDropDownTextFieldDelegate")
            }
            super.delegate = newValue
        }
    }

    fileprivate var delegateAdapter: LHDropDownTextFieldDelegate? {
        if self.delegate != nil && !(self.delegate is LHDropDownTextFieldDelegate) {
            assert(false, "delegate must be LHDropDownTextFieldDelegate")
        }
        return self.delegate as? LHDropDownTextFieldDelegate
    }
    
    @IBOutlet weak open var dataSource: LHDropDownTextFieldDataSource? // default is nil. weak reference
    
    open var dropDownMode = LHDropDownMode.none {
        didSet {
            self.updateDropDownMode()
        }
    }
    
    // http://stackoverflow.com/questions/27432736/how-to-create-an-ibinspectable-of-type-enum
    @IBInspectable var dropDownModeAdapter: Int {
        get {
            return self.dropDownMode.rawValue
        }
        set {
            if let mode = LHDropDownMode(rawValue: newValue) {
                self.dropDownMode = mode
            } else {
                self.dropDownMode = .none
            }
        }
    }
    
    ///----------------------
    /// @name Optional
    ///----------------------
    
    fileprivate var _optionalItemText: String?
    @IBInspectable
    open var optionalItemText: String {
        get {
            if _optionalItemText == nil {
                _optionalItemText = NSLocalizedString("Select", tableName: nil, bundle: Bundle.main, value: "", comment: "")
            }
            return _optionalItemText!
        }
        set {
            _optionalItemText = newValue
            
            self.updateOptionsList()
        }
    }
    
    open var isOptionalDropDown = true {
        didSet {
            self.updateOptionsList()
        }
    }
    
    @IBInspectable
    var isOptionalDropDownAdapter: Int {
        get {
            return self.isOptionalDropDown ? 1 : 0
        }
        set {
            self.isOptionalDropDown = newValue == 0 ? false : true
        }
    }
    
    ///----------------------
    /// @name DropDown Appearance
    ///----------------------
    
    open var dropDownFont = UIFont.boldSystemFont(ofSize: 18)
    
    open var dropDownTextColor = UIColor.black
    
    open var optionalItemFont = UIFont.boldSystemFont(ofSize: 30)

    open var optionalItemTextColor = UIColor.lightGray
    
    ///----------------------
    /// @name Title Selection
    ///----------------------
    
    open var selectedItem: String? {
        get {
            switch self.dropDownMode {
            case .none:
                return super.text
            case .date, .time, .dateAndTime:
                return self.dropDownDateTimeFormatter?.string(from: self.dateTimePicker.date)
            case .text:
                var selectedRow = self.pickerView.selectedRow(inComponent: 0)
                if self.isOptionalDropDown {
                    selectedRow -= 1
                }
                if selectedRow >= 0 {
                    if let itemList = self.itemList {
                        return itemList[selectedRow]
                    }
                    return nil
                } else {// 选中 optionalItemText
                    return nil
                }
            }
        }
        set {
            self.selectedItem(selectedItem, animated: false)
        }
    }
    
    ///-------------------------------
    /// @name mode: text
    ///-------------------------------
    
    open var itemList: [String]? {
        didSet {
            self.updateOptionsList()

            self.dropDownMode = .text
            
            self.pickerView.reloadAllComponents()
            
            self.selectedRow(self.selectedRow, animated: false)
        }
    }
    
    open var itemListView: [UIView]? {
        didSet {
            self.updateOptionsList()

            self.dropDownMode = .text
            
            self.selectedRow(self.selectedRow, animated: false)
        }
    }
    
    open var itemListUI: [String]?
    
    open var selectedRow: Int {
        get {
            var selectedRow: Int
            if self.isOptionalDropDown {
                selectedRow = LHOptionalTextFieldIndex
            } else {
                selectedRow = self.pickerView.selectedRow(inComponent: 0)
            }
            return selectedRow
        }
        set {
            self.selectedRow(newValue, animated: false)
        }
    }
    
    open var adjustPickerLabelFontSizeWidth = false {
        didSet {
            self.updateOptionsList()
        }
    }
    
    @IBInspectable
    var adjustPickerLabelFontSizeWidthAdapter: Int {
        get {
            return self.adjustPickerLabelFontSizeWidth ? 1 : 0
        }
        set {
            self.adjustPickerLabelFontSizeWidth = newValue == 0 ? false : true
        }
    }
    
    ///-------------------------------
    /// @name mode: date & time & dateAndTime
    ///-------------------------------
    
    open var date: Date? {
        get {
            if self.isOptionalDropDown {
                if super.text != nil && !super.text!.isEmpty {
                    return self.dateTimePicker.date
                }
                return nil
            }
            return self.dateTimePicker.date
        }
        set {
            self.setDate(newValue, animated: false)
        }
    }
    
    open var dateComponents: DateComponents? {
        guard let date = self.date else {
            return nil
        }
        let calender = Calendar.current
        let unitFlags = Set<Calendar.Component>([.day, .month, .year])
        return calender.dateComponents(unitFlags, from: date)
    }
    
    open var year: Int? {
        return self.dateComponents?.year
    }
    
    open var month: Int? {
        return self.dateComponents?.month
    }
    
    open var day: Int? {
        return self.dateComponents?.day
    }
    
    open var hour: Int? {
        return self.dateComponents?.hour
    }
    
    open var minute: Int? {
        return self.dateComponents?.minute
    }
    
    open var second: Int? {
        return self.dateComponents?.second
    }
    
    ///-------------------------------
    /// @name mode: date & time & dateAndTime ( UIDatePicker property )
    ///-------------------------------
    
    open var datePickerMode: UIDatePickerMode = .date {
        didSet {
            switch self.dropDownMode {
            case .date, .time, .dateAndTime:
                self.dateTimePicker.datePickerMode = self.datePickerMode
                
                var dateStyle: DateFormatter.Style = .none
                var timeStyle: DateFormatter.Style = .none
                switch self.datePickerMode {
                case .time:
                    timeStyle = .short
                case .date:
                    dateStyle = .short
                case .dateAndTime:
                    dateStyle = .short
                    timeStyle = .short
                case .countDownTimer:
                    break
                }
                self.dropDownDateTimeFormatter?.dateStyle = dateStyle
                self.dropDownDateTimeFormatter?.timeStyle = timeStyle
            default:
                assert(false, "datePickerMode only uses for (.date, .time, .dateAndTime) mode")
            }
        }
    }
    
    open var minimumDate: Date? {
        didSet {
            self.dateTimePicker.minimumDate = self.minimumDate
        }
    }
    
    open var maximumDate: Date? {
        didSet {
            self.dateTimePicker.maximumDate = self.maximumDate
        }
    }
    
    fileprivate var _dropDownDateTimeFormatter: DateFormatter?
    open var dropDownDateTimeFormatter: DateFormatter? {
        get {
            switch self.dropDownMode {
            case .date, .time, .dateAndTime:
                if _dropDownDateTimeFormatter == nil {
                    _dropDownDateTimeFormatter = DateFormatter()
                }
                return _dropDownDateTimeFormatter
            default:
                return nil
            }
        }
        set {
            _dropDownDateTimeFormatter = newValue
        }
    }
    
    // MARK: - Private vars
    
    fileprivate lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.showsSelectionIndicator = true
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    fileprivate lazy var dateTimePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.addTarget(self, action: #selector(dateTimeChanged(_:)), for: .valueChanged)
        return picker
    }()
    
    var pickerItemList: [Any]?
    
    // MARK: - Init
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    // MARK: - Common Init
    
    fileprivate func commonInit() {
        
    }
    
    // MARK: - Override
    
    override open func caretRect(for position: UITextPosition) -> CGRect {
        if self.dropDownMode == .none {
            return super.caretRect(for: position)
        }
        return .zero
    }
    
    // MARK: - Event Response
    
    @objc
    fileprivate func dateTimeChanged(_ sender: UIDatePicker) {
        self.setSelectedItem(self.dropDownDateTimeFormatter?.string(from: sender.date), animated: true, shouldNotifyDelegate: true)
    }
    
    // MARK: - Public Methods
    
    open func selectedItem(_ selectedItem: String?, animated: Bool) {
        self.setSelectedItem(selectedItem, animated: animated, shouldNotifyDelegate: false)
    }
    
    open func selectedRow(_ row: Int, animated: Bool) {
        guard let itemList = self.itemList else {
            return
        }
        guard row < itemList.count + 1 else {
            return
        }
        if self.isOptionalDropDown {
            var selectRow = row
            if (row == LHOptionalTextFieldIndex) {
                super.text = ""
                selectRow = 0
            } else {
                if row == 0 {
                    super.text = ""
                } else if let itemListUI = self.itemListUI {
                    super.text = itemListUI[row - 1]
                } else if let itemList = self.itemList {
                    super.text = itemList[row - 1]
                }
            }
            self.pickerView.selectRow(selectRow, inComponent: 0, animated: animated)
        } else {
            if let itemListUI = self.itemListUI {
                super.text = itemListUI[row]
            } else if let itemList = self.itemList {
                super.text = itemList[row]
            }
            self.pickerView.selectRow(row, inComponent: 0, animated: animated)
        }
    }
    
    open func setDate(_ date: Date?, animated: Bool) {
        switch self.dropDownMode {
        case .date, .time, .dateAndTime:
            // FIXME: date == nil???
            self.setSelectedItem(self.dropDownDateTimeFormatter?.string(from: date ?? Date()), animated: animated, shouldNotifyDelegate: false)
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    fileprivate func updateDropDownMode() {
        switch self.dropDownMode {
        case .none:
            self.inputView = nil
        case .date, .time, .dateAndTime:
            self.datePickerMode = self.dropDownMode.transToUIDatePickerMode()
            self.inputView = self.dateTimePicker
            
            if !self.isOptionalDropDown {
                self.date = self.dateTimePicker.date
            }
        case .text:
            self.inputView = self.pickerView
            
            self.selectedRow(self.selectedRow, animated: true)
        }
    }
    
    fileprivate func updateOptionsList() {
        if self.isOptionalDropDown {
            if let itemList = self.itemList {
                var pickerItemList = [self.optionalItemText]
                pickerItemList.append(contentsOf: itemList)
                self.pickerItemList = pickerItemList
            } else if let itemListView = self.itemListView {
                self.pickerItemList = [itemListView]
            }
        } else {
            switch self.dropDownMode {
            case .date, .time, .dateAndTime:
                self.date = self.dateTimePicker.date
            case .text:
                self.pickerItemList = self.itemList
                self.pickerView.reloadAllComponents()
            default:
                break
            }
        }
    }
    
    fileprivate func setSelectedItem(_ selectedItem: String?, animated: Bool, shouldNotifyDelegate: Bool) {
        switch self.dropDownMode {
        case .none:
            super.text = selectedItem
        case .date, .time, .dateAndTime:
            guard let selectedItem = selectedItem else {
                return
            }
            
            var date: Date?
            if self.self.dropDownMode == .time {
                date = self.parseTime(selectedItem)
            } else {
                date = self.dropDownDateTimeFormatter?.date(from: selectedItem)
            }
            
            guard let currentDate = date else {
                print("LHDropDownTextField: Invalid date or date format: \(selectedItem)")
                return
            }
            super.text = selectedItem
            self.dateTimePicker.setDate(currentDate, animated: animated)
            
            if shouldNotifyDelegate {
                self.delegateAdapter?.textField?(self, didSelect: date)
            }
        case .text:
            guard let selectedItem = selectedItem else {
                return
            }
            guard let itemListsInternal = self.pickerItemList as? [String] else {
                return
            }
            guard let index = itemListsInternal.index(of: selectedItem) else {
                return
            }
            self.selectedRow(index, animated: animated)
            
            if shouldNotifyDelegate {
                self.delegateAdapter?.textField?(self, didSelectItem: selectedItem)
            }
        }
    }
    
    fileprivate func parseTime(_ text: String) -> Date? {
        let day = Date(timeIntervalSinceNow: 0)
        guard let dropDownDateTimeFormater = self.dropDownDateTimeFormatter else {
            return nil
        }
        guard let time = dropDownDateTimeFormater.date(from: text) else {
            return nil
        }
        
        let dayUnitFlags = Set<Calendar.Component>([.era, .day, .month, .year])
        var componentsDay = Calendar.current.dateComponents(dayUnitFlags, from: day)
        let timeUnitFlags = Set<Calendar.Component>([.hour, .minute, .second])
        let componentsTime = Calendar.current.dateComponents(timeUnitFlags, from: time)
        
        componentsDay.hour = componentsTime.hour
        componentsDay.minute = componentsTime.minute
        componentsDay.second = componentsTime.second
        
        return Calendar.current.date(from: componentsDay)
    }
    
}

// MARK: - UIPickerViewDataSource

extension LHDropDownTextField: UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerItemList?.count ?? 0
    }
    
}

// MARK: - UIPickerViewDelegate

extension LHDropDownTextField: UIPickerViewDelegate {
    
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let itemListView = self.itemListView, self.itemListView!.count > row {
            // Archiving and Unarchiving is necessary to copy UIView instance.
            let viewData = NSKeyedArchiver.archivedData(withRootObject: itemListView[row])
            let copyOfView = NSKeyedUnarchiver.unarchiveObject(with: viewData) as? UIView
            if copyOfView == nil {
                assert(false, "Copy view error")
            }
            return copyOfView!
        } else {
            var label = view as? UILabel
            if label == nil {
                label = UILabel()
                label?.textAlignment = .center
                label?.backgroundColor = .clear
            }
            let text = self.pickerItemList![row] as? String
            label?.text = text
            
            if row == 0 && self.isOptionalDropDown {
                label?.font = self.optionalItemFont
                label?.textColor = self.optionalItemTextColor
            } else {
                label?.font = self.dropDownFont
                
                let canSelect = self.dataSource?.textField?(self, canSelectItem: text) ?? true
                if canSelect {
                    label?.textColor = self.optionalItemTextColor
                } else {
                    label?.textColor = .lightGray
                }
            }
            
            label?.adjustsFontSizeToFitWidth = self.adjustsFontSizeToFitWidth
            
            return label!
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let pickerItemList = self.pickerItemList as? [String], pickerItemList.count > row else {
            return
        }
        let text = pickerItemList[row]

        let canSelect = self.dataSource?.textField?(self, canSelectItem: text) ?? true

        if canSelect {
            self.setSelectedItem(text, animated: false, shouldNotifyDelegate: true)
        } else {
            let proposedSelection: LHProposedSelection = self.dataSource?.textField?(self, proposedSelectionModeForItem: text) ?? .both
            
            var aboveIndex = row - 1
            var belowIndex = row + 1
            
            switch proposedSelection {
            case .above:
                belowIndex = self.pickerItemList!.count
            case .below:
                aboveIndex = -1
            default:
                break
            }
            
            while aboveIndex >= 0 || belowIndex < pickerItemList.count {
                if aboveIndex >= 0 {
                    let aboveText = pickerItemList[aboveIndex]
                    
                    if (self.dataSource?.textField?(self, canSelectItem: aboveText))! {
                        self.setSelectedItem(aboveText, animated: true, shouldNotifyDelegate: true)
                        return
                    }
                    
                    aboveIndex -= 1
                }
                if belowIndex < self.pickerItemList!.count {
                    let belowText = pickerItemList[aboveIndex]
                    
                    if (self.dataSource?.textField?(self, canSelectItem: belowText))! {
                        self.setSelectedItem(belowText, animated: true, shouldNotifyDelegate: true)
                        return;
                    }
                    
                    belowIndex -= 1
                }
            }
            self.selectedRow(0, animated: true)
        }
    }
    
}
