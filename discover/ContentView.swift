import SwiftUI
import SwiftData

// ==========================================
// 1. データモデルの定義
// ==========================================

@Model
class Dream {
    var goalTitle: String
    var goalValue: String
    var currentTitle: String
    var currentValue: String
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    init(
        goalTitle: String = "月収",
        goalValue: String = "100万円",
        currentTitle: String = "月収",
        currentValue: String = "35万円"
    ) {
        self.goalTitle = goalTitle
        self.goalValue = goalValue
        self.currentTitle = currentTitle
        self.currentValue = currentValue
        self.items = []
    }
}

@Model
class Item {
    var title: String
    var impact: Double
    var ease: Double
    var isCompleted: Bool
    var isHighlighted: Bool
    
    var dream: Dream?
    
    @Relationship(deleteRule: .cascade)
    var actions: [Action] = []
    
    init(title: String, impact: Double = 50.0, ease: Double = 50.0, isCompleted: Bool = false, isHighlighted: Bool = false) {
        self.title = title
        self.impact = impact
        self.ease = ease
        self.isCompleted = isCompleted
        self.isHighlighted = isHighlighted
        self.actions = []
    }
}

@Model
class Action {
    var title: String
    var done: Bool
    
    var item: Item?
    
    init(title: String, done: Bool = false) {
        self.title = title
        self.done = done
    }
}

// ==========================================
// 2. メインビュー
// ==========================================

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dreams: [Dream]
    
    var body: some View {
        NavigationStack {
            if let dream = dreams.first {
                MainTabView(dream: dream, modelContext: modelContext)
            } else {
                ProgressView()
                    .onAppear {
                        setupInitialData(context: modelContext)
                    }
            }
        }
    }
    
    private func setupInitialData(context: ModelContext) {
        let defaultDream = Dream(
            goalTitle: "月収",
            goalValue: "100万円",
            currentTitle: "月収",
            currentValue: "35万円"
        )
        
        let item1 = Item(title: "転職", impact: 80.0, ease: 30.0, isHighlighted: true)
        item1.actions = [
            Action(title: "履歴書・職務経歴書を作成する", done: true),
            Action(title: "エージェントに登録する", done: false)
        ]
        
        let item2 = Item(title: "エージェントから受注", impact: 70.0, ease: 60.0, isHighlighted: true)
        let item3 = Item(title: "App Storeで収益化", impact: 30.0, ease: 40.0, isHighlighted: false)
        let item4 = Item(title: "起業", impact: 95.0, ease: 10.0, isHighlighted: false)
        
        defaultDream.items = [item1, item2, item3, item4]
        context.insert(defaultDream)
    }
}

// ==========================================
// 3. タブバー管理ビュー
// ==========================================

struct MainTabView: View {
    @Bindable var dream: Dream
    var modelContext: ModelContext
    
    var body: some View {
        TabView {
            DreamDetailView(dream: dream, modelContext: modelContext, isHighlightedOnly: false)
                .tabItem {
                    Label("案", systemImage: "lightbulb.fill")
                }
            
            HighlightedItemsView(dream: dream)
                .tabItem {
                    Label("有力", systemImage: "star.fill")
                }
        }
    }
}

// ==========================================
// 4. 「案」タブのビュー
// ==========================================

enum SortCriterion {
    case impact
    case ease
}

struct DreamDetailView: View {
    @Bindable var dream: Dream
    var modelContext: ModelContext
    var isHighlightedOnly: Bool
    
    @State private var isAddingItem = false
    @State private var newTitle = ""
    @State private var newImpact: Double = 50.0
    @State private var newEase: Double = 50.0
    
    @State private var sortCriterion: SortCriterion = .impact
    @State private var isDescending = true
    
    private var sortedItems: [Item] {
        let targetItems = isHighlightedOnly ? dream.items.filter { $0.isHighlighted } : dream.items
        return targetItems.sorted { item1, item2 in
            switch sortCriterion {
            case .impact:
                return isDescending ? item1.impact > item2.impact : item1.impact < item2.impact
            case .ease:
                return isDescending ? item1.ease > item2.ease : item1.ease < item2.ease
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dream Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        TextField("項目", text: $dream.goalTitle)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        
                        TextField("値", text: $dream.goalValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .bold()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        TextField("項目", text: $dream.currentTitle)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 110)
                        
                        TextField("値", text: $dream.currentValue)
                            .textFieldStyle(.roundedBorder)
                            .font(.headline)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGroupedBackground))
            
            List {
                ForEach(sortedItems) { item in
                    ItemRowView(item: item)
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.insetGrouped)
            .animation(.easeInOut(duration: 0.3), value: sortedItems.map { $0.id })
            .animation(.easeInOut(duration: 0.3), value: sortCriterion)
            .animation(.easeInOut(duration: 0.3), value: isDescending)
        }
        .navigationTitle("案の一覧")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Section("並び替え基準") {
                            Button(action: { sortCriterion = .impact }) {
                                HStack {
                                    Text("影響度 (Impact)")
                                    if sortCriterion == .impact { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { sortCriterion = .ease }) {
                                HStack {
                                    Text("やり易さ (Ease)")
                                    if sortCriterion == .ease { Image(systemName: "checkmark") }
                                }
                            }
                        }
                        
                        Section("順序") {
                            Button(action: { isDescending = true }) {
                                HStack {
                                    Text("高い順 (降順)")
                                    if isDescending { Image(systemName: "checkmark") }
                                }
                            }
                            Button(action: { isDescending = false }) {
                                HStack {
                                    Text("低い順 (昇順)")
                                    if !isDescending { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title2)
                    }
                    
                    Button(action: { isAddingItem = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingItem) {
            NavigationStack {
                Form {
                    Section(header: Text("新しい行動の追加")) {
                        TextField("行動名（例: スキルを学ぶ）", text: $newTitle)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("影響度: \(Int(newImpact))%")
                            Slider(value: $newImpact, in: 0...100, step: 5)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("やり易さ: \(Int(newEase))%")
                            Slider(value: $newEase, in: 0...100, step: 5)
                                .accentColor(.green)
                        }
                    }
                }
                .navigationTitle("行動を追加")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { isAddingItem = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("追加") {
                            if !newTitle.isEmpty {
                                let item = Item(title: newTitle, impact: newImpact, ease: newEase)
                                dream.items.append(item)
                                newTitle = ""
                                newImpact = 50.0
                                newEase = 50.0
                                isAddingItem = false
                            }
                        }.bold()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let itemToDelete = sortedItems[index]
            if let originalIndex = dream.items.firstIndex(where: { $0.id == itemToDelete.id }) {
                dream.items.remove(at: originalIndex)
            }
        }
    }
}

// ==========================================
// 5. 「有力」タブのビュー
// ==========================================

struct HighlightedItemsView: View {
    @Bindable var dream: Dream
    
    private var highlightedItems: [Item] {
        dream.items.filter { $0.isHighlighted }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if highlightedItems.isEmpty {
                    ContentUnavailableView(
                        "有力な案がありません",
                        systemImage: "star",
                        description: Text("「案」タブでアイテムを長押しして星（⭐️）をつけると、ここに表示されます。")
                    )
                } else {
                    List {
                        ForEach(Array(highlightedItems.enumerated()), id: \.element.id) { index, item in
                            HighlightedItemRowView(index: index + 1, item: item)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("有力なアクション")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ==========================================
// 6. 「有力」タブ専用の行ビュー（丸囲み数字アイコン対応）
// ==========================================

struct HighlightedItemRowView: View {
    let index: Int
    @Bindable var item: Item
    
    @State private var tempImpact: Double? = nil
    @State private var tempEase: Double? = nil
    
    private var currentImpact: Double {
        tempImpact ?? item.impact
    }
    
    private var currentEase: Double {
        tempEase ?? item.ease
    }
    
    private var impactColor: Color {
        let hue = (1.0 - (currentImpact / 100.0)) * 0.6
        return Color(hue: hue, saturation: 0.8, brightness: 0.9)
    }
    
    // ★ 1〜50までの丸囲み数字アイコンのシステム名を返すヘルパー
    private func encircledSystemImage(for number: Int) -> String {
        switch number {
        case 1: return "1.circle.fill"
        case 2: return "2.circle.fill"
        case 3: return "3.circle.fill"
        case 4: return "4.circle.fill"
        case 5: return "5.circle.fill"
        case 6: return "6.circle.fill"
        case 7: return "7.circle.fill"
        case 8: return "8.circle.fill"
        case 9: return "9.circle.fill"
        case 10: return "10.circle.fill"
        default: return "\(number).circle.fill" // 11以降もSF Symbolsがあれば対応
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // --- 1段目：丸囲み数字アイコン ＋ チェックボックス ＋ 行動名 ---
            HStack(spacing: 12) {
                // ★ 丸囲み数字（色付き円 ＋ 大きめの数字デザイン）
                Image(systemName: encircledSystemImage(for: index))
                    .font(.title2) // やや大きめのサイズ
                    .foregroundColor(.accentColor) // テーマカラーの円・数字
                
                Button(action: {
                    item.isCompleted.toggle()
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundColor(item.isCompleted ? impactColor : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                
                TextField("行動を入力", text: $item.title)
                    .font(.headline)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Spacer()
                
                Text("影響度: \(Int(currentImpact))%")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(impactColor)
            }
            
            // 影響度スライダー
            Slider(
                value: Binding(
                    get: { tempImpact ?? item.impact },
                    set: { tempImpact = $0 }
                ),
                in: 0...100,
                step: 5,
                onEditingChanged: { editing in
                    if editing {
                        tempImpact = item.impact
                    } else {
                        if let finalValue = tempImpact {
                            item.impact = finalValue
                            tempImpact = nil
                        }
                    }
                }
            )
            .accentColor(impactColor)
            
            // やり易さスライダー
            HStack {
                Text("やり易さ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(currentEase))%")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.green)
            }
            
            Slider(
                value: Binding(
                    get: { tempEase ?? item.ease },
                    set: { tempEase = $0 }
                ),
                in: 0...100,
                step: 5,
                onEditingChanged: { editing in
                    if editing {
                        tempEase = item.ease
                    } else {
                        if let finalValue = tempEase {
                            item.ease = finalValue
                            tempEase = nil
                        }
                    }
                }
            )
            .accentColor(.green)
            
            // --- アクションセクション ---
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("具体的なアクション")
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            let newAction = Action(title: "")
                            item.actions.append(newAction)
                        }
                    }) {
                        Label("アクション追加", systemImage: "plus.circle.fill")
                            .font(.caption)
                            .bold()
                    }
                    .buttonStyle(.borderless)
                }
                
                if !item.actions.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(item.actions.enumerated()), id: \.element.id) { actIndex, action in
                            ActionRowView(index: actIndex + 1, action: action) {
                                if let targetIndex = item.actions.firstIndex(where: { $0.id == action.id }) {
                                    item.actions.remove(at: targetIndex)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
        .padding(10)
        .padding(.vertical, 2)
        .opacity(item.isCompleted ? 0.6 : 1.0)
    }
}

// ==========================================
// 7. 各アクション行のビュー
// ==========================================

struct ActionRowView: View {
    let index: Int
    @Bindable var action: Action
    var onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(index).")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20, alignment: .leading)
            
            Button(action: {
                action.done.toggle()
            }) {
                Image(systemName: action.done ? "checkmark.square.fill" : "square")
                    .foregroundColor(action.done ? .accentColor : .secondary)
                    .font(.body)
            }
            .buttonStyle(.plain)
            
            TextField("アクションを入力", text: $action.title)
                .font(.subheadline)
                .strikethrough(action.done, color: .secondary)
                .foregroundColor(action.done ? .secondary : .primary)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// ==========================================
// 8. 「案」タブ用の個別アイテム行ビュー
// ==========================================

struct ItemRowView: View {
    @Bindable var item: Item
    
    @State private var tempImpact: Double? = nil
    @State private var tempEase: Double? = nil
    
    private var currentImpact: Double {
        tempImpact ?? item.impact
    }
    
    private var currentEase: Double {
        tempEase ?? item.ease
    }
    
    private var impactColor: Color {
        let hue = (1.0 - (currentImpact / 100.0)) * 0.6
        return Color(hue: hue, saturation: 0.8, brightness: 0.9)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button(action: {
                    item.isCompleted.toggle()
                }) {
                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                        .foregroundColor(item.isCompleted ? impactColor : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 4) {
                    if item.isHighlighted {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                    }
                    
                    TextField("行動を入力", text: $item.title)
                        .font(.headline)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .foregroundColor(item.isCompleted ? .secondary : .primary)
                }
                
                Spacer()
                
                Text("影響度: \(Int(currentImpact))%")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(impactColor)
            }
            
            Slider(
                value: Binding(
                    get: { tempImpact ?? item.impact },
                    set: { tempImpact = $0 }
                ),
                in: 0...100,
                step: 5,
                onEditingChanged: { editing in
                    if editing {
                        tempImpact = item.impact
                    } else {
                        if let finalValue = tempImpact {
                            item.impact = finalValue
                            tempImpact = nil
                        }
                    }
                }
            )
            .accentColor(impactColor)
            
            HStack {
                Text("やり易さ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(currentEase))%")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.green)
            }
            
            Slider(
                value: Binding(
                    get: { tempEase ?? item.ease },
                    set: { tempEase = $0 }
                ),
                in: 0...100,
                step: 5,
                onEditingChanged: { editing in
                    if editing {
                        tempEase = item.ease
                    } else {
                        if let finalValue = tempEase {
                            item.ease = finalValue
                            tempEase = nil
                        }
                    }
                }
            )
            .accentColor(.green)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isHighlighted ? Color.orange.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isHighlighted ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .onLongPressGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                item.isHighlighted.toggle()
            }
        }
        .padding(.vertical, 2)
        .opacity(item.isCompleted ? 0.6 : 1.0)
    }
}
