import { onTaskDispatched } from "firebase-functions/v2/tasks";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Cloud Tasks에 의해 트리거되는 함수
export const sendPushNotification = onTaskDispatched(
    {
        retryConfig: { maxAttempts: 3, minBackoffSeconds: 5 },
        rateLimits: { maxDispatchesPerSecond: 500 },
    },
    async (req) => {
        const { userId, title, body } = req.data; // 예약 시 보냈던 데이터
        logger.info(`[${userId}]에게 알림 발송 작업을 시작합니다: ${title}`);

        try {
            // 1. 사용자 FCM 토큰 가져오기
            const tokenDoc = await admin.firestore().doc(`users/${userId}/userData/tokens`).get();
            const fcmToken = tokenDoc.data()?.fcmToken;

            if (!fcmToken) {
                logger.warn(`사용자 ${userId}의 fcmToken이 없어 알림을 보낼 수 없습니다.`);
                return;
            }

            // 2. 알림 발송 및 Firestore에 기록
            const message = {
                notification: { title, body },
                apns: { payload: { aps: { sound: "default" } } },
                token: fcmToken,
            };
            await admin.messaging().send(message);

            const notificationData = {
                title, body, sentAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false, type: 'reminder'
            };
            await admin.firestore().collection(`users/${userId}/notifications`).add(notificationData);

            logger.info(`[${userId}]에게 알림을 성공적으로 보내고 저장했습니다.`);

        } catch (error) {
            logger.error(`[${userId}]에게 알림 발송 중 오류 발생:`, error);
            throw error; // 오류를 다시 던져 Cloud Tasks가 재시도하도록 함
        }
    }
);
