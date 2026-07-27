//
//  HelpView.swift
//  cards
//
//  欢迎页「帮助说明」：规则、模式、设置入口指引（主页只保留入口按钮）。
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("比点数接近 21 且不爆牌。庄家点数小于 17 必须要牌，大于等于 17 停牌（软 17 同停）。天然黑杰克赔率 3:2，普通获胜 1:1，平局退注。")
                } header: {
                    Text("基本规则")
                }

                Section {
                    Text("有筹码与庄家资金池。打穿庄家或累计赢码可解锁更高关卡，新会话双方起始筹码随关提升。注码三档单选；开局全下需本会话打满设置中的解锁局数（可配置，默认 5；设为 0 则开局可用）。玩法道具在闯关中不可用。")
                    Text("当前关卡、起始筹码与距下一关差额见「战绩」；成就与道具兑换见「成就」。卡背解锁也主要看闯关表现。")
                } header: {
                    Text("闯关挑战")
                }

                Section {
                    Text("独立娱乐阶梯：打穿或累计赢码升阶，本阶起始筹码与注码随之提升。已解锁的玩法道具仅在此模式可用（见牌后再全下、软 17 要牌、窥视、换一张、换庄家一张等）。支持「同上局」下注；切牌固定为真实渗透（不受设置页切牌选项影响）。")
                    Text("娱乐对局计入娱乐成就轨，不计入闯关成就。当前阶、注码与距下一阶差额见「战绩」。")
                } header: {
                    Text("娱乐模式")
                }

                Section {
                    Text("默认牌副、闯关切牌三态（每局重洗 / 仪式感 / 真实）、闯关桌限、全下解锁局数、卡背、音效与触觉：均在「设置」中调整。改牌副、桌限或全下解锁局数后，请返回主页再开新局。")
                    Text("「战绩」展示关卡/阶梯进度与胜负摘要；「成就」展示成就与道具兑换。")
                } header: {
                    Text("设置 · 成就 · 战绩")
                }

                Section {
                    Text("本应用面向练习与娱乐，规则为简化版赌场二十一点，不等同于线下赌场全部选项（如分牌、保险等尚未开放）。")
                } header: {
                    Text("说明")
                }
            }
            .navigationTitle("帮助说明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}
