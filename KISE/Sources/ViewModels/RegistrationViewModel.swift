// KISE/Sources/ViewModels/RegistrationViewModel.swift
import SwiftUI
import SwiftData

enum RegistrationStep: Int, CaseIterable, Comparable {
    case category, color, fit, material, weight, formality, confirm

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
    var selectedMaterial: String?
    var selectedWeight: FabricWeight?
    var selectedFormality: Formality?
    var userPhotoPath: String?

    // MARK: - Computed

    var availableFits: [Fit] {
        selectedCategory?.availableFits ?? Fit.allCases
    }

    var availableMaterials: [String] {
        selectedCategory?.availableMaterials ?? []
    }

    var suggestedFormality: Formality? {
        selectedCategory?.defaultFormality
    }

    var catalogImageKey: String? {
        guard let category = selectedCategory,
              let color = selectedColor,
              let fit = selectedFit else { return nil }
        return CatalogImageService.imageKey(category: category, color: color.id, fit: fit)
    }

    // MARK: - Actions

    func selectCategory(_ category: GarmentCategory) {
        selectedCategory = category
        currentStep = .color
    }

    func selectColor(_ color: GarmentColor) {
        selectedColor = color
        currentStep = .fit
    }

    func selectFit(_ fit: Fit) {
        selectedFit = fit
        currentStep = .material
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
        currentStep = .confirm
    }

    func goBack() {
        guard let previousIndex = RegistrationStep.allCases.firstIndex(of: currentStep),
              previousIndex > 0 else { return }
        currentStep = RegistrationStep.allCases[previousIndex - 1]
    }

    func reset() {
        currentStep = .category
        selectedCategory = nil
        selectedColor = nil
        selectedFit = nil
        selectedMaterial = nil
        selectedWeight = nil
        selectedFormality = nil
        userPhotoPath = nil
    }

    func buildPiece() -> GarmentPiece? {
        guard let category = selectedCategory,
              let color = selectedColor,
              let fit = selectedFit,
              let material = selectedMaterial,
              let weight = selectedWeight,
              let formality = selectedFormality else { return nil }

        return GarmentPiece(
            category: category,
            color: color.id,
            colorHex: color.hex,
            fit: fit,
            material: material,
            weight: weight,
            formality: formality
        )
    }

    @MainActor
    func savePiece(context: ModelContext) -> Bool {
        guard let piece = buildPiece() else { return false }
        piece.userPhotoPath = userPhotoPath
        context.insert(piece)
        try? context.save()
        return true
    }
}
