//
// Created by Ruben Samsonyan on 26/07/16.
// Copyright (c) 2016 worldline. All rights reserved.
//

import Foundation

open class TextFieldValidator: NSObject, UITextFieldDelegate {
    open var validators: [TextValidator]
    open var validationError: Error?

    var isValid = false
    var delegateMethodCalled = false
    var editingInProcess = false

    private weak var textField: ValidatableTextField! {
        didSet {
            textField.addTarget(self, action: #selector(self.textFieldDidChangeEditing), for: .editingChanged)
        }
    }

    open init(validators: [TextValidator]) {
        self.validators = validators
    }

    // MARK: - UITextFieldDelegate methods
    // All UITextFieldDelegate methods will proxy calls to textfield delegate set by user if it's not nil

    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldShouldBeginEditing(_:))) {
            return delegate.textFieldShouldBeginEditing!(textField)
        }

        return true
    }

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        editingInProcess = true

        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldDidBeginEditing(_:))) {
            return delegate.textFieldDidBeginEditing!(textField)
        }
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldShouldEndEditing(_:))) {
            return delegate.textFieldShouldEndEditing!(textField)
        }

        return false
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        let validators = self.validators.filter({ $0.executeOnEnd })
        if let text = textField.text, validators.count > 0 {
            var validationError: TextValidationError? = nil

            for validator in validators {
                do {
                    let newText = try validator.validate(oldText: nil, newText: text)
                    if validator.shouldFormat {
                        textField.text = newText
                        textField.sendActions(for: .editingChanged)
                    }
                } catch let error {
                    if let error = error as? TextValidationError {
                        validationError = error
                    } else {
                        validationError = TextValidationError.wrongResult
                    }
                    break
                }
            }
            self.validationError = validationError
            self.textField.isValid.value = validationError == nil
        }

        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldDidEndEditing(_:reason:))) {
            delegate.textFieldDidEndEditing!(textField, reason: reason)
        }

        editingInProcess = false
    }

    open func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldDidEndEditing(_:reason:))) {
            delegate.textFieldDidEndEditing!(textField, reason: reason)
        }
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        delegateMethodCalled = true
        let validators = self.validators.filter({ !$0.executeOnEnd })
        if validators.count > 0 {
            var shouldBlockInput = false
            validationError = nil
            var resultText = updatedText(range, text: string)

            for validator in validators {
                if let error = executeValidator(validator, textField: textField, range: range, string: string, result: &resultText) {
                    validationError = error

                    if validationError == nil {
                        validationError = error
                    }

                    switch error {
                    case .wrongFormat, .wrongLength, .hasNumericSequence, .hasConsecutiveIdenticalCharacters:
                        isValid = false
                        if validator.shouldBlockInput {
                            return false
                        }
                    case .wrongInput:
                        if validator.shouldBlockInput {
                            return false
                        }
                    default: break
                    }
                }

                if validator.shouldFormat {
                    shouldBlockInput = true
                }

                if validationError != nil {
                    break
                }
            }

            isValid = validationError == nil
            if isValid {
                self.validationError = nil
            }
            if shouldBlockInput {
                updateTextFieldText(resultText)
                return false
            }
        }

        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:))) {
            delegate.textField!(textField, shouldChangeCharactersIn: range, replacementString: string)
        }

        return true
    }

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldShouldClear(_:))) {
            return delegate.textFieldShouldClear!(textField)
        }

        return false
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let delegate = _responderDelegate(to: #selector(UITextFieldDelegate.textFieldShouldReturn(_:))) {
            return delegate.textFieldShouldReturn!(textField)
        }

        return true
    }

    func updatedText(_ range: NSRange, text: String) -> String {
        var textAfterUpdate: NSString = textField.text as NSString? ?? ""
        textAfterUpdate = textAfterUpdate.replacingCharacters(in: range, with: text) as NSString

        return textAfterUpdate as String
    }

    func updateTextFieldText(_ newText: String) {
        if let text = textField.text, text != newText {
            //Get selected range in text field. The lenght of range can be 0, it mean cursor is between characters
            let selectedRange: UITextRange? = textField.selectedTextRange
            let offset = newText.characters.count - text.characters.count

            textField.text = newText
            textField.sendActions(for: .editingChanged)

            if let selectedRange = selectedRange {
                //Get the new cursor position in text field. To get it, we are taking the offset from start of selected range and adding offset
                if let newPosition = textField.position(from: selectedRange.start, offset: offset) {
                    // set the new position
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
        }
    }

    func textFieldDidChangeEditing(_ textField: UITextField) {
        if editingInProcess {
            if delegateMethodCalled {
                let validators = self.validators.filter({ !$0.executeOnEnd })
                if validators.count > 0 {
                    self.textField.isValid.value = isValid
                }
            } else {
                let validators = self.validators.filter({ !$0.executeOnEnd && !$0.validateOnlyInput })
                for validator in validators {
                    do {
                        try validator.validate(oldText: nil, newText: textField.text!)
                    } catch let error {
                        if let error = error as? TextValidationError {
                            validationError = error
                        }
                        isValid = false
                        break
                    }
                }
                self.textField.isValid.value = isValid
            }
            delegateMethodCalled = false
        } else {
            let validators = self.validators.filter({ !$0.validateOnlyInput })
            for validator in validators {
                do {
                    try validator.validate(oldText: nil, newText: textField.text!)
                } catch let error {
                    if let error = error as? TextValidationError {
                        validationError = error
                    }
                    isValid = false
                    break
                }
            }
            self.textField.isValid.value = isValid
        }
    }

    func executeValidator(_ validator: TextValidator, textField: UITextField, range: NSRange, string: String, result resultText: inout String) -> TextValidationError? {
        switch (validator.validateOnlyInput, validator.shouldFormat) {
        case (true, true):
            do {
                let validatedString = try validator.validate(oldText: nil, newText: string)
                resultText = updatedText(range, text: validatedString)
            } catch let error {
                if let error = error as? TextValidationError {
                    return error
                }
                return TextValidationError.wrongInput
            }

        case (true, false):
            do {
                try validator.validate(oldText: nil, newText: string)
            } catch let error {
                if let error = error as? TextValidationError {
                    return error
                }
                return TextValidationError.wrongInput
            }

        case (false, true):
            do {
                resultText = try validator.validate(oldText: textField.text, newText: resultText)
            } catch let error {
                if let error = error as? TextValidationError {
                    return error
                }
                return TextValidationError.wrongFormat
            }

        case (false, false):
            do {
                try validator.validate(oldText: textField.text, newText: resultText)
            } catch let error {
                if let error = error as? TextValidationError {
                    return error
                }
                return TextValidationError.wrongFormat
            }
        }

        return nil
    }

    private func _responderDelegate(to aSelector: Selector) -> UITextFieldDelegate? {
        guard let delegate = self.textField.delegate, delegate.responds(to: aSelector) else {
            return delegate
        }

        return nil
    }
}
