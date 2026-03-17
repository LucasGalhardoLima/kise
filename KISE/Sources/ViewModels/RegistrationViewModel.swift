// KISE/Sources/ViewModels/RegistrationViewModel.swift
import SwiftUI
import SwiftData

enum RegistrationStep: Int, CaseIterable, Comparable {
    case category, color, fit, shoeType, material, weight, formality

    static func < (lhs: RegistrationStep, rhs: RegistrationStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@Observable
final class RegistrationViewModel {
    var currentStep: RegistrationStep = .category
    var selectedCategory: GarmentCategory?
    var selectedColor: GarmentColor?
    var selectedFit: Fit?
    var selectedShoeType: ShoeType?
    var selectedMaterial: String?
    var selectedWeight: FabricWeight?
    var selectedFormality: Formality?
    var userPhotoPath: String?
    var showAddedConfirmation = false

    // MARK: - Computed

    private var isShoeCategory: Bool {
        selectedCategory == .shoes
    }

    var availableFits: [Fit] {
        selectedCategory?.availableFits ?? Fit.allCases
    }

    var availableMaterials: [String] {
        selectedCategory?.availableMaterials ?? []
    }

    var suggestedFormality: Formality? {
        selectedCategory?.defaultFormality
    }

    // MARK: - Step Navigation

    /// Returns the steps applicable for the current category
    private var applicableSteps: [RegistrationStep] {
        RegistrationStep.allCases.filter { step in
            switch step {
            case .fit: !isShoeCategory       // skip fit for shoes
            case .shoeType: isShoeCategory   // skip shoeType for non-shoes
            default: true
            }
        }
    }

    private func nextApplicableStep(after step: RegistrationStep) -> RegistrationStep? {
        guard let idx = applicableSteps.firstIndex(of: step),
              idx + 1 < applicableSteps.count else { return nil }
        return applicableSteps[idx + 1]
    }

    private func previousApplicableStep(before step: RegistrationStep) -> RegistrationStep? {
        guard let idx = applicableSteps.firstIndex(of: step),
              idx > 0 else { return nil }
        return applicableSteps[idx - 1]
    }

    // MARK: - Actions

    func selectCategory(_ category: GarmentCategory) {
        selectedCategory = category
        currentStep = .color
    }

    func selectColor(_ color: GarmentColor) {
        selectedColor = color
        // After color, go to fit (non-shoes) or shoeType (shoes)
        if let next = nextApplicableStep(after: .color) {
            currentStep = next
        }
    }

    func selectFit(_ fit: Fit) {
        selectedFit = fit
        if let next = nextApplicableStep(after: .fit) { currentStep = next }
    }

    func selectShoeType(_ type: ShoeType) {
        selectedShoeType = type
        if let next = nextApplicableStep(after: .shoeType) { currentStep = next }
    }

    func selectMaterial(_ material: String) {
        selectedMaterial = material
        selectedWeight = FabricWeight.defaultWeight(for: material)
        currentStep = .weight
    }

    func selectWeight(_ weight: FabricWeight) {
        selectedWeight = weight
        selectedFormality = suggestedFormality
        currentStep = .formality
    }

    func selectFormality(_ formality: Formality) {
        selectedFormality = formality
    }

    func goBack() {
        if let prev = previousApplicableStep(before: currentStep) {
            currentStep = prev
        }
    }

    func reset() {
        currentStep = .category
        selectedCategory = nil
        selectedColor = nil
        selectedFit = nil
        selectedShoeType = nil
        selectedMaterial = nil
        selectedWeight = nil
        selectedFormality = nil
        userPhotoPath = nil
    }

    func buildPiece() -> GarmentPiece? {
        guard let category = selectedCategory,
              let color = selectedColor,
              let material = selectedMaterial,
              let weight = selectedWeight,
              let formality = selectedFormality else { return nil }

        // Shoes need shoeType, non-shoes need fit
        if isShoeCategory {
            guard selectedShoeType != nil else { return nil }
        } else {
            guard selectedFit != nil else { return nil }
        }

        let piece = GarmentPiece(
            category: category,
            color: color.id,
            colorHex: color.hex,
            fit: selectedFit ?? .regular,  // default for shoes
            material: material,
            weight: weight,
            formality: formality
        )
        piece.shoeType = selectedShoeType
        piece.colorDisplayName = color.isCustom ? color.name : nil
        return piece
    }

    @MainActor
    func savePiece(context: ModelContext) -> Bool {
        guard let piece = buildPiece() else { return false }
        piece.userPhotoPath = userPhotoPath
        context.insert(piece)
        try? context.save()
        // Async: upgrade custom color name via AI if available
        if let color = selectedColor, color.isCustom {
            Task {
                let aiName = await ColorNamingService.generateName(for: color.hex)
                piece.colorDisplayName = aiName
                try? context.save()
            }
        }
        return true
    }
}
