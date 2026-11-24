# 스크립트 유지보수 구조

게임의 모든 기능을 `main.gd`에서 직접 수정하지 않도록 역할별로 나눕니다.

| 파일 | 담당 영역 |
|---|---|
| `tutorial_manager.gd` | 튜토리얼 UI 생성, 단계별 완료 판정, 안내 문구 |
| `placement_manager.gd` | 오브젝트 하이라이트, 배치 표면 높이, 배치 오프셋, 화면 중앙 표면 탐색, 테이블 좌표 계산, 빈 공간 검사, 모델 AABB와 바닥 정렬 |
| `broth_manager.gd` | 육수 상태, 육수 시각화, 냄비 채움 상태와 국자 뜨기 연동 |
| `main.gd` | 씬 연결, 게임 상태, 매니저 연결 |
| `service_manager.gd` | 주문 수락, 매장 서빙, 식사 결제, 배달 완료와 서비스 상태 |
| `customer_manager.gd` | 손님 생성, 주문 준비·이동 도착·퇴장과 좌석 관리 |
| `order_manager.gd` | 주문 생성, 주문 수락과 마감 시간 |
| `cooking_manager.gd` | 조리 시작 조건, 조리 타이머, 완성 음식·쟁반과 배달 준비 처리 |
| `economy_manager.gd` | 보상, 평점, 매출과 전체 구매 장바구니 처리 |
| `day_manager.gd` | 영업시간, 하루 종료와 다음 날 전환 UI |
| `save_manager.gd` | 저장 파일 읽기/쓰기와 저장 초기화 |
| `player.gd` | 플레이어 이동과 카메라 |
| `interaction_manager.gd` | 마우스 클릭, 오른쪽 회전, 튜토리얼 입력 |
| `carrying_manager.gd` | 들고 있는 물건 상태·표시, 배치 반경, 들고 있는 국자 모델 생성과 재질 |
| `ingredient_manager.gd` | 재료 모델 미리보기, 숙주·두부피·건두부·알배기배추·팽이버섯·새우완자·소시지·청경채·목이버섯·중국당면·분모자 모델 생성과 재질 |
| `courier_manager.gd` | 배달원 생성·이동·대기열과 배달원 재질 |
| `asset_material_manager.gd` | 집게·그릇 등 공용 재질 생성과 도구 재질 적용 |
| `player_visual_manager.gd` | 플레이어 팔 표시 상태와 들고 있는 그릇의 위치·회전 안정화 |
| `broth_manager.gd` | 육수팩, 물 받기, 육수 재료 투입·끓이기, 액체 표시와 완료 효과 |
| `ui_manager.gd` | HUD 갱신, 모니터 화면 전환·스타일, 상호작용 안내, 영수증과 표시 문자열 |
| `ingredient_manager.gd` | 재료 색상, 재료 담기 효과와 3D 미리보기 |
| `courier_manager.gd` | 배달원 입장·대기·배달·퇴장, 이동 애니메이션과 위치 보정 |
| `world_manager.gd` | 공통 재질과 월드 상호작용 등록 |

## 수정 원칙

1. 주문부터 결제까지의 상태를 추가하거나 바꿀 때는 먼저 `service_manager.gd`를 확인합니다.
2. 3D 오브젝트 이동, UI 문구, 입력 키 처리는 `main.gd`에 둡니다.
3. 계산식은 `economy_manager.gd`, 저장 형식은 `save_manager.gd`에서만 수정합니다.
4. 매니저가 씬의 노드나 UI를 직접 찾지 않도록 하고, 필요한 경우 신호와 메서드로 `main.gd`에 알립니다.

`ServiceManager`는 데이터와 상태만 관리하므로, 캐릭터 애니메이션이나 그릇 위치를 바꿀 때는 `main.gd`의 연결 코드를 수정하면 됩니다.
