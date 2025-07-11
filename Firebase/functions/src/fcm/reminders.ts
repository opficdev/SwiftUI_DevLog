import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// 매일 저녁 9시에 실행되는 스케줄 함수
export const sendDueDateReminders = onSchedule(
    {
        schedule: "0 21 * * *", // 매일 21:00 (KST)
        timeZone: "Asia/Seoul",  // 한국 시간 기준
        region: "asia-northeast3",
    },
    async (event) => {
        logger.info("🚀 sendDueDateReminders 함수 실행 시작!"); // <--- 이 로그를 추가
        // 한국 시간 기준으로 '내일'의 시작과 끝을 계산
        const now = new Date();
        const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
        const dayAfterTomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2);

        try {
            // 'todoLists' 컬렉션 그룹에서 마감 기한이 '내일'인 모든 문서를 쿼리
            const querySnapshot = await admin.firestore()
                .collectionGroup('todoLists')
                .where('dueDate', '>=', tomorrow)
                .where('dueDate', '<', dayAfterTomorrow)
                .get();

            if (querySnapshot.empty) {
                logger.info("내일 마감되는 Todo가 없습니다.");
                return;
            }

            // 각 할 일에 대해 알림 전송
            for (const doc of querySnapshot.docs) {
                const todoData = doc.data();
                const todoTitle = todoData.title || '제목 없음';

                const pathParts = doc.ref.path.split('/');
                const userId = pathParts[1];

                if (!userId) {
                    logger.warn("문서 경로에서 userId를 찾을 수 없습니다:", doc.ref.path);
                    continue;
                }

                const tokenDoc = await admin.firestore().doc(`users/${userId}/userData/tokens`).get();
                if (!tokenDoc.exists) {
                    logger.warn(`사용자 ${userId}의 토큰 문서가 없습니다.`);
                    continue;
                }

                const fcmToken = tokenDoc.data()?.fcmToken;
                if (!fcmToken) {
                    logger.warn(`사용자 ${userId}의 fcmToken이 없습니다.`);
                    continue;
                }

                // FCM 메시지 내용 수정
                const message = {
                    notification: {
                        title: '마감 알림',
                        body: `'${todoTitle}'의 마감일이 내일입니다.`,
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

                await admin.messaging().send(message);
                logger.info(`사용자 ${userId}에게 '${todoTitle}'에 대한 마감 알림을 성공적으로 보냈습니다.`);
            }
        } catch (error) {
            logger.error("마감 알림 전송 중 오류 발생:", error);
        }
    }
);
