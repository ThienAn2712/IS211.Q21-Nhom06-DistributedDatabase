CREATE DATABASE LINK qlk2_to_qlk1  
CONNECT TO qlk_read_cn1 
IDENTIFIED BY qlk_read_cn1 USING 'CN1_LINK'; 

CREATE DATABASE LINK qlk2_to_qlk3  
CONNECT TO qlk_read_cn3 
IDENTIFIED BY qlk_read_cn3 USING 'CN3_LINK'; 

SELECT COUNT (*) FROM GIAMDOC_CN1.KHO_NHAP@qlk2_to_qlk1;
SELECT COUNT (*) FROM GIAMDOC_CN3.KHO_NHAP@qlk2_to_qlk3;

DROP DATABASE LINK qlk2_to_qlk1;
DROP DATABASE LINK qlk2_to_qlk3;


-- Câu 5: GROUP BY + COUNT + AVG (Quản lý kho CN2)
-- Mục đích: Thống kê số lần nhập kho và giá nhập trung bình theo từng đầu sách tại CN2, chỉ lấy sách được nhập ít nhất 3 lần.
SELECT s.MaSach,
       s.TenSach,
       s.TacGia,
       COUNT(kn.NgayNhap)          AS SoLanNhap,
       ROUND(AVG(kn.GiaNhap), 2)   AS GiaNhapTrungBinh,
       SUM(kn.SoLuongNhap)         AS TongSoLuongNhap
FROM   GIAMDOC_CN2.KHO_NHAP kn
JOIN   GIAMDOC_CN2.SACH s ON s.MaSach = kn.MaSach
WHERE  kn.MaCN = 'CN002' 
GROUP BY s.MaSach, s.TenSach, s.TacGia
HAVING COUNT(kn.NgayNhap) >= 3
ORDER BY TongSoLuongNhap DESC;


-- Thực thi với user: quanlikho_cn2

SELECT MaSach FROM GIAMDOC_CN2.KHO_BAN
WHERE  MaCN = 'CN002' AND SoLuongTon > 0

MINUS
(
    SELECT MaSach FROM GIAMDOC_CN1.KHO_NHAP@qlk2_to_qlk1
    WHERE  MaCN = 'CN001'
    UNION
    SELECT MaSach FROM GIAMDOC_CN3.KHO_NHAP@qlk2_to_qlk3
    WHERE  MaCN = 'CN003'
);


SELECT COUNT(DISTINCT MaSach) FROM GIAMDOC_CN2.KHO_BAN 
WHERE MaCN = 'CN002' AND SoLuongTon > 0;


SELECT COUNT(DISTINCT MaSach) FROM (
    SELECT MaSach FROM GIAMDOC_CN1.KHO_NHAP@qlk2_to_qlk1 WHERE MaCN = 'CN001'
    UNION
    SELECT MaSach FROM GIAMDOC_CN3.KHO_NHAP@qlk2_to_qlk3 WHERE MaCN = 'CN003'
);
-- Thực thi với user: quanlikho_cn2
-- Mục đích: Tìm sách có tồn kho tại CN2 mà CN1 & CN3 chưa nhập trong tháng 4/2026
-- Câu 7
SELECT s.MaSach, 
       s.TenSach, 
       kb.SoLuongTon
FROM GIAMDOC_CN2.SACH s
JOIN GIAMDOC_CN2.KHO_BAN kb ON s.MaSach = kb.MaSach
WHERE kb.MaCN = 'CN002' 
  AND kb.SoLuongTon > 0
  -- Điều kiện 1: Không tồn tại trong các đợt nhập hàng gần đây của CN1
  AND NOT EXISTS (
      SELECT 1 
      FROM GIAMDOC_CN1.KHO_NHAP@qlk2_to_qlk1 kn1
      WHERE kn1.MaSach = s.MaSach
        AND kn1.NgayNhap >= TO_DATE('01/04/2026', 'DD/MM/YYYY')
  )
  -- Điều kiện 2: Không tồn tại trong các đợt nhập hàng gần đây của CN3
  AND NOT EXISTS (
      SELECT 1 
      FROM GIAMDOC_CN3.KHO_NHAP@qlk2_to_qlk3 kn3
      WHERE kn3.MaSach = s.MaSach
        AND kn3.NgayNhap >= TO_DATE('01/04/2026', 'DD/MM/YYYY')
  );






