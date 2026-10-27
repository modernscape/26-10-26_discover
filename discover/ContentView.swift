import SwiftUI
import SwiftData
import PhotosUI

// ==========================================
// 1. データモデルの定義
// ==========================================

@Model
class Dream {
    var goalTitle: String
    var goalValue: String
    var currentTitle: String
    var currentValue: String
    var imageData: Data?
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    init(
        goalTitle: String = "月収",
        goalValue: String = "100万円",
        currentTitle: String = "月収",
        currentValue: String = "35万円",
        imageData: Data? = nil
    ) {
        self.goalTitle = goalTitle
        self.goalValue = goalValue
        self.currentTitle = currentTitle
        self.currentValue = currentValue
        self.imageData = imageData
        self.items = []
    }
}

@Model
class Item {
    var title: String
    var impact: Double // 効力
    var ease: Double
    var merit: String
    var demerit: String
    var isCompleted: Bool
    var isHighlighted: Bool
    
    // 4つの評価項目（0〜4 の5段階）
    var moneyLevel: Int = 0
    var funLevel: Int = 0
    var easyStartLevel: Int = 0
    var comfortableLevel: Int = 0
    
    var dream: Dream?
    
    @Relationship(deleteRule: .cascade)
    var actions: [Action] = []
    
    init(title: String, impact: Double = 50.0, ease: Double = 50.0, merit: String = "", demerit: String = "", isCompleted: Bool = false, isHighlighted: Bool = false, moneyLevel: Int = 0, funLevel: Int = 0, easyStartLevel: Int = 0, comfortableLevel: Int = 0) {
        self.title = title
        self.impact = impact
        self.ease = ease
        self.merit = merit
        self.demerit = demerit
        self.isCompleted = isCompleted
        self.isHighlighted = isHighlighted
        self.moneyLevel = moneyLevel
        self.funLevel = funLevel
        self.easyStartLevel = easyStartLevel
        self.comfortableLevel = comfortableLevel
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
        Group {
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
        
        let item1 = Item(title: "転職", impact: 80.0, ease: 30.0, merit: "年収アップ確実", demerit: "準備に時間がかかる", isHighlighted: true, moneyLevel: 4, funLevel: 1, easyStartLevel: 2, comfortableLevel: 1)
        item1.actions = [
            Action(title: "履歴書・職務経歴書を作成する", done: true),
            Action(title: "エージェントに登録する", done: false)
        ]
        
        let item2 = Item(title: "エージェントから受注", impact: 70.0, ease: 60.0, merit: "すぐ始められる", demerit: "単価が変動する", isHighlighted: true, moneyLevel: 3, funLevel: 4, easyStartLevel: 1, comfortableLevel: 2)
        let item3 = Item(title: "App Storeで収益化", impact: 30.0, ease: 40.0, merit: "当たれば大きい", demerit: "時間がかかる", isHighlighted: false)
        let item4 = Item(title: "起業", impact: 95.0, ease: 10.0, merit: "リターンが大きい", demerit: "ハイリスク", isHighlighted: false)
        
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
                    Label("追い風アクション", systemImage: "list.bullet")
                }
            
            HighlightedItemsView(dream: dream)
                .tabItem {
                    Label("有力候補", systemImage: "star.fill")
                }
        }
    }
}

// ==========================================
// 4. 「追い風アクション」タブのビュー
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
    @State private var newMerit = ""
    @State private var newDemerit = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    @State private var sortCriterion: SortCriterion = .impact
    @State private var isDescending = true
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case goalTitle, goalValue, currentTitle, currentValue
    }
    
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
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- ヘッダー部分 ---
                VStack(spacing: 12) {
                    HStack(alignment: .center, spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let data = dream.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "photo.badge.plus")
                                        .font(.title2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    dream.imageData = data
                                }
                            }
                        }
                        
                        VStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dream Goal")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack(spacing: 8) {
                                    TextField("項目", text: $dream.goalTitle)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .goalTitle)
                                        .clearButton(text: $dream.goalTitle, isFocused: focusedField == .goalTitle)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                        .frame(width: 100)
                                    
                                    TextField("値", text: $dream.goalValue)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .goalValue)
                                        .clearButton(text: $dream.goalValue, isFocused: focusedField == .goalValue)
                                        .font(.title3)
                                        .bold()
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Current Status")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .textCase(.uppercase)
                                
                                HStack(spacing: 8) {
                                    TextField("項目", text: $dream.currentTitle)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .currentTitle)
                                        .clearButton(text: $dream.currentTitle, isFocused: focusedField == .currentTitle)
                                        .foregroundColor(.red)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                        .frame(width: 100)
                                    
                                    TextField("値", text: $dream.currentValue)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($focusedField, equals: .currentValue)
                                        .clearButton(text: $dream.currentValue, isFocused: focusedField == .currentValue)
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // ★ アイコンの説明
                    HStack(spacing: 16) {
                        LegendItemView(systemImage: "yensign.circle.fill", label: "収入", color: Color(hex: "222222"))
                        LegendItemView(systemImage: "fireworks", label: "ワクワク", color: Color(hex: "222222"))
                        LegendItemView(systemImage: "figure.walk", label: "手軽さ", color: Color(hex: "222222"))
                        LegendItemView(systemImage: "figure.mind.and.body", label: "快適", color: Color(hex: "222222"))
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color(.systemGroupedBackground))
                
                List {
                    ForEach(sortedItems) { item in
                        ItemRowView(item: item, dream: dream)
                    }
                }
                .listStyle(.insetGrouped)
                .animation(.easeInOut(duration: 0.3), value: sortedItems.map { $0.id })
                .animation(.easeInOut(duration: 0.3), value: sortCriterion)
                .animation(.easeInOut(duration: 0.3), value: isDescending)
            }
            .navigationTitle("Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Menu {
                            Section("並び替え基準") {
                                Button(action: { sortCriterion = .impact }) {
                                    HStack {
                                        Text("効力 (Impact)")
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
                                .submitLabel(.done)
                            
                            TextField("メリット", text: $newMerit, axis: .vertical)
                                .submitLabel(.done)
                            
                            TextField("デメリット", text: $newDemerit, axis: .vertical)
                                .submitLabel(.done)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("効力: \(Int(newImpact))%")
                                Slider(value: $newImpact, in: 0...100, step: 5)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("やり易さ: \(Int(newEase))%")
                                Slider(value: $newEase, in: 0...100, step: 5)
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
                                    let item = Item(title: newTitle, impact: newImpact, ease: newEase, merit: newMerit, demerit: newDemerit)
                                    dream.items.append(item)
                                    newTitle = ""
                                    newMerit = ""
                                    newDemerit = ""
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
// 5. 「有力候補」タブのビュー
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
                        "有力候補がありません",
                        systemImage: "star",
                        description: Text("「追い風アクション」タブで右上の星ボタンを押して星をつけると、ここに表示されます。")
                    )
                } else {
                    List {
                        ForEach(Array(highlightedItems.enumerated()), id: \.element.id) { index, item in
                            HighlightedItemRowView(index: index + 1, item: item, dream: dream)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("有力候補")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ==========================================
// 6. 「有力候補」タブ専用の行ビュー
// ==========================================

struct HighlightedItemRowView: View {
    let index: Int
    @Bindable var item: Item
    var dream: Dream
    
    @State private var tempImpact: Double? = nil
    @State private var tempEase: Double? = nil
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isMeritFocused: Bool
    @FocusState private var isDemeritFocused: Bool
    
    @State private var showingDeleteAlert = false
    
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
    
    private var easeColor: Color {
        let brightness = 0.85 - (currentEase / 100.0) * 0.75
        return Color(white: brightness)
    }
    
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
        default: return "\(number).circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            HStack(spacing: 12) {
                Image(systemName: encircledSystemImage(for: index))
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
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
                    .textInputAutocapitalization(.never)
                    .focused($isTitleFocused)
                    .clearButton(text: $item.title, isFocused: isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit { isTitleFocused = false }
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Button(action: {
                    withAnimation {
                        item.isHighlighted.toggle()
                    }
                }) {
                    Image(systemName: item.isHighlighted ? "star.fill" : "star")
                        .foregroundColor(item.isHighlighted ? .orange : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // --- 効力スライダー（幅100%） ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("効力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(currentImpact))%")
                        .font(.caption)
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
            }
            
            // --- やり易さスライダー（幅50%） ＆ 右側の空白に4つの評価ボタン ---
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("やり易さ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(currentEase))%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(easeColor)
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
                    .accentColor(easeColor)
                }
                .frame(width: UIScreen.main.bounds.width * 0.5)
                
                // 右側の空白に4つのアイコンボタン（5段階評価）
                HStack(spacing: 8) {
                    ScoreButtonView(title: "収入", systemImage: "yensign.circle.fill", level: $item.moneyLevel)
                    ScoreButtonView(title: "ワクワク", systemImage: "fireworks", level: $item.funLevel)
                    ScoreButtonView(title: "手軽さ", systemImage: "figure.walk", level: $item.easyStartLevel)
                    ScoreButtonView(title: "快適", systemImage: "figure.mind.and.body", level: $item.comfortableLevel)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // --- 下段：左にメリット、右にデメリット ---
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("メリット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("メリット", text: $item.merit, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .focused($isMeritFocused)
                        .clearButton(text: $item.merit, isFocused: isMeritFocused)
                        .submitLabel(.done)
                        .onChange(of: item.merit) { _, newValue in
                            if newValue.hasSuffix("\n") {
                                item.merit = String(newValue.dropLast())
                                isMeritFocused = false
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("デメリット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("デメリット", text: $item.demerit, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .focused($isDemeritFocused)
                        .clearButton(text: $item.demerit, isFocused: isDemeritFocused)
                        .submitLabel(.done)
                        .onChange(of: item.demerit) { _, newValue in
                            if newValue.hasSuffix("\n") {
                                item.demerit = String(newValue.dropLast())
                                isDemeritFocused = false
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
            
            Divider()
                .padding(.vertical, 2)
            
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
        .contentShape(Rectangle())
        .onLongPressGesture {
            showingDeleteAlert = true
        }
        .alert("アイテムの削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let index = dream.items.firstIndex(where: { $0.id == item.id }) {
                    dream.items.remove(at: index)
                }
            }
        } message: {
            Text("「\(item.title.isEmpty ? "無題" : item.title)」を削除しますか？")
        }
    }
}

// ==========================================
// 7. 各アクション行のビュー
// ==========================================

struct ActionRowView: View {
    let index: Int
    @Bindable var action: Action
    var onDelete: () -> Void
    
    @FocusState private var isActionFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(index)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16, alignment: .leading)
            
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
                .focused($isActionFocused)
                .clearButton(text: $action.title, isFocused: isActionFocused)
                .submitLabel(.done)
                .onSubmit { isActionFocused = false }
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
        .padding(2)
    }
}

// ==========================================
// 8. 「追い風アクション」タブ用の個別アイテム行ビュー
// ==========================================

struct ItemRowView: View {
    @Bindable var item: Item
    var dream: Dream
    
    @State private var tempImpact: Double? = nil
    @State private var tempEase: Double? = nil
    
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isMeritFocused: Bool
    @FocusState private var isDemeritFocused: Bool
    
    @State private var showingDeleteAlert = false
    
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
    
    private var easeColor: Color {
        let brightness = 0.85 - (currentEase / 100.0) * 0.75
        return Color(white: brightness)
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
                
                TextField("行動を入力", text: $item.title)
                    .font(.headline)
                    .focused($isTitleFocused)
                    .clearButton(text: $item.title, isFocused: isTitleFocused)
                    .submitLabel(.done)
                    .onSubmit { isTitleFocused = false }
                    .strikethrough(item.isCompleted, color: .secondary)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Button(action: {
                    withAnimation {
                        item.isHighlighted.toggle()
                    }
                }) {
                    Image(systemName: item.isHighlighted ? "star.fill" : "star")
                        .foregroundColor(item.isHighlighted ? .orange : .secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // --- 効力スライダー（幅100%） ---
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("効力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(currentImpact))%")
                        .font(.caption)
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
            }
            
            // --- やり易さスライダー（幅50%） ＆ 右側の空白に4つの評価ボタン ---
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("やり易さ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(currentEase))%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(easeColor)
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
                    .accentColor(easeColor)
                }
                .frame(width: UIScreen.main.bounds.width * 0.5)
                
                // 右側の空白に4つのアイコンボタン（5段階評価）
                HStack(spacing: 8) {
                    ScoreButtonView(title: "収入", systemImage: "yensign.circle.fill", level: $item.moneyLevel)
                    ScoreButtonView(title: "ワクワク", systemImage: "fireworks", level: $item.funLevel)
                    ScoreButtonView(title: "手軽さ", systemImage: "figure.walk", level: $item.easyStartLevel)
                    ScoreButtonView(title: "快適", systemImage: "figure.mind.and.body", level: $item.comfortableLevel)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // --- 下段：左にメリット、右にデメリット ---
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("メリット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("メリット", text: $item.merit, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .focused($isMeritFocused)
                        .clearButton(text: $item.merit, isFocused: isMeritFocused)
                        .submitLabel(.done)
                        .onChange(of: item.merit) { _, newValue in
                            if newValue.hasSuffix("\n") {
                                item.merit = String(newValue.dropLast())
                                isMeritFocused = false
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("デメリット")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("デメリット", text: $item.demerit, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .font(.subheadline)
                        .focused($isDemeritFocused)
                        .clearButton(text: $item.demerit, isFocused: isDemeritFocused)
                        .submitLabel(.done)
                        .onChange(of: item.demerit) { _, newValue in
                            if newValue.hasSuffix("\n") {
                                item.demerit = String(newValue.dropLast())
                                isDemeritFocused = false
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
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
        .padding(.vertical, 2)
        .opacity(item.isCompleted ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showingDeleteAlert = true
        }
        .alert("アイテムの削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let index = dream.items.firstIndex(where: { $0.id == item.id }) {
                    dream.items.remove(at: index)
                }
            }
        } message: {
            Text("「\(item.title.isEmpty ? "無題" : item.title)」を削除しますか？")
        }
    }
}

// ==========================================
// 9. アイコン説明用のヘルパービュー
// ==========================================

struct LegendItemView: View {
    let systemImage: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// ==========================================
// 10. 5段階評価ボタン用のコンポーネント
// ==========================================

struct ScoreButtonView: View {
    let title: String
    let systemImage: String
    @Binding var level: Int // 0, 1, 2, 3, 4 の5段階
    
    // 5段階のカラー定義（4番目に緑 #00AC24 を配置）
    private let grayColor = Color(hex: "6E6E6E")   // レベル0 (△)
    private let yellowColor = Color(hex: "FAD000") // レベル1 (◯)
    private let cyanColor = Color(hex: "00F9F7")   // レベル2 (◎)
    private let greenColor = Color(hex: "00AC24")  // レベル3 (moon.stars)
    private let pinkColor = Color(hex: "F84390")   // レベル4 (💎)
    
    private var buttonColor: Color {
        switch level {
        case 0: return grayColor
        case 1: return yellowColor
        case 2: return cyanColor
        case 3: return greenColor
        case 4: return pinkColor
        default: return grayColor
        }
    }
    
    // 5段階の記号表示（レベル3を "moon.stars" に変更）
    private var levelText: String {
        switch level {
        case 0: return "△"
        case 1: return "◯"
        case 2: return "◎"
        case 3: return "🌙✨" // ※コード内ではテキスト表示ですが、以下のようにImageを使うことも可能です
        case 4: return "💎"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: {
            // タップするたびに 0 → 1 → 2 → 3 → 4 → 0 と循環
            level = (level + 1) % 5
        }) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .foregroundColor(buttonColor)
                
                // レベル3のときはテキストの代わりにSF Symbolsの moon.stars を表示
                if level == 3 {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(buttonColor)
                        .frame(height: 12)
                } else {
                    Text(levelText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(buttonColor)
                        .frame(height: 12)
                }
            }
            .frame(width: 28, height: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Hexカラーを扱うための拡張
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

// ==========================================
// 11. フォーカス中のみ表示されるクリアボタン拡張
// ==========================================

extension View {
    func clearButton(text: Binding<String>, isFocused: Bool) -> some View {
        self.modifier(ClearButtonModifier(text: text, isFocused: isFocused))
    }
}

struct ClearButtonModifier: ViewModifier {
    @Binding var text: String
    var isFocused: Bool
    
    func body(content: Content) -> some View {
        HStack {
            content
            if isFocused && !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
