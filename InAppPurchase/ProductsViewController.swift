//
//  ProductsViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation

// MARK: - Products View Controller

public protocol ProductsViewController : class
{
    var productManager : ProductManager? { get set }
}
