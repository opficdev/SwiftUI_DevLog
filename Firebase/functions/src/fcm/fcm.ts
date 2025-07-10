import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// FCM 메시지가 전송될 때 자동으로 Firestore에 저장
export const onFCMSend = onMessagePublished(async (event) => {
  try {
    const message = event.data.message;
    if (!message) {
      console.log("메시지가 없습니다.");
      return;
    }

    const { notification, data } = message;
    const userId = data?.userId;

    if (!userId) {
      console.log('userId가 없어 저장할 수 없습니다');
      return;
    }

    await admin.firestore().collection(`users/${userId}/notifications`).add({
      title: notification?.title || '',
      content: notification?.body || '',
      kind: data?.kind || 'info',
      receivedDate: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });
    console.log(`사용자 ${userId}의 알림이 저장되었습니다`);
  } catch (error) {
    console.error('알림 저장 중')
  }
});
