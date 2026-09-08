import SwiftUI

/// 카드 등록·수정. 스캔 한 번이면 값과 종류가 함께 들어온다.
struct ItemEditorView: View {
    let item: WalletItem?
    var initialName: String? = nil
    /// 온보딩에서 고른 장소를 미리 켜둔다.
    var initialPlaces: [PlaceCategory] = []
    /// 온보딩처럼 "지금 바로 스캔"으로 들어오는 경로에서 쓴다.
    var autoScan = false

    @EnvironmentObject private var store: WalletStore
    @Environment(\.dismiss) private var dismiss

    @State private var kind: WalletItem.Kind = .membership
    @State private var name = ""
    @State private var memo = ""
    @State private var symbology: BarcodeSymbology = .ean13
    @State private var value = ""
    @State private var payAppID = PayAppCatalog.all.first?.id ?? ""
    @State private var tintHex = TintPalette.all[0]
    @State private var places: [PlaceCategory] = []
    @State private var isScanning = false

    /// 숫자 키패드에는 완료 키가 없다. 한 번 뜨면 스스로 내려가지 않으므로
    /// 어느 칸에 있는지 들고 있다가 직접 내린다.
    @FocusState private var focusedField: Field?

    private enum Field: Hashable { case value, name, memo }

    init(
        item: WalletItem?,
        initialName: String? = nil,
        initialPlaces: [PlaceCategory] = [],
        autoScan: Bool = false
    ) {
        self.item = item
        self.initialName = initialName
        self.initialPlaces = initialPlaces
        self.autoScan = autoScan
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("종류", selection: $kind) {
                        Text("멤버십 · 포인트").tag(WalletItem.Kind.membership)
                        Text("페이 앱 바로가기").tag(WalletItem.Kind.payApp)
                    }
                    .pickerStyle(.segmented)
                }

                if kind == .membership {
                    membershipSection
                } else {
                    payAppSection
                }

                placeSection

                Section("보기") {
                    TextField("이름", text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                    TextField("메모 (선택)", text: $memo)
                        .focused($focusedField, equals: .memo)
                        .submitLabel(.done)
                    colorPicker
                }
            }
            // 빈 곳을 누르면 키보드가 내려간다. 칸이나 버튼을 누른 것은
            // 그쪽이 먼저 가져가므로 여기까지 오지 않는다.
            .onTapGesture { focusedField = nil }
            .onSubmit { focusedField = nil }
            .onChange(of: kind) { _, _ in focusedField = nil }
            .onChange(of: symbology) { _, _ in focusedField = nil }
            .navigationTitle(item == nil ? "카드 추가" : "카드 수정")
            .navigationBarTitleDisplayMode(.inline)
            // 아래로 쓸어서 시트가 닫히면 입력하던 것이 통째로 날아간다. 나가는 문은 '취소' 하나.
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }.disabled(!canSave)
                }
                // 숫자 키패드로 들어왔을 때 빠져나올 유일한 문.
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") { focusedField = nil }
                }
            }
            .sheet(isPresented: $isScanning) {
                scannerSheet
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private var membershipSection: some View {
        Section {
            Button {
                focusedField = nil
                isScanning = true
            } label: {
                Label("카메라로 스캔", systemImage: "barcode.viewfinder")
            }

            Picker("바코드 종류", selection: $symbology) {
                ForEach(BarcodeSymbology.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }

            TextField("바코드 번호", text: $value)
                .focused($focusedField, equals: .value)
                .keyboardType(symbology.isNumericOnly ? .numberPad : .default)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if let normalized, normalized != value.filter(\.isNumber), symbology.isNumericOnly {
                Label("체크디지트를 붙여 \(normalized) 로 저장돼요", systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if !value.isEmpty && normalized == nil && symbology.isNumericOnly {
                Label(symbology.hint, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            if let preview {
                BarcodeView(barcode: preview, height: 80)
                    .padding(.vertical, 8)
            }
        } header: {
            Text("바코드")
        } footer: {
            Text(symbology.hint)
        }
    }

    /// 등록해두고 언제 꺼내야 할지 몰라서 못 쓰는 문제를 카드 자체에서 푼다.
    private var placeSection: some View {
        Section {
            ChipGrid(
                items: PlaceCategory.allCases.map(\.chip),
                isSelected: { chip in
                    PlaceCategory.from(chip: chip).map(places.contains) ?? false
                },
                onTap: { chip in
                    focusedField = nil
                    guard let place = PlaceCategory.from(chip: chip) else { return }
                    if let index = places.firstIndex(of: place) {
                        places.remove(at: index)
                    } else {
                        places.append(place)
                    }
                }
            )
            .padding(.vertical, 4)
        } header: {
            Text("사용처")
        } footer: {
            Text("고른 장소가 카드에 적혀서, 언제 꺼내야 하는지 바로 보입니다. 여러 개 고를 수 있습니다.")
        }
    }

    private var payAppSection: some View {
        Section {
            Picker("앱", selection: $payAppID) {
                ForEach(PayAppCatalog.all) { app in
                    Text(app.name).tag(app.id)
                }
            }
        } header: {
            Text("바로가기")
        } footer: {
            Text("결제 QR은 각 앱만 만들 수 있어요. 이 카드는 해당 앱의 결제 화면으로 넘겨줍니다.")
        }
    }

    private var colorPicker: some View {
        HStack(spacing: 10) {
            ForEach(TintPalette.all, id: \.self) { hex in
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().stroke(Color.primary, lineWidth: tintHex == hex ? 2 : 0)
                    )
                    .onTapGesture {
                        focusedField = nil
                        tintHex = hex
                    }
            }
        }
        .padding(.vertical, 4)
    }

    private var scannerSheet: some View {
        NavigationStack {
            ScannerView { scanned in
                symbology = scanned.symbology
                value = scanned.value
                isScanning = false
                focusedField = nil
            }
            .ignoresSafeArea()
            .navigationTitle("바코드 스캔")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { isScanning = false }
                }
            }
        }
    }

    private var normalized: String? {
        guard symbology.isNumericOnly else { return value.isEmpty ? nil : value }
        return EANEncoder.normalized(value, for: symbology)
    }

    private var preview: Barcode? {
        guard let normalized, !normalized.isEmpty else { return nil }
        return Barcode(value: normalized, symbology: symbology)
    }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch kind {
        case .membership: return preview != nil
        case .payApp: return !payAppID.isEmpty
        }
    }

    private func loadIfNeeded() {
        guard let item else {
            if let initialName, name.isEmpty { name = initialName }
            if places.isEmpty { places = initialPlaces }
            if autoScan && !isScanning && value.isEmpty { isScanning = true }
            return
        }
        kind = item.kind
        name = item.name
        memo = item.memo
        tintHex = item.tintHex
        places = item.places
        if let barcode = item.barcode {
            symbology = barcode.symbology
            value = barcode.value
        }
        if let payAppID = item.payAppID { self.payAppID = payAppID }
    }

    private func save() {
        var next = item ?? WalletItem(kind: kind, name: name)
        next.kind = kind
        next.name = name.trimmingCharacters(in: .whitespaces)
        next.memo = memo.trimmingCharacters(in: .whitespaces)
        next.tintHex = tintHex
        next.places = places
        switch kind {
        case .membership:
            next.barcode = preview
            next.payAppID = nil
        case .payApp:
            next.barcode = nil
            next.payAppID = payAppID
            if next.name.isEmpty, let app = PayAppCatalog.app(id: payAppID) { next.name = app.name }
        }
        store.upsert(next)
        dismiss()
    }
}
