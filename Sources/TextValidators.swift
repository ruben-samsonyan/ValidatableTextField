//
// Created by Ruben Samsonyan on 26/07/16.
// Copyright (c) 2016 worldline. All rights reserved.
//

import Foundation

public struct AsPositiveNumber: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = true
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = false

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.isEmpty {
            return newText
        }
        if Double(newText) != nil {
            return newText
        }

        throw TextValidationError.wrongInput
    }
}

public struct AsRelativeNumber: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = true
    public var executeOnEnd: Bool = false

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.characters.last == "-", newText.characters.count > 1 {
            return oldText ?? ""
        }
        if newText.characters.first == "-", newText.characters.count == 1 {
            return newText
        }

        let newText = newText.replacingOccurrences(of: ",", with: ".")
        if newText.isEmpty {
            return newText
        }
        if Double(newText) != nil {
            let substrings = newText.components(separatedBy: ".")
            if substrings.count == 2 && substrings[1].characters.count > 2 { //decimal places should be 2 max
                throw TextValidationError.wrongInput
            }

            return newText
        }

        throw TextValidationError.wrongInput
    }
}

public struct AsDecimal: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = false
    public var decimalCount: Int = 2 //decimal places should be 2 by default

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        guard !newText.contains("."), !(decimalCount == 0 && newText.contains(",")) else { throw TextValidationError.wrongInput }

        let newText = newText.replacingOccurrences(of: ",", with: ".")

        if newText.isEmpty {
            return newText
        }

        if Double(newText) != nil {

            let substrings = newText.components(separatedBy: ".")
            if substrings.count == 2 {
                if substrings[1].characters.count > decimalCount {
                    throw TextValidationError.wrongInput
                }
            }

            return newText
        }

        throw TextValidationError.wrongInput
    }
}

public struct Max: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = true
    public var executeOnEnd: Bool = false

    let limit: Int

    public init(_ limit: Int) {
        self.limit = limit
    }

    public func validate(oldText: String?, newText: String) throws -> String {
        if let oldText = oldText {
            if oldText.characters.count == limit && newText.characters.count > oldText.characters.count {
                return oldText
            }
            if oldText.characters.count < limit && newText.characters.count > limit {
                let index = newText.characters.index(newText.startIndex, offsetBy: limit)
                return newText.substring(to: index)
            }
        }

        return newText
    }
}

public struct Min: TextValidator {
    public var shouldBlockInput: Bool = false
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = false

    let limit: Int

    public init(_ limit: Int) {
        self.limit = limit
    }

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.characters.count < limit {
            throw TextValidationError.wrongResult
        }

        return newText
    }
}

public struct Email: TextValidator {
    public var shouldBlockInput: Bool = false
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = true

    let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        let range = newText.range(of: regex, options:.regularExpression)
        if range != nil {
            return newText
        }

        throw TextValidationError.wrongResult
    }
}

public struct Password: TextValidator {
    public var shouldBlockInput: Bool = false
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = true

    //5 or more identical aphanumeric characters
    func hasConsecutiveIdenticalCharacters(_ text: String) -> Bool {
        let length = 5
        let characters = Array(text.characters)
        guard characters.count > length else { return false }

        for i in 0...max(characters.count - length, 0) {
            if characters[i] == characters[i+1] &&
                characters[i] == characters[i+2] &&
                characters[i] == characters[i+3] &&
                characters[i] == characters[i+4] {

                return true
            }
        }

        return false
    }

    func isDigitAscendingSequence(_ sequence: String) -> Bool {
        return "0123456789".contains(sequence)
    }

    func isDigitDescendingSequence(_ sequence: String) -> Bool {
        return "9876543210".contains(sequence)
    }

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        let length = 3
        //Minimum 6 characters / Maximum 25 characters
        if newText.characters.count < 6 || newText.characters.count > 25 {
            throw TextValidationError.wrongLength
        } else if hasConsecutiveIdenticalCharacters(newText) {
            throw TextValidationError.hasConsecutiveIdenticalCharacters
        } else if newText.characters.count >= length {
            for i in 0...max((newText.characters.count - length), 0) {
                let startIndex = newText.index(newText.startIndex, offsetBy: i)
                let endIndex = newText.index(newText.startIndex, offsetBy: i+length-1)
                let substring = newText[startIndex...endIndex]
                if isDigitAscendingSequence(substring) || isDigitDescendingSequence(substring) {
                    throw TextValidationError.hasNumericSequence
                }
            }
        }

        return newText
    }
}

public struct NotEmpty: TextValidator {
    public var shouldBlockInput: Bool = false
    public var validateOnlyInput: Bool = false
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = true

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.isEmpty {
            throw TextValidationError.wrongResult
        }

        return newText
    }
}

public struct Alpha: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = true
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = false

    let characterSet = CharacterSet.letters.inverted

    public init() {}

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.isEmpty {
            return newText
        }
        let range = newText.rangeOfCharacter(from: characterSet, options: .caseInsensitive)
        if range != nil {
            throw TextValidationError.wrongInput
        }

        return newText
    }
}

public struct CharacterSetTextValidator: TextValidator {
    public var shouldBlockInput: Bool = true
    public var validateOnlyInput: Bool = true
    public var shouldFormat: Bool = false
    public var executeOnEnd: Bool = false

    let characterSet: CharacterSet

    public init(characterSet: CharacterSet) {
        self.characterSet = characterSet
    }

    public func validate(oldText: String?, newText: String) throws -> String {
        if newText.isEmpty {
            return newText
        }
        let range = newText.rangeOfCharacter(from: characterSet, options: .caseInsensitive)
        if range != nil {
            throw TextValidationError.wrongInput
        }

        return newText
    }
}
