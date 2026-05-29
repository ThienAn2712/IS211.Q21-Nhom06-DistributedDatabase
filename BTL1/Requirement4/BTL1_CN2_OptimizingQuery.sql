
-- Câu truy vấn 6 chưa tối ưu

ALTER SESSION SET statistics_level = ALL;


SELECT /*+ GATHER_PLAN_STATISTICS */ 
       s.MaSach,
       s.TenSach,
       SUM(ban_data.SoLuong) AS TongSoLuongBan
FROM (
    SELECT MaSach, SoLuong FROM CHITIET_HD@gd2_to_gd1
    UNION ALL
    SELECT MaSach, SoLuong FROM CHITIET_HD
    UNION ALL
    SELECT MaSach, SoLuong FROM CHITIET_HD@gd2_to_gd3
) ban_data
JOIN SACH s ON s.MaSach = ban_data.MaSach
GROUP BY s.MaSach, s.TenSach
ORDER BY TongSoLuongBan DESC;


-- Lấy SQL_ID của truy vấn chưa tối ưu
SELECT sql_id, sql_text
FROM v$sql
WHERE sql_text LIKE '%GATHER_PLAN_STATISTICS%ban_data%'
  AND sql_text NOT LIKE '%v$sql%'
ORDER BY last_load_time DESC;


SELECT *
FROM TABLE(DBMS_XPLAN.display_cursor('3w6k17qt6gf6w', NULL, 'ALLSTATS LAST'));





-- Câu truy vấn đã tối ưu

SELECT /*+ GATHER_PLAN_STATISTICS */
       MaSach,
       TenSach,
       SUM(Tong_Phan_Manh) AS TongSoLuongBan
FROM (
    -- CN1: xử lý từ xa qua dblink gd2_to_gd1
    SELECT s.MaSach,
           s.TenSach,
           SUM(ct.SoLuong) AS Tong_Phan_Manh
    FROM SACH@gd2_to_gd1 s
    JOIN CHITIET_HD@gd2_to_gd1 ct 
         ON s.MaSach = ct.MaSach
    GROUP BY s.MaSach, s.TenSach

    UNION ALL

    -- CN2: xử lý cục bộ
    SELECT s.MaSach,
           s.TenSach,
           SUM(ct.SoLuong) AS Tong_Phan_Manh
    FROM SACH s
    JOIN CHITIET_HD ct 
         ON s.MaSach = ct.MaSach
    GROUP BY s.MaSach, s.TenSach

    UNION ALL

    -- CN3: xử lý từ xa qua dblink gd2_to_gd3
    SELECT s.MaSach,
           s.TenSach,
           SUM(ct.SoLuong) AS Tong_Phan_Manh
    FROM SACH@gd2_to_gd3 s
    JOIN CHITIET_HD@gd2_to_gd3 ct 
         ON s.MaSach = ct.MaSach
    GROUP BY s.MaSach, s.TenSach
) all_branches
GROUP BY MaSach, TenSach
ORDER BY TongSoLuongBan DESC;

-- Lấy ID
SELECT sql_id, sql_text
FROM v$sql
WHERE sql_text LIKE '%GATHER_PLAN_STATISTICS%Tong_Phan_Manh%'
  AND sql_text NOT LIKE '%v$sql%'
ORDER BY last_load_time DESC;



SELECT *
FROM TABLE(DBMS_XPLAN.display_cursor('5d5c7mpqp1p3x', NULL, 'ALLSTATS LAST'));












