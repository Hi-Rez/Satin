//
//  PublishedDidSet.swift
//
//
//  Created by Reza Ali (inspired by Haris Ali) on 4/4/22.
//

import Combine
import Foundation

@propertyWrapper
public class PublishedDidSet<Value> {
    private var value: Value
    private let publisher: CurrentValueSubject<Value, Never>

    public init(wrappedValue value: Value) {
        self.value = value
        publisher = CurrentValueSubject(value)
        wrappedValue = value
    }

    public var wrappedValue: Value {
        set {
            value = newValue
            publisher.value = value
        }
        get { value }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }
}
