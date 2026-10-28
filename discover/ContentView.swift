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
    var impact: Double // 追い風力
    var ease: Double
    var merit: String
    var demerit: String
    var isCompleted: Bool
    var isHighlighted: Bool // 神風フラグ
    
    // 5つの評価項目（0〜5 の6段階）
    var moneyLevel: Int = 0
    var funLevel: Int = 0
    var contributionLevel: Int = 0
    var comfortableLevel: Int = 0
    var easyStartLevel: Int = 0
    
    var dream: Dream?
    
    @Relationship(deleteRule: .cascade)
    var actions: [Action] = []
    
    init(title: String, impact: Double = 50.0, ease: Double = 50.0, merit: String = "", demerit: String = "", isCompleted: Bool = false, isHighlighted: Bool = false, moneyLevel: Int = 0, funLevel: Int = 0, contributionLevel: Int = 0, comfortableLevel: Int = 0, easyStartLevel: Int = 0) {
        self.title = title
        self.impact = impact
        self.ease = ease
        self.merit = merit
        self.demerit = demerit
        self.isCompleted = isCompleted
        self.isHighlighted = isHighlighted
        self.moneyLevel = moneyLevel
        self.funLevel = funLevel
        self.contributionLevel = contributionLevel
        self.comfortableLevel = comfortableLevel
        self.easyStartLevel = easyStartLevel
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
        
        let item1 = Item(title: "転職", impact: 80.0, ease: 30.0, merit: "年収アップ確実", demerit: "準備に時間がかかる", isHighlighted: true, moneyLevel: 4, funLevel: 1, contributionLevel: 3, comfortableLevel: 1, easyStartLevel: 2)
        item1.actions = [
            Action(title: "履歴書・職務経歴書を作成する", done: true),
            Action(title: "エージェントに登録する", done: false)
        ]
        
        let item2 = Item(title: "エージェントから受注", impact: 70.0, ease: 60.0, merit: "すぐ始められる", demerit: "単価が変動する", isHighlighted: true, moneyLevel: 3, funLevel: 4, contributionLevel: 0, comfortableLevel: 2, easyStartLevel: 1)
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
                    Label("神風", systemImage: "flame.fill")
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
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 16) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            if let data = dream.imageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 98, height: 98)
                                    .clipped()
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 98, height: 98)
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
                        
                        VStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DREAM GOAL（上がり）")
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CURRENT STATUS（現状）")
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .submitLabel(.done)
                                        .onSubmit { focusedField = nil }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    VStack(spacing: 6) {
                        HStack(spacing: 12) {
                            LegendItemView(systemImage: "yensign.circle.fill", label: "収入", color: Color("Legend Item Color"))
                            LegendItemView(systemImage: "fireworks", label: "ワクワク", color: Color("Legend Item Color"))
                            LegendItemView(systemImage: "apple.meditate", label: "貢献", color: Color("Legend Item Color"))
                            LegendItemView(systemImage: "figure.mind.and.body", label: "快適", color: Color("Legend Item Color"))
                            LegendItemView(systemImage: "figure.walk", label: "手軽", color: Color("Legend Item Color"))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))
                
                // --- スクロールビュー ---
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedItems) { item in
                            ItemRowView(item: item, dream: dream)
                                .padding(12)
                                .background(item.isHighlighted ? Color("Highlight Item") : Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
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
                                        Text("追い風力 (Impact)")
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
                            
                            TextField("デメリット", text: $newDemerit, axis: .vertical)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("追い風力: \(Int(newImpact))%")
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
}

// ==========================================
// 5. 「神風」タブのビュー
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
                        "神風アクションがありません",
                        systemImage: "flame",
                        description: Text("「追い風アクション」タブで炎ボタンを押して指定すると、ここに表示されます。")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(highlightedItems.enumerated()), id: \.element.id) { index, item in
                                HighlightedItemRowView(index: index + 1, item: item, dream: dream)
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(10)
                                    .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(16)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("神風")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// ==========================================
// 6. 「神風」タブ専用の行ビュー
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
    @State private var showingResetAlert = false
    
    @State private var activeSelectingIndex: Int? = nil
    
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
        let opacity = max(0.15, currentEase / 100.0)
        return Color("EaseSliderTint").opacity(opacity)
    }
    
    private var areAllLevelsZero: Bool {
        item.moneyLevel == 0 && item.funLevel == 0 && item.contributionLevel == 0 && item.comfortableLevel == 0 && item.easyStartLevel == 0
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
                
                FlameToggleButton(isHighlighted: $item.isHighlighted)
            }
            
            // --- 追い風力スライダー ---
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("追い風力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "wind")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(currentImpact))%")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(impactColor)
                        .clipShape(Capsule())
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
            
            // --- やり易さスライダー ＆ セグメント評価（完全フロート展開） ＋ リセットボタン ---
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("やり易さ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "hand.thumbsup")
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
                .frame(width: UIScreen.main.bounds.width * 0.44)
                
                Spacer()
                
                // 評価マス群（22pt・完全フロート展開） ＋ リセットボタン
                HStack(alignment: .top, spacing: 4) {
                    HStack(alignment: .top, spacing: 2) {
                        SegmentScoreButton(index: 1, systemImage: "yensign.circle.fill", level: $item.moneyLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 2, systemImage: "fireworks", level: $item.funLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 3, systemImage: "apple.meditate", level: $item.contributionLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 4, systemImage: "figure.mind.and.body", level: $item.comfortableLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 5, systemImage: "figure.walk", level: $item.easyStartLevel, activeSelectingIndex: $activeSelectingIndex)
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 18, height: 22)
                    .opacity(areAllLevelsZero ? 0.0 : 1.0)
                    .scaleEffect(areAllLevelsZero ? 0.5 : 1.0)
                    .disabled(areAllLevelsZero)
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.2), value: areAllLevelsZero)
                    .alert("評価をリセットしますか？", isPresented: $showingResetAlert) {
                        Button("キャンセル", role: .cancel) { }
                        Button("リセット", role: .destructive) {
                            item.moneyLevel = 0
                            item.funLevel = 0
                            item.contributionLevel = 0
                            item.comfortableLevel = 0
                            item.easyStartLevel = 0
                            activeSelectingIndex = nil
                        }
                    }
                }
            }
            
            // --- メリット・デメリット ---
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
        .padding(.vertical, 4)
        .opacity(item.isCompleted ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showingDeleteAlert = true
        }
        .alert("\(item.title.isEmpty ? "無題" : item.title)の削除", isPresented: $showingDeleteAlert) {
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
    @State private var showingResetAlert = false
    
    @State private var activeSelectingIndex: Int? = nil
    
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
        let opacity = max(0.15, currentEase / 100.0)
        return Color("EaseSliderTint").opacity(opacity)
    }
    
    private var areAllLevelsZero: Bool {
        item.moneyLevel == 0 && item.funLevel == 0 && item.contributionLevel == 0 && item.comfortableLevel == 0 && item.easyStartLevel == 0
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
                
                FlameToggleButton(isHighlighted: $item.isHighlighted)
            }
            
            // --- 追い風力スライダー ---
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("追い風力")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: "wind")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(currentImpact))%")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(impactColor)
                        .clipShape(Capsule())
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
            
            // --- やり易さスライダー ＆ セグメント評価（完全フロート展開） ＋ リセットボタン ---
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("やり易さ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "hand.thumbsup")
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
                .frame(width: UIScreen.main.bounds.width * 0.44)
                
                Spacer()
                
                // 評価マス群（22pt・完全フロート展開） ＋ リセットボタン
                HStack(alignment: .top, spacing: 4) {
                    HStack(alignment: .top, spacing: 2) {
                        SegmentScoreButton(index: 1, systemImage: "yensign.circle.fill", level: $item.moneyLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 2, systemImage: "fireworks", level: $item.funLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 3, systemImage: "apple.meditate", level: $item.contributionLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 4, systemImage: "figure.mind.and.body", level: $item.comfortableLevel, activeSelectingIndex: $activeSelectingIndex)
                        SegmentScoreButton(index: 5, systemImage: "figure.walk", level: $item.easyStartLevel, activeSelectingIndex: $activeSelectingIndex)
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 18, height: 22)
                    .opacity(areAllLevelsZero ? 0.0 : 1.0)
                    .scaleEffect(areAllLevelsZero ? 0.5 : 1.0)
                    .disabled(areAllLevelsZero)
                    .contentShape(Rectangle())
                    .animation(.easeInOut(duration: 0.2), value: areAllLevelsZero)
                    .alert("評価をリセットしますか？", isPresented: $showingResetAlert) {
                        Button("キャンセル", role: .cancel) { }
                        Button("リセット", role: .destructive) {
                            item.moneyLevel = 0
                            item.funLevel = 0
                            item.contributionLevel = 0
                            item.comfortableLevel = 0
                            item.easyStartLevel = 0
                            activeSelectingIndex = nil
                        }
                    }
                }
            }
            .zIndex(activeSelectingIndex != nil ? 999 : 1) // ★ここを追加！
            
            // --- メリット・デメリット ---
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
        .padding(.vertical, 4)
        .opacity(item.isCompleted ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onLongPressGesture {
            showingDeleteAlert = true
        }
        .alert("\(item.title.isEmpty ? "無題" : item.title)の削除", isPresented: $showingDeleteAlert) {
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
// 8. 炎アイコン（X風キラリ・パーティクルエフェクト付き・FlameTintアセット対応）
// ==========================================

struct FlameToggleButton: View {
    @Binding var isHighlighted: Bool
    @State private var particleID = 0
    
    var body: some View {
        Button(action: {
            if !isHighlighted {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    isHighlighted = true
                }
                particleID += 1
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHighlighted = false
                }
            }
        }) {
            ZStack {
                FlameParticlesView()
                    .id(particleID)
                
                Image(systemName: isHighlighted ? "flame.fill" : "flame")
                    .foregroundColor(isHighlighted ? Color("FlameTint") : .secondary)
                    .font(.title3)
            }
            .frame(width: 30, height: 30)
        }
        .buttonStyle(.plain)
    }
}

struct FlameParticlesView: View {
    @State private var progress: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color("FlameTint"))
                    .frame(width: 5, height: 5)
                    .offset(particleOffset(for: i, progress: progress))
                    .opacity(Double(1.0 - progress))
                    .scaleEffect(0.5 + progress * 1.0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                progress = 1.0
            }
        }
    }
    
    private func particleOffset(for index: Int, progress: CGFloat) -> CGSize {
        let angle = Double(index) * (Double.pi / 3.0)
        let distance: Double = 22.0 * Double(progress)
        let x = cos(angle) * distance
        let y = sin(angle) * distance
        return CGSize(width: x, height: y)
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
        HStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// ==========================================
// 10. 修正版：完全浮動オーバーレイ展開式の評価ボタン
// ==========================================

struct SegmentScoreButton: View {
    let index: Int
    let systemImage: String
    @Binding var level: Int // 0〜5 の6段階
    @Binding var activeSelectingIndex: Int?
    
    private var isSelecting: Bool {
        activeSelectingIndex == index
    }
    
    private var buttonColor: Color {
        Color("Level \(level)")
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 通常時のボタン（22×22pt）
            VStack(spacing: 2) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeSelectingIndex = index
                    }
                }) {
                    ZStack {
                        buttonColor
                            .cornerRadius(3.0)
                        
                        Image(systemName: systemImage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                
                ZStack {
                    if level > 0 {
                        Text("\(level)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(buttonColor)
                    }
                }
                .frame(height: 12)
            }
            .opacity(isSelecting ? 0 : 1) // 展開中は元の場所を非表示に
            
            // 選択時：完全に浮いたオーバーレイとして上下に展開
            if isSelecting {
                VStack(spacing: 2) {
                    // 1. 上に展開する数字（現在値より小さい値：x, 1, 2 の順）
                    if level > 0 {
                        ForEach(0..<level, id: \.self) { num in
                            Button(action: {
                                level = num
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    activeSelectingIndex = nil
                                }
                            }) {
                                ZStack {
                                    Color("Level \(num)")
                                        .cornerRadius(3.0)
                                        .opacity(0.45)
                                    
                                    Text(num == 0 ? "×" : "\(num)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.95)
                                }
                                .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 2. 現在選択中の位置（元の評価アイコンを大きさもそのまま表示）
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            activeSelectingIndex = nil
                        }
                    }) {
                        ZStack {
                            buttonColor
                                .cornerRadius(3.0)
                            
                            Image(systemName: systemImage)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    
                    // 3. 下に展開する数字（現在値より大きい値：3, 4, 5）
                    if level < 5 {
                        ForEach((level+1)...5, id: \.self) { num in
                            Button(action: {
                                level = num
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    activeSelectingIndex = nil
                                }
                            }) {
                                ZStack {
                                    Color("Level \(num)")
                                        .cornerRadius(3.0)
                                        .opacity(0.45)
                                    
                                    Text("\(num)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.95)
                                }
                                .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(0)
                .background(Color(.systemBackground))
                .cornerRadius(4)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                .offset(y: (CGFloat(level) * -24.0) + 53.0)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 22, height: 22)
        // 選択中は周囲のUIより圧倒的に手前に表示されるよう最大値を設定
        .zIndex(isSelecting ? 99999 : 1)
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
