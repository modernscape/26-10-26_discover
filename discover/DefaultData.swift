//
//  DefaultData.swift
//  discover
//
//  Created by forest on 2026/10/28.
//

import Foundation

func defaultData() {
    let defaultDream = Dream(
        goalTitle: "ライフワーク",
        goalValue: "起業",
        currentTitle: "仕事",
        currentValue: "会社員"
    )
    
    let item1 = Item(title: "世の中の問題に目を向ける", impact: 90.0, ease: 30.0, merit: "人の役に立てる！", demerit: "すでに他の人が気づいてる？", isHighlighted: true, moneyLevel: 4, funLevel: 4, contributionLevel: 5, comfortableLevel: 2, easyStartLevel: 1)
    item1.actions = [
        Action(title: "人にはどんな悩み・苦しみがあるか観察する", done: true),
        Action(title: "不満・不都合・不具合・不便・不平等・不条理、に目を向ける", done: false)
    ]
    
    let item2 = Item(title: "自分の好きなことを探究する", impact: 70.0, ease: 80.0, merit: "楽しい✨✨", demerit: "それでお金になるかは分からない。。", isHighlighted: false, moneyLevel: 3, funLevel: 5, contributionLevel: 3, comfortableLevel: 5, easyStartLevel: 4)
    item1.actions = [
        Action(title: "お金を払っててもしたいことは何か？", done: true),
        Action(title: "突然仕事が休みになったら何をする？", done: false)
    ]
    
}

