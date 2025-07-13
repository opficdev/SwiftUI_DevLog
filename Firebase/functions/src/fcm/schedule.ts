import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { getFunctions } from "firebase-admin/functions";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const LOCATION = "asia-northeast3"; 

// 할 일(Todo) 문서가 생성되거나 업데이트될 때마다 실행
export const scheduleTodoReminder = onDocumentWritten(
    {
        region: LOCATION,
        document: "users/{userId}/todoLists/{todoId}",
    },
    async (event) => {
        const todoData = event.data?.after.data();
        const userId = event.params.userId;

        // 할 일이 삭제되었거나 dueDate가 없으면 작업 중지
        if (!todoData || !todoData.dueDate) {
            logger.info(`Todo가 삭제되었거나 dueDate가 없어 스케줄링하지 않습니다.`);
            return;
        }

        try {
            // 1. 사용자의 알림 설정 시간 가져오기 (기본값: 오전 9시)
            const settingsDoc = await admin.firestore().doc(`users/${userId}/userData/settings`).get();
            const settings = settingsDoc.data();
            const notificationHour = settings?.notificationHour ?? 9; // 설정 없으면 오전 9시

            // 2. 실제 알림 보낼 시간 계산 (마감일 하루 전, 사용자가 설정한 시각)
            const dueDate = todoData.dueDate.toDate(); // Firestore Timestamp를 JS Date로 변환
            const notificationDate = new Date(dueDate.getFullYear(), dueDate.getMonth(), dueDate.getDate() - 1, notificationHour, 0, 0);

            // 3. Cloud Tasks 큐에 작업 예약
            const queue = getFunctions().taskQueue("sendPushNotification",LOCATION);
            await queue.enqueue(
                {
                    userId: userId,
                    title: "마감 알림",
                    body: `'${todoData.title || '제목 없음'}'의 마감일이 내일입니다.`,
                },
                {
                    scheduleTime: notificationDate, // 이 시간에 작업이 실행되도록 예약
                }
            );

            logger.info(`[${userId}]의 Todo '${todoData.title}'에 대한 알림을 ${notificationDate.toLocaleString()}에 예약했습니다.`);

        } catch (error) {
            logger.error("알림 예약 중 오류 발생:", error);
        }
    }
);
