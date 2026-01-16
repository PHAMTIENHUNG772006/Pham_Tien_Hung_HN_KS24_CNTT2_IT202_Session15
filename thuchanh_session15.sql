/*
 * DATABASE SETUP - SESSION 15 EXAM
 * Database: StudentManagement
 */

DROP DATABASE IF EXISTS StudentManagement;
CREATE DATABASE StudentManagement;
USE StudentManagement;

-- =============================================
-- 1. TABLE STRUCTURE
-- =============================================

-- Table: Students
CREATE TABLE Students (
    StudentID CHAR(5) PRIMARY KEY,
    FullName VARCHAR(50) NOT NULL,
    TotalDebt DECIMAL(10,2) DEFAULT 0
);

-- Table: Subjects
CREATE TABLE Subjects (
    SubjectID CHAR(5) PRIMARY KEY,
    SubjectName VARCHAR(50) NOT NULL,
    Credits INT CHECK (Credits > 0)
);

-- Table: Grades
CREATE TABLE Grades (
    StudentID CHAR(5),
    SubjectID CHAR(5),
    Score DECIMAL(4,2) CHECK (Score BETWEEN 0 AND 10),
    PRIMARY KEY (StudentID, SubjectID),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students(StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID)
);

-- Table: GradeLog
CREATE TABLE GradeLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    StudentID CHAR(5),
    OldScore DECIMAL(4,2),
    NewScore DECIMAL(4,2),
    ChangeDate DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- 2. SEED DATA
-- =============================================

-- Insert Students
INSERT INTO Students (StudentID, FullName, TotalDebt) VALUES 
('SV01', 'Ho Khanh Linh', 5000000),
('SV03', 'Tran Thi Khanh Huyen', 0);

-- Insert Subjects
INSERT INTO Subjects (SubjectID, SubjectName, Credits) VALUES 
('SB01', 'Co so du lieu', 3),
('SB02', 'Lap trinh Java', 4),
('SB03', 'Lap trinh C', 3);

-- Insert Grades
INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV01', 'SB01', 8.5),
('SV03', 'SB02', 3.0); 

-- End of File



-- PHẦN A – CƠ BẢN (4 điểm)

-- Câu 1 (Trigger - 2đ): Nhà trường yêu cầu điểm số (Score) nhập vào hệ thống phải luôn hợp lệ (từ 0 đến 10). Hãy viết một Trigger có tên tg_CheckScore chạy trước khi thêm (BEFORE INSERT) dữ liệu vào bảng Grades
delimiter $$
create trigger tg_CheckScore 
before insert
on Grades
for each row
begin
	
	if new.Score < 0  then 
    update Grades
    set new.Score = 0;
    end if;
    
    
    if new.Score > 10  then 
    update Grades
    set new.Score = 10;
    end if;
    
end $$
delimiter ;


INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV05', 'SB02', -1); -- Failed

INSERT INTO Grades (StudentID, SubjectID, Score) VALUES 
('SV06', 'SB01', 8.5); -- Passed


-- Câu 2 (Transaction - 2đ): Viết một đoạn script sử dụng Transaction để thêm một sinh viên mới. Yêu cầu đảm bảo tính trọn vẹn "All or Nothing" của dữ liệu

start transaction ;
insert into Students (StudentID, FullName) values 
('SV02', 'Ha Bich Ngoc');
update students set TotalDebt = 5000000 where StudentID = 'SV02';
commit;




-- PHẦN B – KHÁ (3 điểm)

-- Câu 3 (Trigger - 1.5đ): Để chống tiêu cực trong thi cử, mọi hành động sửa đổi điểm số cần được ghi lại. Hãy viết Trigger tên tg_LogGradeUpdate chạy sau khi cập nhật (AFTER UPDATE) trên bảng Grades.

delimiter $$
create trigger tg_LogGradeUpdate 
after update
on Grades
for each row
begin
	
	insert into GradeLog(StudentID,OldScore,NewScore ,ChangeDate  ) values (old.StudentID,old.Score,new.Score , now());
    
end $$
delimiter ;


update Grades set Score = 8.5 where StudentID = 'SV01';
select * from students;
select * from Grades;

-- Câu 4 (Transaction & Procedure cơ bản - 1.5đ): Viết một Stored Procedure đơn giản tên sp_PayTuition thực hiện việc đóng học phí cho sinh viên 'SV01' với số tiền 2,000,000.

delimiter $$
create procedure sp_PayTuition (p_student_id char(5), p_TotalDebt decimal(10,2))
begin

	start transaction;
    
		if not exists (select TotalDebt from students where StudentID = p_student_id) < 0 then
			ROLLBACK;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Lỗi : số tiền trong tài khoản không đủ';
            rollback;
		end if;
    
		update students set TotalDebt = TotalDebt - p_TotalDebt where StudentID = p_student_id;
	commit;
    
end $$
delimiter ;

call sp_PayTuition('SV01',2000000);

select * from students;


-- Câu 5 (Trigger nâng cao - 1.5đ): Viết Trigger tên tg_PreventPassUpdate.

delimiter $$
create trigger tg_PreventPassUpdate 
before update
on Grades
for each row
begin
	
    if old.Score >= 4 then
			ROLLBACK;
			SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Số điểm của bạn đã đạt không được phép sửa';
            rollback;
	END IF;
        
end $$
delimiter ;

update Grades set Score = 8.5 where StudentID = 'SV01';


-- Câu 6 (Stored Procedure & Transaction - 1.5đ): Viết một Stored Procedure tên sp_DeleteStudentGrade nhận vào p_StudentID và p_SubjectID. Thủ tục này thực hiện việc sinh viên xin hủy môn học nhưng phải đảm bảo an toàn dữ liệu:


-- Câu 6
delimiter //
create procedure sp_DeleteStudentGrade(
	in p_StudentID char(5),
    in p_SubjectID char(5))
begin
	declare current_score decimal(10,2);

	start transaction;
		select score into current_score
        from grades
        where StudentId = p_StudentID and SubjectID = p_SubjectId;

	insert into GradeLog(studentId, oldScore, newScore, changeDate)
    value(p_StudentID, current_score, null, now());

    delete from grades
    where studentID = p_studentID and subjectId = p_subjectID;

    if row_count() = 0 then
		rollback;
	else
		commit;
	end if;
end //
delimiter ;