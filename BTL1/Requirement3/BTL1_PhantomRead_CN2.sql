------T1
ALTER SESSION SET ISOLATION_LEVEL = READ COMMITTED;
COMMIT;

SELECT COUNT(*) AS SoLuongSachVanHoc
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';

------T3
SELECT COUNT(*) AS SoLuongSachVanHoc
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';


-------------Resolution
DELETE FROM SACH@gd2_to_gd3
WHERE MaSach = 'S_DEMO_VH01';


COMMIT;

            
------T1
ALTER SESSION SET ISOLATION_LEVEL = SERIALIZABLE;
COMMIT;

SELECT COUNT(*) AS SoLuongSachVanHoc
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';


------T3
SELECT COUNT(*) AS SoLuongSachVanHoc
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';

------T4
COMMIT;

SELECT COUNT(*) AS SoLuongSachVanHoc
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';

---------------


rollback;

SELECT * 
FROM SACH@gd2_to_gd3
WHERE TheLoai = 'Văn học';


DELETE FROM SACH@gd2_to_gd3
WHERE MaSach = 'S_DEMO_VH02';

commit;

















