//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

class ProductsManager: NSObject {

    let productsFetcherSK1: ProductsFetcherSK1

    private let systemInfo: SystemInfo

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private(set) lazy var productsFetcherSK2 = ProductsFetcherSK2()

    init(
        productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
        systemInfo: SystemInfo,
        requestTimeout: DispatchTimeInterval = .seconds(30)
    ) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                     requestTimeout: requestTimeout)
        self.systemInfo = systemInfo
    }

    func productsFromOptimalStoreKitVersion(withIdentifiers identifiers: Set<String>,
                                            completion: @escaping (Result<Set<StoreProduct>, Error>) -> Void) {

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.useStoreKit2IfAvailable {
            _ = Task<Void, Never> {
                do {
                    let storeProduct = try await self.sk2StoreProduct(withIdentifiers: identifiers)
                    completion(.success(storeProduct))
                } catch {
                    completion(.failure(error))
                }
            }
        } else {
            productsFetcherSK1.products(withIdentifiers: identifiers, completion: completion)
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func productsFromOptimalStoreKitVersion(
        withIdentifiers identifiers: Set<String>
    ) async throws -> Set<StoreProduct> {
        return try await withCheckedThrowingContinuation { continuation in
            productsFromOptimalStoreKitVersion(withIdentifiers: identifiers) { result in
                continuation.resume(with: result)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2StoreProduct(withIdentifiers identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        let storeProduct = try await productsFetcherSK2.products(identifiers: identifiers)

        return Set(storeProduct)
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Result<Set<SK1Product>, Error>) -> Void) {
        return productsFetcherSK1.sk1Products(withIdentifiers: identifiers, completion: completion)
    }

    func cacheProduct(_ product: SK1Product) {
        productsFetcherSK1.cacheProduct(product)
    }

}
