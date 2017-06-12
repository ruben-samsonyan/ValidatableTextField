//
// Created by Ruben Samsonyan on 26/07/16.
// Copyright (c) 2016 worldline. All rights reserved.
//

import Foundation

public protocol TextValidator {
    var shouldBlockInput: Bool { get }
    var validateOnlyInput: Bool { get }
    var shouldFormat: Bool { get }
    var executeOnEnd: Bool { get }
    @discardableResult func validate(oldText: String?, newText: String) throws -> String
}
