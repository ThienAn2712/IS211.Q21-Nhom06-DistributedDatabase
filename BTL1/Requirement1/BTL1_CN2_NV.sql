
CREATE DATABASE LINK nv2_to_nv1  
CONNECT TO nv_read_cn1 
IDENTIFIED BY nv_read_cn1 USING 'cn1_link'; 


CREATE DATABASE LINK nv2_to_nv3  
CONNECT TO nv_read_cn3 
IDENTIFIED BY nv_read_cn3 USING 'cn3_link'; 


SELECT COUNT (*) FROM GIAMDOC_CN1.HOADON@nv2_to_nv1;
SELECT COUNT (*) FROM GIAMDOC_CN3.HOADON@nv2_to_nv3;

--------------------------------------------------------------------------------
-- Câu 6 — UNION ALL + SUM (Nhân viên CN2)
-- Mục đích: Xem tổng số lượng từng đầu sách đã bán trong hóa đơn tại cả 3 chi nhánh (nhân viên CN2 có quyền xem HD của CN1, CN3).
SELECT s.MaSach,
       s.TenSach,
       SUM(ban_data.SoLuong) AS TongSoLuongBan
FROM (
    SELECT MaSach, SoLuong FROM GIAMDOC_CN1.CHITIET_HD@nv2_to_nv1
    
    UNION ALL
    
    SELECT MaSach, SoLuong FROM GIAMDOC_CN2.CHITIET_HD
    
    UNION ALL
    
    SELECT MaSach, SoLuong FROM GIAMDOC_CN3.CHITIET_HD@nv2_to_nv3
) ban_data
JOIN GIAMDOC_CN2.SACH s ON s.MaSach = ban_data.MaSach
GROUP BY s.MaSach, s.TenSach
ORDER BY TongSoLuongBan DESC;



-- EXPLAIN CÂU TRUY VẤN CHƯA TỐI ƯU
-- 1. Kích hoạt thu thập thống kê thời gian thực trên session hiện tại
ALTER SESSION SET statistics_level = ALL;
 
-- 2. Thực thi câu truy vấn gốc với gợi ý (Hint) thu thập thông tin
SELECT /*+ GATHER_PLAN_STATISTICS */ s.MaSach,
   	s.TenSach,
   	SUM(ban_data.SoLuong) AS TongSoLuongBan
FROM (
	SELECT MaSach, SoLuong FROM GIAMDOC_CN1.CHITIET_HD@nv2_to_nv1
	UNION ALL
	SELECT MaSach, SoLuong FROM GIAMDOC_CN2.CHITIET_HD
	UNION ALL
	SELECT MaSach, SoLuong FROM GIAMDOC_CN3.CHITIET_HD@nv3_to_nv2
) ban_data
JOIN CN2.SACH s ON s.MaSach = ban_data.MaSach
GROUP BY s.MaSach, s.TenSach
ORDER BY TongSoLuongBan DESC;
 
-- 3. Tìm kiếm SQL_ID của câu lệnh vừa chạy
SELECT sql_id, sql_text
FROM v$sql
WHERE sql_text LIKE '%GATHER_PLAN_STATISTICS%ban_data%JOIN CN2.SACH%'
  AND sql_text NOT LIKE '%v$sql%'
ORDER BY last_load_time DESC;

 
-- 4. Explain câu truy vấn có SQL_ID vừa tìm được ở câu lệnh trên
SELECT * FROM TABLE(DBMS_XPLAN.display_cursor('SQL_ID', NULL, 'ALLSTATS LAST'));

































