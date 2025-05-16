import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import * as jwt from "jsonwebtoken";

// Apple ID 토큰 페이로드 인터페이스 정의
interface AppleTokenPayload {
  iss: string;          // 발행자 (issuer)
  sub: string;          // 사용자 ID (subject)
  aud: string;          // 앱 ID (audience)
  iat: number;          // 발행 시간 (issued at)
  exp: number;          // 만료 시간 (expiration)
  email?: string;       // 사용자 이메일 (선택적)
  email_verified?: string; // 이메일 인증 여부
  is_private_email?: boolean; // 개인정보 보호 이메일 여부
  nonce?: string;       // 보안용 난수값
  nonce_supported?: boolean;
  real_user_status?: number; // 실제 사용자 상태
  auth_time?: number;   // 인증 시간
}

// Apple 설정 불러오기
const teamId = process.env.APPLE_TEAM_ID;
const clientId = process.env.APPLE_CLIENT_ID;
const keyId = process.env.APPLE_KEY_ID;
const privateKey = (process.env.APPLE_PRIVATE_KEY || "").replace(/\\n/g, "\n");

export const requestAppleCustomToken = onCall({
  cors: true,
  maxInstances: 10,
  region: "asia-northeast3",
}, async (request) => {
  try {
    const { idToken, authorizationCode } = request.data;
    
    if (!idToken || !authorizationCode) {
      throw new HttpsError('invalid-argument', 'ID token and authorization code are required');
    }

    // Apple 설정 불러오기
    if (!teamId || !clientId || !keyId || !privateKey) {
      throw new HttpsError('internal', 'Missing Apple configuration');
    }

    // 1. Verify and decode the Apple ID token
    let decodedToken: AppleTokenPayload;
    try {
      decodedToken = jwt.decode(idToken) as AppleTokenPayload;
      if (!decodedToken) {
        throw new HttpsError('invalid-argument', 'Invalid Apple ID token');
      }
    } catch (error) {
      console.error('Error decoding Apple ID token:', error);
      throw new HttpsError('invalid-argument', 'Failed to decode Apple ID token');
    }

    // 2. Get user information from the decoded token
    const userId = decodedToken.sub; // Apple's unique user ID
    const email = decodedToken.email;

    if (!userId) {
      throw new HttpsError('internal', 'Could not get user ID from Apple token');
    }
    
    // 4. Find or create Firebase user

    let uid;
    try {
      // 애플에서 받아오는 토큰에서 이메일이 존재하는 경우
      if (email) {
        try {
          const userRecord = await admin.auth().getUserByEmail(email);
          uid = userRecord.uid;
          console.log(`Found existing user by email (${email})`);
        } catch (error) {
          // User not found by email, create new user
          const userRecord = await admin.auth().createUser({
            email: email,
            emailVerified: decodedToken.email_verified === 'true',
          });
          uid = userRecord.uid;
          console.log(`Created new user with email: ${uid}`);
        }
      } 
      else {
        // 애플 정책 변환 또는 알수 없는 이유로 이메일을 못받아오는 경우
        try {
          const userRecord = await admin.auth().getUser(`apple:${userId}`);
          uid = userRecord.uid;
        } catch (error) {
          // User not found, create new user with Apple UID
          const userRecord = await admin.auth().createUser({});
          uid = userRecord.uid;
          console.log(`Created new user with Apple ID: ${uid}`);
        }
      }

      // 5. Save refresh token to Firestore
      if (refreshToken) {
        await admin.firestore().collection(uid).doc("info").set({
          appleRefreshToken: refreshToken
        }, { merge: true });
      }

      // 6. Create Firebase custom token
      const customToken = await admin.auth().createCustomToken(uid);
      
      return {
        customToken
      };
    } catch (error) {
      console.error('Error processing Apple authentication:', error);
      throw new HttpsError(
        'internal',
        error instanceof Error ? error.message : 'Unknown error occurred during authentication'
      );
    }
  } catch (error) {
    console.error('Apple custom token creation error:', error);
    throw new HttpsError(
      'internal',
      error instanceof Error ? error.message : 'Unknown error occurred'
    );
  }
});

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
  
      if (!teamId || !clientId || !keyId || !privateKey) {
        throw new HttpsError("internal", "Missing Apple configuration");
      }

      const refreshToken = await requestAppleRefreshTokenHelper(authorizationCode);
      console.log("appleRefreshToken:", refreshToken);
      // Apple 서버에서 받은 응답을 확인

      await admin.firestore().collection("users").doc(uid).collection("userData").doc("tokens").set({
        appleRefreshToken: refreshToken
      }, { merge: true });

      return {
        success: true,
        refreshToken: refreshToken
      };
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


export async function requestAppleRefreshTokenHelper(authorizationCode: string): Promise<string> {
  // Apple 설정 불러오기
  if (!teamId || !clientId || !keyId || !privateKey) {
    throw new HttpsError('internal', 'Missing Apple configuration');
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
  const tokenResponse = await axios.post<{
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

  const refreshToken = tokenResponse.data.refresh_token;
  if (!refreshToken) {
    throw new HttpsError('internal', 'Apple에서 refresh_token을 받아오지 못했습니다.');
  }
  return refreshToken;
}
