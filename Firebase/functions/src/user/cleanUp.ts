import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

export const userCleanup = onCall(
  {
    cors: true,
    maxInstances: 10,
    region: "asia-northeast3",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "로그인 필요");
    const userId = request.data.userId;
    if (!userId) throw new HttpsError("invalid-argument", "userId 필요");

    try {
      const userDocRef = admin.firestore().doc(`users/${userId}`);
      await admin.firestore().recursiveDelete(userDocRef);

    // Firestore의 recursiveDelete API 사용 (firebase-tools v9.12.0+)
    // 실제로는 admin SDK엔 없고, 아래처럼 functions에서 사용할 수 있음
    // https://firebase.google.com/docs/firestore/solutions/delete-collections?hl=ko#cloud-functions
    // @ts-ignore
      return { success: true }
    } catch (err: any) {
      throw new HttpsError("internal", `삭제 중 오류: ${err.message || err}`);
    }
  }
);