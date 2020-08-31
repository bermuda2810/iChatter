//
//  ListCompanyViewController.swift
//  iChatter
//
//  Created by Bui Quoc Viet on 8/31/20.
//  Copyright © 2020 NAL Viet Nam. All rights reserved.
//

import UIKit
import ESPullToRefresh

class ListStockViewController: BaseViewController {

    @IBOutlet weak var tblStock: UITableView!
    private var presenter : ListStockPresenter!
    private var stocks : Array<Stock> = []
    private var noMoreData : Bool = false
    private var isLoadingMore : Bool = false
    private var filterFavourite : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblStock.dataSource = self
        tblStock.delegate = self
        presenter = ListStockPresenter(self)
        
        tblStock.es.addPullToRefresh { [unowned self] in
            self.noMoreData = false
            self.isLoadingMore = false
            self.presenter.requestListStock(self.filterFavourite)
        }
        
        tblStock.es.addInfiniteScrolling { [unowned self ] in
            if (!self.noMoreData && !self.isLoadingMore) {
                self.isLoadingMore = true
                self.presenter.requestMoreStocks(self.filterFavourite)
            }else {
                self.tblStock.es.noticeNoMoreData()
            }
        }
    }
    
    public func onFilterChanged(_ filterFavourite : Int) {
        self.filterFavourite = filterFavourite
        self.noMoreData = false
        self.isLoadingMore = false
        self.tblStock.es.stopLoadingMore()
        self.tblStock.es.stopPullToRefresh()
        self.presenter.requestListStock(self.filterFavourite)
    }
    
    func onReady() {
        presenter.requestListStock(self.filterFavourite)
    }
}

extension ListStockViewController : StockViewCellDelegate {
    
    func onNeedLoadProfileAtIndexPath(_ indexPath : IndexPath, _ stock : Stock) {
        stock.indexPath = indexPath
        presenter.requestProfile(stock: stock)
    }
    
    func onChangedFavouriteAtIndexPath(_ indexPath: IndexPath, _ stock: Stock) {
        presenter.requestUpdateStock(stock: stock)
        self.stocks.remove(at: indexPath.row)
        tblStock.deleteRows(at: [indexPath], with: .fade)
    }
}


extension ListStockViewController : ListStockView {
    
    func onNewStocks(stocks: Array<Stock>) {
        tblStock?.es.stopPullToRefresh()
        
        self.stocks = stocks
        self.tblStock.reloadData()
    }
    
    func onLoadMoreStocks(stocks: Array<Stock>) {
        if stocks.count == 0 {
            noMoreData = true
        }
        tblStock?.es.stopLoadingMore()
        self.isLoadingMore = false
        for newStock in stocks {
            self.stocks.append(newStock)
        }
        self.tblStock.reloadData()
    }
    
    func onStockUpdated(_ newStock: Stock) {
        
        for stock in stocks {
            if stock.id == newStock.id {
                stock.profile = newStock.profile
                break
            }
        }
        
        if let cell = tblStock.cellForRow(at: newStock.indexPath!) {
            if ( (cell as! StockViewCell).stock.id == newStock.id) {
                tblStock.reloadRows(at: [newStock.indexPath!], with: .automatic)
            }
        }
    }
    
    
    func onLoadFail(_ errorCode: Int, _ errorMessage: String) {
        tblStock?.es.stopPullToRefresh()
    }
}

extension ListStockViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockViewCell") as! StockViewCell
        cell.bindStock(delegate : self, indexPath: indexPath, stock: stocks[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
}
