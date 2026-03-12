// KISE/Sources/Views/Registration/RegistrationFlowView.swift
import SwiftUI

struct RegistrationFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegistrationViewModel()
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    switch viewModel.currentStep {
                    case .category:
                        CategoryPickerView { category in
                            withAnimation { viewModel.selectCategory(category) }
                        }

                    case .color:
                        CuratedColorPicker { color in
                            withAnimation { viewModel.selectColor(color) }
                        }

                    case .fit:
                        OptionPickerStepView(
                            title: "What fit?",
                            options: viewModel.availableFits,
                            labelFor: { $0.displayName },
                            suggested: nil
                        ) { fit in
                            withAnimation { viewModel.selectFit(fit) }
                        }

                    case .material:
                        MaterialPickerStepView(
                            materials: viewModel.availableMaterials
                        ) { material in
                            withAnimation { viewModel.selectMaterial(material) }
                        }

                    case .weight:
                        OptionPickerStepView(
                            title: "Fabric weight?",
                            options: FabricWeight.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.selectedWeight
                        ) { weight in
                            withAnimation { viewModel.selectWeight(weight) }
                        }

                    case .formality:
                        OptionPickerStepView(
                            title: "Formality level?",
                            options: Formality.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.suggestedFormality
                        ) { formality in
                            viewModel.selectFormality(formality)
                            if viewModel.savePiece(context: modelContext) {
                                viewModel.showAddedConfirmation = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(KISEDesign.Spacing.md)
            }
            .background(KISEDesign.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep > .category {
                        Button("Back") {
                            withAnimation { viewModel.goBack() }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if viewModel.showAddedConfirmation {
                    VStack {
                        Spacer()
                        Text("Added!")
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(KISEDesign.Colors.background)
                            .padding(.horizontal, KISEDesign.Spacing.xl)
                            .padding(.vertical, KISEDesign.Spacing.md)
                            .background(KISEDesign.Colors.accent)
                            .clipShape(Capsule())
                            .padding(.bottom, KISEDesign.Spacing.xxl)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeOut(duration: 0.3), value: viewModel.showAddedConfirmation)
                }
            }
        }
    }
}
