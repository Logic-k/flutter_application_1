-- 누락된 쓰기 권한 추가
-- Supabase 대시보드 > SQL Editor에서 실행

-- notices: 쓰기 허용 (관리자 포털에서 INSERT/UPDATE/DELETE)
CREATE POLICY "notices_insert_all" ON notices FOR INSERT WITH CHECK (true);
CREATE POLICY "notices_update_all" ON notices FOR UPDATE USING (true);
CREATE POLICY "notices_delete_all" ON notices FOR DELETE USING (true);

-- faqs: 쓰기 허용
CREATE POLICY "faqs_insert_all" ON faqs FOR INSERT WITH CHECK (true);
CREATE POLICY "faqs_update_all" ON faqs FOR UPDATE USING (true);
CREATE POLICY "faqs_delete_all" ON faqs FOR DELETE USING (true);

-- inquiries: UPDATE 허용 (문의 상태 변경 - answered)
CREATE POLICY "inquiries_update_all" ON inquiries FOR UPDATE USING (true);

-- inquiry_replies: INSERT 허용 (관리자 답변 등록)
CREATE POLICY "replies_insert_all" ON inquiry_replies FOR INSERT WITH CHECK (true);
