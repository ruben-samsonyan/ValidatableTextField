//
//  ValidatableTextField.swift
//  mchb-ios
//
//  Created by Ruben Samsonyan on 23/07/16.
//  Copyright © 2016 worldline. All rights reserved.
//

import UIKit

open class ValidatableTextField: UITextField {

    open lazy var validator: TextFieldValidator? {
        didSet {
            validator?.textField = self

            if let delegate = super.delegate, !(delegate is TextFieldValidator) {
                initialDelegate = delegate
            }

            super.delegate = validator
        }
    }

    public var isValid: Bool = false

    private weak var initialDelegate: UITextFieldDelegate?
    override weak open var delegate: UITextFieldDelegate? {
        set(value) {
            if super.delegate != nil {
                initialDelegate = value
            } else {
                initialDelegate = nil
                super.delegate = value
            }
        }
        get {
            return initialDelegate ?? super.delegate
        }
    }

    public func setTextChangedProgrammatically() {
        isValid = true
    }
}
