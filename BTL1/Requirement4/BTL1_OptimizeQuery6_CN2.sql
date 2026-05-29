-- Câu truy vấn chưa tối ưu
SELECT * 
FROM sach
where tacgia = 'Orhan Pamuk';


SELECT /*+ GATHER_PLAN_STATISTICS */
       MaSach,
       TenSach,
       TacGia,
       TheLoai,
       NhaXuatBan,
       GiaBan
FROM SACH
WHERE TacGia = 'Orhan Pamuk';


SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +PREDICATE'));




EXPLAIN PLAN FOR
SELECT 
    MaSach,
    TenSach,
    TacGia,
    TheLoai,
    NhaXuatBan,
    GiaBan
FROM SACH
WHERE TacGia = 'Orhan Pamuk';

SELECT * 
FROM TABLE(DBMS_XPLAN.DISPLAY);


CREATE INDEX IDX_SACH_TACGIA
ON SACH(TacGia);

SELECT 
    MaSach,
    TenSach,
    TacGia,
    TheLoai,
    NhaXuatBan,
    GiaBan
FROM SACH
WHERE TacGia = 'Orhan Pamuk';




EXPLAIN PLAN FOR
SELECT 
    MaSach,
    TenSach,
    TacGia,
    TheLoai,
    NhaXuatBan,
    GiaBan
FROM SACH
WHERE TacGia = 'Orhan Pamuk';

SELECT * 
FROM TABLE(DBMS_XPLAN.DISPLAY);


----------------------------------------


SELECT /*+ GATHER_PLAN_STATISTICS */
       hd.MaHD,
       hd.MaKH,
       hd.MaNV,
       hd.NgayLap,
       hd.TongTien
FROM HOADON hd
WHERE hd.MaKH = 'KH0068'
ORDER BY hd.NgayLap DESC;


EXPLAIN PLAN FOR
SELECT *
FROM HOADON
WHERE MaKH = 'KH0068';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);

CREATE INDEX IDX_HOADON_MAKH
ON HOADON(MaKH);




SELECT /*+ INDEX(hd IDX_HOADON_MAKH) */
       *
FROM HOADON hd
WHERE hd.MaKH = 'KH0068';

-- Index scan
EXPLAIN PLAN FOR
SELECT /*+ INDEX(hd IDX_HOADON_MAKH) */
       *
FROM HOADON hd
WHERE hd.MaKH = 'KH0068';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY);




