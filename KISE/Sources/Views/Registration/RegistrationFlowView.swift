// KISE/Sources/Views/Registration/RegistrationFlowView.swift
import SwiftUI

struct RegistrationFlowView: View {
    @Environment(ThemeProvider.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RegistrationViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    switch viewModel.currentStep {
                    case .category:
                        CategoryPickerView { category in
                            withAnimation { viewModel.selectCategory(category) }
                        }
                        .transition(.opacity)

                    case .color:
                        CuratedColorPicker { color in
                            withAnimation { viewModel.selectColor(color) }
                        }
                        .transition(.opacity)

                    case .fit:
                        OptionPickerStepView(
                            title: String(localized: "registration.whatFit"),
                            options: viewModel.availableFits,
                            labelFor: { $0.displayName },
                            suggested: nil
                        ) { fit in
                            withAnimation { viewModel.selectFit(fit) }
                        }
                        .transition(.opacity)

                    case .shoeType:
                        OptionPickerStepView(
                            title: String(localized: "registration.whatType"),
                            options: ShoeType.allCases,
                            labelFor: { $0.displayName },
                            suggested: nil
                        ) { type in
                            withAnimation { viewModel.selectShoeType(type) }
                        }
                        .transition(.opacity)

                    case .material:
                        MaterialPickerStepView(
                            materials: viewModel.availableMaterials
                        ) { material in
                            withAnimation { viewModel.selectMaterial(material) }
                        }
                        .transition(.opacity)

                    case .weight:
                        OptionPickerStepView(
                            title: String(localized: "registration.fabricWeight"),
                            options: FabricWeight.allCases,
                            labelFor: { $0.displayName },
                            suggested: viewModel.selectedWeight
                        ) { weight in
                            withAnimation { viewModel.selectWeight(weight) }
                        }
                        .transition(.opacity)

                    case .formality:
                        OptionPickerStepView(
                            title: String(localized: "registration.formalityLevel"),
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
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
                .padding(KISEDesign.Spacing.md)
            }
            .background(theme.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep > .category {
                        Button(String(localized: "action.back")) {
                            withAnimation { viewModel.goBack() }
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
            }
            .overlay {
                if viewModel.showAddedConfirmation {
                    VStack {
                        Spacer()
                        Text("registration.added")
                            .font(KISEDesign.Typography.subtitle)
                            .foregroundStyle(theme.colors.background)
                            .padding(.horizontal, KISEDesign.Spacing.xl)
                            .padding(.vertical, KISEDesign.Spacing.md)
                            .background(theme.colors.accent)
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
