//
//  HomeFeatureTests.swift
//  HomeTabTests
//
//  Created by opfic on 6/14/26.
//

import Testing
import Domain
import PresentationShared
@testable import HomeTab

@MainActor
struct HomeFeatureTests {
    @Test("HomeFeature fetchData는 홈 상태를 갱신한다")
    func HomeFeature_fetchData는_홈_상태를_갱신한다() async throws {
        let context = makeHomeFetchDataContext()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy
        )

        try await verifyHomeFetchData(adapter: adapter)
    }

    @Test("HomeFeature tapTodoCategory는 editor를 지연 표시한다")
    func HomeFeature_tapTodoCategory는_editor를_지연_표시한다() async throws {
        let adapter = HomeStoreTestAdapter()

        try await verifyHomeTapTodoCategory(adapter: adapter)
    }

    @Test("TodoEditor 생성 delegate는 editor를 닫고 홈 데이터를 다시 조회한다")
    func TodoEditor_생성_delegate는_editor를_닫고_홈_데이터를_다시_조회한다() async throws {
        let context = makeHomeFetchDataContext()
        let trackSpy = HomeTrackAnalyticsEventUseCaseSpy()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            trackAnalyticsEventUseCase: trackSpy
        )

        await adapter.tapTodoCategory(.system(.feature))
        await adapter.todoEditorCreated()

        await waitUntil {
            context.fetchPreferencesUseCaseSpy.executeCount == 1
                && trackSpy.hasTrackedTodoCreate
        }

        #expect(!adapter.showTodoEditor)
    }

    @Test("HomeFeature orderTodoCategory는 카테고리 설정을 저장한다")
    func HomeFeature_orderTodoCategory는_카테고리_설정을_저장한다() async throws {
        let context = makeHomeOrderContext()
        let adapter = HomeStoreTestAdapter(
            fetchPreferencesUseCase: context.fetchPreferencesUseCaseSpy,
            updatePreferencesUseCase: context.updatePreferencesUseCaseSpy
        )

        try await verifyHomeOrderTodoCategory(
            adapter: adapter,
            updatePreferencesUseCaseSpy: context.updatePreferencesUseCaseSpy
        )
    }

    @Test("HomeFeature startObserving은 네트워크 연결 상태를 반영한다")
    func HomeFeature_startObserving은_네트워크_연결_상태를_반영한다() async {
        let networkUseCaseSpy = ObserveNetworkConnectivityUseCaseSpy()
        let adapter = HomeStoreTestAdapter(networkConnectivityUseCase: networkUseCaseSpy)

        await adapter.startObserving()

        #expect(adapter.isNetworkConnected)

        networkUseCaseSpy.currentValueSubject.send(false)
        await adapter.settle()

        #expect(!adapter.isNetworkConnected)
    }
}
