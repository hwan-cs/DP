# DP 💸
## 구독권 더치페이 앱

구독권 더치페이를 위해 돈 계산 및 알림을 보내주는 앱 입니다.

## 기능 🛠

- 애플/구글 계정으로 로그인, Firebase에 이벤트 정보 저장
- Firebase Dynamic Link를 통해 이벤트에 유저 초대 
- 각 이벤트에 대해 지불 금액 계산 (소유자 & 참가자로 분류) 
- 총 구독권 지출 금액 계산
- 구독권 지불일 오후 12시, 6시에 모든 참가자에게 두 번 알림을 보냄
- 다크 모드 지원

## Tech 👨🏻‍💻

DP는 아래의 오픈소스 라이브러리(CocoaPod)들을 사용합니다:
- GoogleSignIn - 구글 로그인
- Firebase/Auth - Firebase 인증
- Firebase/Firestore - Firebase 데이터베이스
- Firebase/Analytics - Firebase 통계
- Firebase/DynamicLinks - Firebase 다이나믹 링크 (초대 링크)
- SwipeCellKit - 이벤트를 스와이프하여 삭제
- DropDown - 드롭다운 라이브러리

## 실행 화면 📱

| 로그인 화면   | 홈 화면       |  설정 화면    |
| ------------- | ------------- | ------------- |
| ![alt text](https://user-images.githubusercontent.com/68496759/147366885-3f16e4f5-b7f3-47fe-9a4d-f935b4fb177a.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147366920-8c8e171e-de8f-4fcc-ab73-102ad6abe319.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147366950-c4b1b135-2811-4277-9f08-05909b86a9f9.png)  |

| 이벤트 선택 화면 (소유자)  | 이벤트 선택 화면 (참가자) | 초대하기 클릭 |
| ------------- | ------------- | ------------- |
| ![alt text](https://user-images.githubusercontent.com/68496759/147366938-55e4e2c7-2ea6-4539-b1f9-154b6031e4d3.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147366981-a7a22acd-a1cc-4ded-bc24-2e18bf0d1c1b.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147367730-0c169fff-7dc4-4df9-af9c-525defdcf679.jpg) |

| 이벤트 추가  | 새로운 이벤트 저장 |  이벤트 삭제 |
| ------------- | ------------- | ------------- |
| ![alt text](https://user-images.githubusercontent.com/68496759/147366999-8a5a5e07-3871-43d2-a998-23757297f565.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147367023-c9ccc0a3-5070-4920-b166-b9094277e750.png)  | ![alt text](https://user-images.githubusercontent.com/68496759/147367044-54d1fc67-42f4-4d8b-b56b-292ee21db336.png)  |

| 소유자 알림  | 참가자 알림 |  초대 링크 |
| ------------- | ------------- | ------------- |
| ![alt text](https://user-images.githubusercontent.com/68496759/147367671-06ce791f-d34f-4729-852f-1264bcfbf3c7.jpg)  | ![alt text](https://user-images.githubusercontent.com/68496759/147367676-fe59942f-daa6-4a0c-8cd2-d02d9115728e.jpg)  | ![alt text](https://user-images.githubusercontent.com/68496759/147367679-b5619631-bea1-427f-b037-be79df203b76.jpg)  |
