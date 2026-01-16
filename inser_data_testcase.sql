-- =============================================
-- KIỂM TRA KẾT QUẢ TỔNG HỢP
-- =============================================
SELECT 'USERS TABLE' as Table_Name;
SELECT * FROM Users;

SELECT 'POSTS TABLE (Check like_count)' as Table_Name;
SELECT * FROM Posts;

SELECT 'COMMENTS TABLE' as Table_Name;
SELECT * FROM Comments;

SELECT 'LIKES TABLE' as Table_Name;
SELECT * FROM Likes;

SELECT 'FRIENDS TABLE' as Table_Name;
SELECT * FROM Friends;

SELECT 'LOGS (Check User & Post Logs)' as Table_Name;
SELECT * FROM user_log ORDER BY log_time DESC LIMIT 20;
SELECT * FROM post_log ORDER BY log_time DESC LIMIT 20;


-- =============================================================
-- PHẦN TEST CASES CHI TIẾT (CHẠY TỪNG KHỐI ĐỂ KIỂM TRA)
-- =============================================================

-- -------------------------------------------------------------
-- TEST CASE 1: KIỂM TRA RÀNG BUỘC ĐĂNG KÝ (USER)
-- -------------------------------------------------------------
SELECT '--- TEST 1: Đăng ký trùng Username/Email ---' AS Test_Description;

-- 1.1. Test trùng Username
CALL sp_register_user('nguyenvanan', 'newpass', 'new.email@example.com');

-- 1.2. Test trùng Email
CALL sp_register_user('newuser', 'newpass', 'an.nguyen@example.com');

-- 1.3. Kiểm tra Log đăng ký
SELECT * FROM user_log WHERE action = 'User Register!' ORDER BY log_time DESC LIMIT 5;


-- -------------------------------------------------------------
-- TEST CASE 2: KIỂM TRA LOGIC BÀI VIẾT (POST)
-- -------------------------------------------------------------
SELECT '--- TEST 2: Đăng bài viết rỗng ---' AS Test_Description;

-- 2.1. Test Content rỗng
CALL sp_create_post(1, '');
CALL sp_create_post(1, '   ');

-- 2.2. Kiểm tra Log đăng bài
SELECT * FROM post_log WHERE action = 'Create Post' ORDER BY log_time DESC LIMIT 5;


-- -------------------------------------------------------------
-- TEST CASE 3: KIỂM TRA LOGIC LIKE & UPDATE LIKE_COUNT
-- -------------------------------------------------------------
SELECT '--- TEST 3: Like, Unlike và Tự động cập nhật Count ---' AS Test_Description;

-- 3.1. User 5 Like Post 1 (Thành công)
CALL sp_like_post(5, 1);

-- 3.2. User 5 cố tình Like Post 1 lần nữa (Mong đợi: Lỗi Duplicate Entry)
CALL sp_like_post(5, 1);

-- 3.3. User 5 Unlike Post 1 (Thành công)
CALL sp_unlike_post(5, 1);


-- -------------------------------------------------------------
-- TEST CASE 4: KIỂM TRA LOGIC BẠN BÈ (FRIENDS)
-- -------------------------------------------------------------
SELECT '--- TEST 4: Gửi và Chấp nhận kết bạn ---' AS Test_Description;

-- 4.1. Tự gửi kết bạn cho chính mình (Mong đợi: Lỗi)
CALL sp_send_friend_request(1, 1);

-- 4.2. Gửi lời mời từ User 8 -> User 10
CALL sp_send_friend_request(8, 10);

-- 4.3. Chấp nhận lời mời (Thành công -> Accepted cả 2 chiều)
CALL sp_accept_friend_request(8, 10);

-- -------------------------------------------------------------
-- TEST CASE 5: KIỂM TRA XOÁ BÀI VIẾT (DELETE POST)
-- -------------------------------------------------------------
SELECT '--- TEST 5: Xoá bài viết và dữ liệu liên quan ---' AS Test_Description;

-- 5.1. Thực hiện xoá
CALL sp_delete_post(1, 1); -- post_id = 1, user_id = 1


-- -------------------------------------------------------------
-- TEST CASE 6: KIỂM TRA XOÁ USER (CASCADE HOẶC MANUAL DELETE)
-- -------------------------------------------------------------
SELECT '--- TEST 6: Xoá User và kiểm tra sạch dữ liệu ---' AS Test_Description;
-- xoá user_id = 2
CALL sp_delete_user(2);

-- Kiểm tra Log xoá User
SELECT * FROM user_log WHERE user_id = @del_id AND action = 'User has been deleted!';

DELETE FROM Users;
DELETE FROM Comments;
DELETE FROM Friends;
DELETE FROM Likes;
DELETE FROM post_log;
DELETE FROM Posts;
DELETE FROM user_log;