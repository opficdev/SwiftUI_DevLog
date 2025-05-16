import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";

// GitHub OAuth 인증 및 커스텀 토큰 발급 함수
export const requestGithubTokens = onCall({
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
