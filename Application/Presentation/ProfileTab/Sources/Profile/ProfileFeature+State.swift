//
//  ProfileFeature+State.swift
//  ProfileTab
//
//  Created by opfic on 6/15/26.
//

import Core
import Foundation
import PresentationShared

extension ProfileFeature.State {
    var isLoading: Bool {
        loading.isLoading
    }

    var quarterTitle: String {
        guard let start = selectedQuarterStart else { return "" }
        let year = Calendar.current.component(.year, from: start)
        let month = Calendar.current.component(.month, from: start)
        let quarter = ((month - 1) / 3) + 1
        return String.localizedStringWithFormat(
            String(localized: "profile_year_quarter_format", bundle: PresentationResources.bundle),
            String(year),
            String(quarter)
        )
    }

    var selectedDayActivities: [HeatmapActivityItem] {
        guard let selectedDay else { return [] }
        let dayStart = Calendar.current.startOfDay(for: selectedDay.date)
        let activities = dayActivitiesByDate[dayStart] ?? []

        return activities.filter { activity in
            !Set(activity.activityKinds).isDisjoint(with: selectedActivityKinds)
        }
    }

    var isCreatedActivitySelected: Bool {
        get { selectedActivityKinds.contains(.created) }
        set { setActivityKind(.created, isSelected: newValue) }
    }

    var isCompletedActivitySelected: Bool {
        get { selectedActivityKinds.contains(.completed) }
        set { setActivityKind(.completed, isSelected: newValue) }
    }

    var isDeletedActivitySelected: Bool {
        get { selectedActivityKinds.contains(.deleted) }
        set { setActivityKind(.deleted, isSelected: newValue) }
    }

    var isCreatedActivityToggleDisabled: Bool {
        selectedActivityKinds == [.created]
    }

    var isCompletedActivityToggleDisabled: Bool {
        selectedActivityKinds == [.completed]
    }

    var isDeletedActivityToggleDisabled: Bool {
        selectedActivityKinds == [.deleted]
    }

    var canMoveToPreviousQuarter: Bool {
        ProfileHeatmapBuilder.canMoveToQuarter(offsetMonths: -3, state: self)
    }

    var canMoveToNextQuarter: Bool {
        ProfileHeatmapBuilder.canMoveToQuarter(offsetMonths: 3, state: self)
    }

    var isViewingCurrentQuarter: Bool {
        guard let selectedQuarterStart,
              let currentQuarterStart = ProfileHeatmapBuilder.quarterStart(for: Date()) else {
            return false
        }
        return selectedQuarterStart == currentQuarterStart
    }

    var availableQuarterYears: [Int] {
        guard let earliestQuarterStart,
              let currentQuarterStart = ProfileHeatmapBuilder.quarterStart(for: Date()) else {
            return [selectedQuarterPickerYear]
        }
        let earliestYear = Calendar.current.component(.year, from: earliestQuarterStart)
        let currentYear = Calendar.current.component(.year, from: currentQuarterStart)
        return Array(stride(from: currentYear, through: earliestYear, by: -1))
    }

    func quarterStartForPicker(quarter: Int) -> Date? {
        ProfileHeatmapBuilder.quarterStart(year: selectedQuarterPickerYear, quarter: quarter)
    }

    func isQuarterSelectableForPicker(_ quarter: Int) -> Bool {
        guard let quarterStart = quarterStartForPicker(quarter: quarter) else { return false }
        return ProfileHeatmapBuilder.canSelectQuarter(quarterStart, state: self)
    }

    func isQuarterSelectedForPicker(_ quarter: Int) -> Bool {
        quarterStartForPicker(quarter: quarter) == selectedQuarterStart
    }

    private mutating func setActivityKind(_ activityKind: ActivityKind, isSelected: Bool) {
        if isSelected {
            selectedActivityKinds.insert(activityKind)
        } else if 1 < selectedActivityKinds.count {
            selectedActivityKinds.remove(activityKind)
        }
    }
}
