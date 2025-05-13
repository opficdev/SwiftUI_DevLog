import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import * as jwt from "jsonwebtoken";
import * as dotenv from "dotenv";

// .env 파일 로드
dotenv.config();

admin.initializeApp();

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

  // GitHub OAuth 인증 및 커스텀 토큰 발급 함수
  export const requestGithubCustomTokens = onCall({
    cors: true,
    maxInstances: 10,
    region: "asia-northeast3",
  }, async (request) => {
    try {
      const { code } = request.data;
      
      if (!code) {
        throw new HttpsError('invalid-argument', '인증 코드가 필요합니다.');
      }
  
      // GitHub Client ID와 Secret 가져오기
      const clientId = process.env.GITHUB_CLIENT_ID;
      const clientSecret = process.env.GITHUB_CLIENT_SECRET;
      
      if (!clientId || !clientSecret) {
        throw new HttpsError('internal', 'GitHub 환경 설정이 누락되었습니다.');
      }
  
      // GitHub OAuth 응답 타입 정의
      interface GitHubOAuthResponse {
        access_token: string;
        token_type: string;
        scope: string;
        error?: string;
      }
  
      // 1. GitHub OAuth 토큰 획득
      const tokenResponse = await axios.post<GitHubOAuthResponse>(
        'https://github.com/login/oauth/access_token', 
        {
          client_id: clientId,
          client_secret: clientSecret,
          code: code
        }, 
        {
          headers: {
            'Accept': 'application/json'
          }
        }
      );
  
      const tokenData = tokenResponse.data;
      if (tokenData.error) {
        throw new HttpsError('invalid-argument', `GitHub OAuth 오류: ${tokenData.error}`);
      }
  
      const accessToken = tokenData.access_token;
  
      // GitHub 사용자 정보 응답 타입 정의
      interface GitHubUser {
        id: number;
        login: string;
        name?: string;
        email?: string;
        avatar_url?: string;
      }
  
      // 2. GitHub 사용자 정보 가져오기
      const userResponse = await axios.get<GitHubUser>('https://api.github.com/user', {
        headers: {
          'Authorization': `token ${accessToken}`
        }
      });
            
      const userData = userResponse.data;
      if (!userData.id || !userData.email) {
        throw new HttpsError('internal', 'GitHub 사용자 데이터를 가져오지 못했습니다.');
      }
  
      // 3. Firebase에서 GitHub 제공자로 사용자를 찾거나 생성
      let uid;

      try {
        const userRecord = await admin.auth().getUserByEmail(userData.email);
        uid = userRecord.uid; // 기존 UID 사용
        console.log(`이메일(${userData.email})로 기존 사용자를 찾았습니다.`);
      } catch (error) {
        // 사용자가 없으면 Firebase에 새 사용자 생성
        const userRecord = await admin.auth().createUser({
          displayName: userData.name || userData.login,
          email: userData.email,
          photoURL: userData.avatar_url,
        });
        uid = userRecord.uid; // 새로 생성된 UID 사용
        console.log(`이메일 있는 새 사용자가 생성됨: ${uid}`);
      }
      
      // 4. Firebase Custom Token 생성
      const customToken = await admin.auth().createCustomToken(uid);
      
      return { 
        accessToken,
        customToken
      };
    } catch (error) {
      console.error('GitHub 커스텀 토큰 생성 오류:', error);
      throw new HttpsError(
        'internal',
        error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다.'
      );
    }
  });


  export const revokeGithubAccessToken = onCall(
    {
      cors: true,
      maxInstances: 10,
      region: "asia-northeast3",
    },
    async (request) => {
      try {
        const uid = request.auth?.uid;
        if (!uid) {
          throw new HttpsError("unauthenticated", "인증된 사용자가 아닙니다.");
        }
  
        const clientId = process.env.GITHUB_CLIENT_ID;
        const clientSecret = process.env.GITHUB_CLIENT_SECRET;
  
        if (!clientId || !clientSecret) {
          throw new HttpsError("internal", "GitHub 클라이언트 설정이 누락되었습니다.");
        }
  
        const tokenDoc = await admin.firestore().collection(uid).doc("info").get();
        const accessToken = tokenDoc.exists ? tokenDoc.data()?.githubAccessToken : null;
  
        if (!accessToken) {
          throw new HttpsError("not-found", "GitHub 토큰이 존재하지 않습니다.");
        }
  
        const url = `https://api.github.com/applications/${clientId}/token`;
  
        const response = await axios.request({
          method: "delete",
          url,
          auth: {
            username: clientId,
            password: clientSecret,
          },
          data: {
            access_token: accessToken,
          },
          headers: {
            Accept: "application/vnd.github+json",
          },
        });
  
        if (response.status === 204) {
          return { success: true };
        } else {
          throw new HttpsError("internal", "토큰 폐기에 실패했습니다.");
        }
      } catch (error: any) {
        console.error("GitHub 토큰 폐기 오류:", error);
        throw new HttpsError(
          "internal",
          error?.message || "알 수 없는 오류가 발생했습니다."
        );
      }
    }
  );
