import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import * as jwt from "jsonwebtoken";

export const requestAppleRefreshToken = onCall({
    cors: true,
    maxInstances: 10,
    region: "asia-northeast3",
  }, async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }
  
    try {
    // 요청 데이터가 null인지 확인
      console.log("Request data:", request.data);
      
      if (!request.data) {
        throw new HttpsError(
          "invalid-argument",
          "Request data is missing"
        );
      }
      
      const { authorizationCode, userId } = request.data;
      
      if (!authorizationCode || !userId) {
        throw new HttpsError("invalid-argument", "Authorization code and userId are required");
      }
  
      // Apple 설정 불러오기
      const teamId = process.env.APPLE_TEAM_ID;
      const clientId = process.env.APPLE_CLIENT_ID;
      const keyId = process.env.APPLE_KEY_ID;
      const privateKey = (process.env.APPLE_PRIVATE_KEY || "").replace(/\\n/g, "\n");
  
      if (!teamId || !clientId || !keyId || !privateKey) {
        throw new HttpsError("internal", "Missing Apple configuration");
      }
  
      // JWT 생성
      const clientSecret = jwt.sign({}, privateKey, {
        algorithm: "ES256",
        expiresIn: "5m",
        audience: "https://appleid.apple.com",
        issuer: teamId,
        subject: clientId,
        keyid: keyId,
      });
  
      // Apple 서버에 토큰 요청 (authorization_code 사용)
      const response = await axios.post<{
        access_token: string,
        refresh_token: string,
        id_token: string,
        token_type: string,
        expires_in: number
      }>(
        "https://appleid.apple.com/auth/token",
        new URLSearchParams({
          client_id: clientId,
          client_secret: clientSecret,
          code: authorizationCode,
          grant_type: "authorization_code",
        }).toString(),
        {
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
        }
      );
  
      // 리프레시 토큰을 Firestore에 저장 - 클라이언트 구조에 맞게 수정
      if (response.data && response.data.refresh_token) {
        // 클라이언트 구조에 맞게 collection(userId).document("info")로 변경
        await admin.firestore().collection(userId).doc("info").set({
          appleRefreshToken: response.data.refresh_token
        }, { merge: true }); // merge: true로 기존 필드 유지
        
        return { success: true };
      } else {
        throw new HttpsError("internal", "Failed to request refresh token from Apple");
      }
    } catch (error) {
      console.error("Error request Apple refresh token:", error);
      throw new HttpsError("internal", "Failed to process Apple sign in");
    }
});
  
export const refreshAppleAccessToken = onCall({
  cors: true,
  maxInstances: 10,
  region: "asia-northeast3",
}, async (request) => {
  // 인증 확인
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  try {
    const userId = request.auth.uid;
    console.log("Auth user ID:", userId);
    
    // 클라이언트 경로에서만 시도
    console.log(`Fetching from collection(${userId})/doc(info)`);
    const userDoc = await admin.firestore().collection(userId).doc("info").get();
    
    if (!userDoc.exists) {
      console.error(`User document not found for ID: ${userId}`);
      throw new HttpsError("not-found", `User document not found at collection('${userId}')/doc('info')`);
    }
    
    const userData = userDoc.data();
    const refreshToken = userData?.appleRefreshToken;
    
    if (!refreshToken) {
      console.error("User document exists but has no appleRefreshToken field:", userData);
      throw new HttpsError("not-found", "Apple refresh token not found for this user");
    }
    
    console.log("Successfully retrieved refresh token from Firestore");
    
    // Apple configuration
    const teamId = process.env.APPLE_TEAM_ID;
    const clientId = process.env.APPLE_CLIENT_ID;
    const keyId = process.env.APPLE_KEY_ID;
    const privateKey = (process.env.APPLE_PRIVATE_KEY || "")
      .replace(/\\n/g, "\n");

    if (!teamId || !clientId || !keyId || !privateKey) {
      throw new HttpsError(
        "internal",
        "Missing Apple configuration environment variables."
      );
    }

    // Create client_secret JWT
    const clientSecret = jwt.sign({}, privateKey, {
      algorithm: "ES256",
      expiresIn: "5m",
      audience: "https://appleid.apple.com",
      issuer: teamId,
      subject: clientId,
      keyid: keyId,
    });

    // Request new access token from Apple
    const response = await axios.post<{access_token: string}>(
      "https://appleid.apple.com/auth/token",
      new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: "refresh_token",
        refresh_token: refreshToken,
      }).toString(),
      {
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
      }
    );

    // Return the new access token
    if (response.data && response.data.access_token) {
      return {token: response.data.access_token}; // v2에서는 객체로 반환
    } else {
      throw new HttpsError(
        "internal",
        "Failed to retrieve access token from Apple response."
      );
    }
  } catch (error: unknown) {
    console.error("Error refreshing Apple token:", error);
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if ((axios as any).isAxiosError(error)) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      console.error("Axios error details:", (error as any).response?.data);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      throw new HttpsError(
        "internal",
        `Token refresh failed: ${
          (error as any).response?.data?.error ||
          (error as Error).message
        }`
      );
    } else if (error instanceof Error) {
      throw new HttpsError(
        "internal",
        `Token refresh error: ${error.message}`
      );
    } else {
      throw new HttpsError(
        "internal",
        "An unknown error occurred during token refresh."
      );
    }
  }
});
  
export const revokeAppleAccessToken = onCall({
  cors: true,
  maxInstances: 10,
  region: "asia-northeast3",
}, async (request) => {
  // 인증 확인
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  try {
    const { token } = request.data;
    
    if (!token) {
      throw new HttpsError("invalid-argument", "Token is required");
    }

    // Apple 설정 불러오기
    const teamId = process.env.APPLE_TEAM_ID;
    const clientId = process.env.APPLE_CLIENT_ID;
    const keyId = process.env.APPLE_KEY_ID;
    const privateKey = (process.env.APPLE_PRIVATE_KEY || "").replace(/\\n/g, "\n");

    if (!teamId || !clientId || !keyId || !privateKey) {
      throw new HttpsError("internal", "Missing Apple configuration");
    }

    // JWT 생성
    const clientSecret = jwt.sign({}, privateKey, {
      algorithm: "ES256",
      expiresIn: "5m",
      audience: "https://appleid.apple.com",
      issuer: teamId,
      subject: clientId,
      keyid: keyId,
    });

    // Apple 서버에 토큰 취소 요청
    await axios.post(
      "https://appleid.apple.com/auth/revoke",
      new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: token,
        token_type_hint: "access_token" // access_token 또는 refresh_token 지정 가능
      }).toString(),
      {
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
      }
    );

    return { success: true };
    
  } catch (error: unknown) {
    console.error("Error revoking Apple token:", error);
    
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    if ((axios as any).isAxiosError(error)) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      console.error("Axios error details:", (error as any).response?.data);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      throw new HttpsError(
        "internal",
        `Token revocation failed: ${
          (error as any).response?.data?.error ||
          (error as Error).message
        }`
      );
    } else if (error instanceof Error) {
      throw new HttpsError(
        "internal",
        `Token revocation error: ${error.message}`
      );
    } else {
      throw new HttpsError(
        "internal",
        "An unknown error occurred during token revocation."
      );
    }
  }
});