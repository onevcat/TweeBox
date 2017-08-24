//
//  ReplyTableViewController.swift
//  TweeBox
//
//  Created by 4faramita on 2017/8/23.
//  Copyright © 2017年 4faramita. All rights reserved.
//

import UIKit

class ReplyTableViewController: TimelineTableViewController {

    @IBOutlet weak var tweetInfoContainerView: UIView!
    
    private var retweet: Tweet?
    
    public var tweet: Tweet! {
        didSet {
            if let originTweet = tweet.retweetedStatus, tweet.text.hasPrefix("RT @") {
                retweet = tweet
                tweet = originTweet
            }
            
            if tweetID == nil {
                tweetID = tweet?.id
            }
        }
    }
    
    public var tweetID: String! {
        didSet {
            if tweet == nil {
                setTweet()
            }
        }
    }
    
    
    public var cellTextLabelHeight: CGFloat?
    private var hasMedia: Bool {
        if let media = tweet?.entities?.realMedia, media.count > 0 {
            return true
        } else {
            return false
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        for subview in (tweetInfoContainerView.subviews[0].subviews) {
            if subview.frame.height > 0, subview.subviews.count != 0 {
                tweetInfoContainerView?.frame.size.height = subview.frame.height + CGFloat(10)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshTimeline()
    }
    
    
    override func setAndPerformSegue() {
        
        let destinationViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReplyTableViewController")
        
        let segue = UIStoryboardSegue(identifier: "View Tweet", source: self, destination: destinationViewController) {
            self.navigationController?.show(destinationViewController, sender: self)
        }
        
        self.prepare(for: segue, sender: self)
        segue.perform()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "Single Tweet Info" {
            if let singleTweetViewController = segue.destination.content as? SingleTweetViewController {
                singleTweetViewController.tweet = tweet
            }
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
    override func refreshTimeline() {
        
        let replyTimelineParams = SearchTweetParams(
            query: "%40\(tweet?.user.screenName ?? "")",
            resultType: .recent,
            until: nil,
            sinceID: nil,
            maxID: nil,
            includeEntities: nil,
            resourceURL: ResourceURL.search_tweets
        )
        
        let replyTimeline = ReplyTimeline(
            maxID: maxID,
            sinceID: sinceID,
            fetchNewer: fetchNewer,
            resourceURL: replyTimelineParams.resourceURL,
            timelineParams: replyTimelineParams,
            mainTweetID: tweetID ?? ""
        )
        
        replyTimeline.fetchData { [weak self] (maxID, sinceID, tweets) in
            
            if let maxID = maxID {
                self?.maxID = maxID
            }
            if let sinceID = sinceID {
                self?.sinceID = sinceID
            }
            
            if tweets.count > 0 {
                
                self?.insertNewTweets(with: tweets)
                
                let cells = self?.tableView.visibleCells
                if cells != nil {
                    for cell in cells! {
                        let indexPath = self?.tableView.indexPath(for: cell)
                        if let tweetCell = cell as? TweetTableViewCell {
                            tweetCell.section = indexPath?.section
                        }
                    }
                    
                }
                
            }
            
            Timer.scheduledTimer(
                withTimeInterval: TimeInterval(0.1),
                repeats: false) { (timer) in
                    self?.refreshControl?.endRefreshing()
            }
        }

    }
    
    private func setTweet() {
        SingleTweet(
            tweetParams: TweetParams(of: tweetID!),
            resourceURL: ResourceURL.statuses_show_id
            ).fetchData { [weak self] (tweet) in
                if tweet != nil {
                    self?.tweet = tweet
                }
        }
    }
}
