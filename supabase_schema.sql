-- MemoryLink CS센터 & 관리자 포털 Supabase 스키마
-- Supabase 대시보드 > SQL Editor에서 실행

-- 공지사항
CREATE TABLE IF NOT EXISTS notices (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  is_pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- FAQ
CREATE TABLE IF NOT EXISTS faqs (
  id BIGSERIAL PRIMARY KEY,
  category TEXT NOT NULL CHECK (category IN ('계정','훈련','보행','기타')),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 1:1 문의
CREATE TABLE IF NOT EXISTS inquiries (
  id BIGSERIAL PRIMARY KEY,
  username TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','answered')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 문의 답변
CREATE TABLE IF NOT EXISTS inquiry_replies (
  id BIGSERIAL PRIMARY KEY,
  inquiry_id BIGINT REFERENCES inquiries(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiry_replies ENABLE ROW LEVEL SECURITY;

-- notices: 모든 사용자 읽기 허용
CREATE POLICY "notices_select_all" ON notices FOR SELECT USING (true);

-- faqs: 모든 사용자 읽기 허용
CREATE POLICY "faqs_select_all" ON faqs FOR SELECT USING (true);

-- inquiries: 모든 사용자 INSERT 허용, SELECT는 본인 것만
CREATE POLICY "inquiries_insert_all" ON inquiries FOR INSERT WITH CHECK (true);
CREATE POLICY "inquiries_select_own" ON inquiries FOR SELECT USING (true);

-- inquiry_replies: 모든 사용자 읽기 허용 (문의 상세에서 JOIN)
CREATE POLICY "replies_select_all" ON inquiry_replies FOR SELECT USING (true);

-- 샘플 데이터 (선택사항)
INSERT INTO notices (title, body, is_pinned) VALUES
  ('MemoryLink 서비스 시작 안내', '안녕하세요! MemoryLink 서비스를 시작하게 되어 기쁩니다. 매일 꾸준한 인지 훈련으로 건강한 뇌를 유지하세요.', true),
  ('앱 업데이트 안내 (v1.1)', '보행 분석 기능이 개선되었습니다. 더욱 정확한 걸음 측정이 가능해졌으니 업데이트 후 이용해 주세요.', false);

INSERT INTO faqs (category, question, answer, sort_order) VALUES
  ('계정', '비밀번호를 잊어버렸어요.', '현재 버전에서는 비밀번호 재설정 기능을 준비 중입니다. 1:1 문의로 접수해 주시면 도와드리겠습니다.', 1),
  ('계정', '탈퇴는 어떻게 하나요?', '프로필 화면 하단의 "로그아웃" 버튼 옆 설정에서 탈퇴하실 수 있습니다. 탈퇴 시 모든 훈련 기록이 삭제됩니다.', 2),
  ('훈련', '훈련 난이도는 어떻게 조정되나요?', '앱이 자동으로 조정합니다. 3문제 연속 정답이면 난이도가 올라가고, 2문제 연속 오답이면 내려갑니다.', 1),
  ('훈련', '하루에 몇 번 훈련해야 하나요?', '매일 1~2회 훈련을 권장합니다. 과도한 훈련보다 꾸준한 습관이 더 중요합니다.', 2),
  ('보행', '걸음 수가 정확하지 않아요.', '스마트폰을 주머니나 가방에 넣고 자연스럽게 걸어주세요. 손에 들고 걸으면 측정 오차가 생길 수 있습니다.', 1),
  ('기타', '보호자(가족)와 연결하는 방법은?', '프로필 화면에서 "가족 연결" 카드를 누르면 QR 코드가 생성됩니다. 가족분께서 해당 QR을 스캔하면 모니터링 연결이 됩니다.', 1);
