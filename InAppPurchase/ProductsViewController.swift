//
//  ProductsViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit

// MARK: - Products View Controller

public protocol ProductsViewControllerDelegate
{
    func productsControllerCancelled(controller: ProductsViewController)
    
    func productsController(controller: ProductsViewController, didPurchase product: SKProduct)
    
    func productsController(controller: ProductsViewController, didEncounterError: ErrorType)
}

public protocol ProductsViewController : class
{
    var productsDelegate : ProductsViewControllerDelegate? { get set }
}
