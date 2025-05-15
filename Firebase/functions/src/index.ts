import * as admin from "firebase-admin";
import * as dotenv from "dotenv";

// Apple 인증 관련 함수 가져오기
import {
  requestAppleRefreshToken,
  refreshAppleAccessToken,
  revokeAppleAccessToken
} from "./auth/apple";

// GitHub 인증 관련 함수 가져오기
import {
  requestGithubCustomTokens,
  revokeGithubAccessToken
} from "./auth/github";

import {

} from "./auth/google";

// .env 파일 로드
dotenv.config();

// Firebase 앱 초기화
admin.initializeApp();

// Apple 인증 함수들 내보내기
export { 
  requestAppleRefreshToken,
  refreshAppleAccessToken,
  revokeAppleAccessToken
};

// GitHub 인증 함수들 내보내기
export {
  requestGithubCustomTokens,
  revokeGithubAccessToken
};

// Google 인증 함수들 (나중에 구현되면 추가)
// export { ... } from "./auth/google";