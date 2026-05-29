----------------------------------- Tạo bảng -----------------------------------
CREATE TABLE CHINHANH ( 
    MaCN VARCHAR2(15) PRIMARY KEY, 
    TenCN VARCHAR2(100), 
    DiaChi VARCHAR2(250) 
);  

CREATE TABLE NHANVIEN ( 
    MaNV VARCHAR2(15) PRIMARY KEY, 
    HoTen VARCHAR2(100), 
    GioiTinh VARCHAR2(10), 
    NgaySinh DATE, 
    SoDienThoai VARCHAR2(15), 
    NgayVaoLam DATE, 
    MaCN VARCHAR2(15) REFERENCES CHINHANH(MaCN) 
);  

CREATE TABLE SACH ( 
    MaSach VARCHAR2(15) PRIMARY KEY, 
    TenSach VARCHAR2(200), 
    TacGia VARCHAR2(100), 
    TheLoai VARCHAR2(50), 
    NhaXuatBan VARCHAR2(100), 
    GiaBan NUMBER(12, 2) 
); 

CREATE TABLE KHACHHANG ( 
    MaKH VARCHAR2(15) PRIMARY KEY, 
    HoTen VARCHAR2(100), 
    GioiTinh VARCHAR2(10),
    NgaySinh DATE, 
    DiaChi VARCHAR2(250), 
    SoDienThoai VARCHAR2(15) 
); 

CREATE TABLE HOADON ( 
    MaHD VARCHAR2(20) PRIMARY KEY, 
    MaKH VARCHAR2(15) REFERENCES KHACHHANG(MaKH), 
    MaNV VARCHAR2(15) REFERENCES NHANVIEN(MaNV), 
    NgayLap TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    TongTien NUMBER(15, 2) 
);  

CREATE TABLE CHITIET_HD ( 
    MaHD VARCHAR2(20), 
    MaSach VARCHAR2(15), 
    SoLuong NUMBER, 
    PRIMARY KEY (MaHD, MaSach), 
    FOREIGN KEY (MaHD) REFERENCES HOADON(MaHD), 
    FOREIGN KEY (MaSach) REFERENCES SACH(MaSach) 
); 

CREATE TABLE KHO_NHAP ( 
    MaCN VARCHAR2(15), 
    MaSach VARCHAR2(15), 
    NgayNhap DATE, 
    SoLuongNhap NUMBER, 
    GiaNhap NUMBER(12, 2), 
    PRIMARY KEY (MaCN, MaSach, NgayNhap), 
    FOREIGN KEY (MaCN) REFERENCES CHINHANH(MaCN), 
    FOREIGN KEY (MaSach) REFERENCES SACH(MaSach) 
); 

CREATE TABLE KHO_BAN ( 
    MaCN VARCHAR2(15), 
    MaSach VARCHAR2(15), 
    SoLuongTon NUMBER DEFAULT 0, 
    TrangThai VARCHAR2(20), 
    PRIMARY KEY (MaCN, MaSach), 
    FOREIGN KEY (MaCN) REFERENCES CHINHANH(MaCN), 
    FOREIGN KEY (MaSach) REFERENCES SACH(MaSach) 
);  


ALTER TABLE SACH MODIFY (TENSACH VARCHAR2(500));

ALTER TABLE SACH MODIFY (TACGIA VARCHAR2(300));

ALTER TABLE SACH MODIFY (NHAXUATBAN VARCHAR2(300));

------------------------------- Insert data
GRANT UNLIMITED TABLESPACE TO giamdoc_cn2;
-- CHINHANH
Insert into CHINHANH (MACN,TENCN,DIACHI) values ('CN002','Fahasa Nguyễn Huệ','40 Nguyễn Huệ, Phường Sài Gòn, Thành phố Hồ Chí Minh');

-- SACH
@"D:\Năm 3\Kì 2\Distributed\SACH_CN2.sql"

-- KHACHHANG
@"D:\Năm 3\Kì 2\Distributed\KHACHHANG_CN2.sql"

-- NHANVIEN
@"D:\Năm 3\Kì 2\Distributed\NHANVIEN_CN002.sql"

-- KHONHAP
@"D:\Năm 3\Kì 2\Distributed\KHO_NHAP_CN2.sql"

-- KHOBAN
@"D:\Năm 3\Kì 2\Distributed\KHO_BAN_CN2.sql"

-- HOADON
@"D:\Năm 3\Kì 2\Distributed\HOADON_CN2.sql"

-- CHITIET_HD
@"D:\Năm 3\Kì 2\Distributed\CHITIET_HD_CN2.sql"

Commit;



select count(*) from NHANVIEN;
---------------------------------------
select count (*) from SACH;
select count (*) 
from SACH
where THELOAI = N'Văn học';

---------------------------------------
select count (*) from KHACHHANG;
---------------------------------------
select count(*) from HOADON;
---------------------------------------
select count(*) from CHITIET_HD;
---------------------------------------
SELECT COUNT(*) FROM HOADON h 
WHERE NOT EXISTS (SELECT 1 FROM CHITIET_HD c WHERE c.MaHD = h.MaHD);
---------------------------------------
select count(*) from KHO_NHAP;
---------------------------------------
select count(*) from KHO_BAN;





--------------------------------------------------------------------------------

-- Tạo các user 
-- Nhân viên
alter session set "_ORACLE_SCRIPT"=true;
CREATE USER nhanvien_cn2 IDENTIFIED BY nhanvien_cn2;

-- Quản lý kho
CREATE USER quanlikho_cn2 IDENTIFIED BY quanlikho_cn2;

-- Nhân viên cho truy cập từ xa từ các chi nhánh còn lại
CREATE USER nv_read_cn2 IDENTIFIED BY nv_read_cn2;

-- Quản lý kho cho truy cập từ xa từ các chi nhánh còn lại
CREATE USER qlk_read_cn2 IDENTIFIED BY qlk_read_cn2;
--------------------------------------------------------------------------------

-- Grant các quyền
-- Quản lý kho 
GRANT CONNECT, RESOURCE, CREATE DATABASE LINK TO quanlikho_cn2; 

GRANT SELECT, INSERT, UPDATE, DELETE ON KHO_NHAP TO quanlikho_cn2; 

GRANT SELECT, INSERT, UPDATE, DELETE ON KHO_BAN TO quanlikho_cn2; 

GRANT SELECT, INSERT, UPDATE, DELETE ON SACH TO quanlikho_cn2; 
--------------------------------------------------------------------------------

-- Nhân viên
GRANT CONNECT, RESOURCE, CREATE DATABASE LINK TO nhanvien_cn2; 

GRANT SELECT, INSERT ON HOADON TO nhanvien_cn2; 

GRANT SELECT, INSERT ON CHITIET_HD TO nhanvien_cn2; 

GRANT SELECT ON GIAMDOC_CN2.SACH TO nhanvien_cn2;

GRANT SELECT ON KHO_BAN TO nhanvien_cn2; 

GRANT SELECT, INSERT, UPDATE, DELETE ON KHACHHANG TO nhanvien_cn2; 
--------------------------------------------------------------------------------

-- Quản lý kho và nhân viên từ xa
GRANT CONNECT TO nv_read_cn2; 

GRANT SELECT ON HOADON TO nv_read_cn2; 

GRANT SELECT ON SACH TO nv_read_cn2;

GRANT SELECT ON CHITIET_HD TO nv_read_cn2; 

GRANT CONNECT TO qlk_read_cn2; 

GRANT SELECT ON KHO_NHAP TO qlk_read_cn2; 

GRANT SELECT ON KHO_BAN TO qlk_read_cn2;
--------------------------------------------------------------------------------

-- Database link
-- Tạo PUBLIC link sang CN1
CREATE PUBLIC DATABASE LINK gd2_to_gd1
CONNECT TO giamdoc_cn1 IDENTIFIED BY giamdoc_cn1
USING 'cn1_link';

-- Tạo PUBLIC link sang CN3
CREATE PUBLIC DATABASE LINK gd2_to_gd3
CONNECT TO giamdoc_cn3 IDENTIFIED BY giamdoc_cn3
USING 'cn3_link';

drop database link gd2_to_gd3;
drop database link gd2_to_gd1;
-- Test DB link
SELECT * FROM CHINHANH@gd2_to_gd1;
SELECT COUNT (*) FROM HOADON@gd2_to_gd1;

SELECT * FROM CHINHANH@gd2_to_gd3;
SELECT COUNT (*) FROM HOADON@gd2_to_gd3;
SELECT COUNT (*) FROM CHITIET_HD@gd2_to_gd3;
SELECT COUNT(*) FROM GIAMDOC_CN1.CHITIET_HD@gd2_to_gd1;
SELECT COUNT(*) FROM GIAMDOC_CN3.CHITIET_HD@gd2_to_gd3;
SELECT COUNT(*) FROM GIAMDOC_CN2.CHITIET_HD;
--------------------------------------------------------------------------------

