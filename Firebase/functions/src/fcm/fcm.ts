import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * 특정 사용자에게 푸시 알림을 보내고, 그 기록을 Firestore에 저장합니다.
 * @param {string} userId - 알림을 받을 사용자의 ID
 * @param {string} fcmToken - 대상 기기의 FCM 토큰
 * @param {string} title - 알림의 제목
 * @param {string} body - 알림의 본문
 */
export async function sendAndRecordNotification(userId: string, fcmToken: string, title: string, body: string) {
    try {
        // 1. FCM 메시지 구성
        const message = {
            notification: {
                title: title,
                body: body,
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                    },
                },
            },
            token: fcmToken,
        };

        // 2. 알림 발송
        await admin.messaging().send(message);
        logger.info(`사용자 ${userId}에게 '${title}' 알림을 성공적으로 보냈습니다.`);

        // 3. Firestore에 저장할 데이터 구성
        const notificationData = {
            title: title,
            body: body,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            type: 'reminder'
        };

        // 4. Firestore에 알림 기록 저장
        await admin.firestore().collection(`users/${userId}/notifications`).add(notificationData);
        logger.info(`사용자 ${userId}의 notifications 컬렉션에 알림을 저장했습니다.`);

    } catch (error) {
        logger.error(`[sendAndRecordNotification] 사용자 ${userId}에게 알림 전송/저장 중 오류 발생:`, error);
        // 여기서 에러를 다시 던져서 호출한 쪽에서도 알 수 있게 할 수 있습니다.
        throw error;
    }
}
