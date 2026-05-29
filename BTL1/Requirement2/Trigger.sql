--reset data
-- 1. Xóa chi tiết hóa đơn trước (FK constraint)
DELETE FROM GIAMDOC_CN1.CHITIET_HD WHERE MAHD IN ('HD001', 'HD002', 'HD003', 'HD004');

-- 2. Xóa hóa đơn
DELETE FROM GIAMDOC_CN1.HOADON WHERE MAHD IN ('HD001', 'HD002', 'HD003', 'HD004');


UPDATE GIAMDOC_CN1.KHO_BAN SET SOLUONGTON = 72, TRANGTHAI ='Còn hàng' WHERE MASACH = 'S0684';
UPDATE GIAMDOC_CN2.KHO_BAN@gd1_to_gd2 SET SOLUONGTON = 79, TRANGTHAI ='Còn hàng'  WHERE MASACH = 'S0684';
UPDATE GIAMDOC_CN3.KHO_BAN@gd1_to_gd3 SET SOLUONGTON = 79, TRANGTHAI ='Còn hàng'  WHERE MASACH = 'S0684';

COMMIT;

-- Kiểm tra lại tồn kho 
SELECT 'CN1' AS CN, SOLUONGTON FROM GIAMDOC_CN1.KHO_BAN WHERE MASACH = 'S0684'
UNION ALL
SELECT 'CN2', SOLUONGTON FROM GIAMDOC_CN2.KHO_BAN@gd1_to_gd2 WHERE MASACH = 'S0684'
UNION ALL
SELECT 'CN3', SOLUONGTON FROM GIAMDOC_CN3.KHO_BAN@gd1_to_gd3 WHERE MASACH = 'S0684';


--Test case 1 - CN1 còn đủ hàng:
-- Yêu cầu 10, CN1 có 72 → CN1 tự xử lý
INSERT INTO GIAMDOC_CN1.HOADON VALUES ('HD001', 'KH0272', 'NV0001', CURRENT_TIMESTAMP, NULL);
INSERT INTO GIAMDOC_CN1.CHITIET_HD VALUES ('HD001', 'S0684', 10);
COMMIT;

--Test case 2 - CN1 không đủ, lấy từ CN2:
-- Yêu cầu 70, CN1 còn 62 → thiếu 8 → lấy từ CN2
INSERT INTO GIAMDOC_CN1.HOADON VALUES ('HD002', 'KH0272', 'NV0002', CURRENT_TIMESTAMP, NULL);
INSERT INTO GIAMDOC_CN1.CHITIET_HD VALUES ('HD002', 'S0684', 70);
COMMIT;

--Test case 3 - CN1 + CN2 không đủ, lấy từ CN3:
-- Yêu cầu 75 → lấy từ CN3
INSERT INTO GIAMDOC_CN1.HOADON VALUES ('HD003', 'KH0272', 'NV0003', CURRENT_TIMESTAMP, NULL);
INSERT INTO GIAMDOC_CN1.CHITIET_HD VALUES ('HD003', 'S0684', 75);
COMMIT;

--Test case 4 - Cả 3 không đủ → báo lỗi:
INSERT INTO GIAMDOC_CN1.HOADON VALUES ('HD004', 'KH0272', 'NV000', CURRENT_TIMESTAMP, NULL);
INSERT INTO GIAMDOC_CN1.CHITIET_HD VALUES ('HD004', 'S0684', 85);
COMMIT;

-- trigger
CREATE OR REPLACE TRIGGER CapNhatSoLuongSachTrongKho
AFTER INSERT ON GIAMDOC_CN1.CHITIET_HD
FOR EACH ROW
DECLARE
    v_masach              VARCHAR2(15);
    v_quantity_needed      NUMBER;
    v_remained_qty_cn1    NUMBER := 0;
    v_remained_qty_cn2    NUMBER := 0;
    v_remained_qty_cn3    NUMBER := 0;
    v_qty_taken_from_cn1  NUMBER := 0;
    v_qty_taken_from_cn2  NUMBER := 0;
    v_qty_taken_from_cn3  NUMBER := 0;
    v_qty_still_needed    NUMBER;
    DBLINK_TO_CN2 CONSTANT VARCHAR2(50) := '@gd1_to_gd2';
    DBLINK_TO_CN3 CONSTANT VARCHAR2(50) := '@gd1_to_gd3';
    v_sql_stmt VARCHAR2(1000);

BEGIN
    v_masach           := :NEW.MaSach;
    v_quantity_needed   := :NEW.SoLuong;
    v_qty_still_needed := v_quantity_needed;

    -- 1. Lấy số lượng còn lại trong kho chi nhánh 1 (local)
    BEGIN
        SELECT NVL(SoLuongTon, 0)
        INTO v_remained_qty_cn1
        FROM GIAMDOC_CN1.KHO_BAN
        WHERE MaSach = v_masach
          AND MaCN = 'CN001';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_remained_qty_cn1 := 0;
    END;

    -- 2. Xử lý kho CN1
    IF v_remained_qty_cn1 >= v_qty_still_needed THEN
        -- Trường hợp 1: Kho CN1 đủ hàng
        v_qty_taken_from_cn1 := v_qty_still_needed;
        v_qty_still_needed   := 0;

        UPDATE GIAMDOC_CN1.KHO_BAN
        SET SoLuongTon = SoLuongTon - v_qty_taken_from_cn1,
            TrangThai  = CASE
                             WHEN (SoLuongTon - v_qty_taken_from_cn1) > 0 THEN 'Còn hàng'
                             ELSE 'Hết hàng'
                         END
        WHERE MaSach = v_masach AND MaCN = 'CN001';
        DBMS_OUTPUT.PUT_LINE('Đã cập nhật kho CN1. Lấy: ' || v_qty_taken_from_cn1);

    ELSE
        -- Kho CN1 không đủ, lấy hết những gì CN1 có
        v_qty_taken_from_cn1 := v_remained_qty_cn1;
        v_qty_still_needed   := v_quantity_needed - v_qty_taken_from_cn1;

        IF v_qty_taken_from_cn1 > 0 THEN
            UPDATE GIAMDOC_CN1.KHO_BAN
            SET SoLuongTon = 0,
                TrangThai  = 'Hết hàng'
            WHERE MaSach = v_masach AND MaCN = 'CN001';
            DBMS_OUTPUT.PUT_LINE('CN1 không đủ. Lấy hết từ CN1: ' || v_qty_taken_from_cn1
                || '. Còn thiếu: ' || v_qty_still_needed);
        ELSE
            DBMS_OUTPUT.PUT_LINE('CN1 không có hàng. Còn thiếu: ' || v_qty_still_needed);
        END IF;

        -- 3. Xử lý kho CN2 (nếu vẫn còn thiếu)
        IF v_qty_still_needed > 0 THEN
            BEGIN
                v_sql_stmt := 'SELECT NVL(SoLuongTon, 0) FROM GIAMDOC_CN2.KHO_BAN' || DBLINK_TO_CN2
                    || ' WHERE MaSach = :1 AND MaCN = ''CN002'' FOR UPDATE';
                EXECUTE IMMEDIATE v_sql_stmt INTO v_remained_qty_cn2 USING v_masach;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_remained_qty_cn2 := 0;
            END;

            IF v_remained_qty_cn2 >= v_qty_still_needed THEN
                -- Kho CN2 đủ cho phần còn thiếu
                v_qty_taken_from_cn2 := v_qty_still_needed;
                v_qty_still_needed   := 0;

                v_sql_stmt := 'UPDATE GIAMDOC_CN2.KHO_BAN' || DBLINK_TO_CN2
                    || ' SET SoLuongTon = SoLuongTon - :1,'
                    || '     TrangThai  = CASE WHEN (SoLuongTon - :2) > 0 THEN ''Còn hàng'' ELSE ''Hết hàng'' END'
                    || ' WHERE MaSach = :3 AND MaCN = ''CN002''';
                EXECUTE IMMEDIATE v_sql_stmt
                    USING v_qty_taken_from_cn2, v_qty_taken_from_cn2, v_masach;

                DBMS_OUTPUT.PUT_LINE('Đã cập nhật kho CN2. Lấy: ' || v_qty_taken_from_cn2);

            ELSE
                -- Kho CN2 không đủ, lấy hết những gì CN2 có
                v_qty_taken_from_cn2 := v_remained_qty_cn2;
                v_qty_still_needed   := v_qty_still_needed - v_qty_taken_from_cn2;

                IF v_qty_taken_from_cn2 > 0 THEN
                    v_sql_stmt := 'UPDATE GIAMDOC_CN2.KHO_BAN' || DBLINK_TO_CN2
                        || ' SET SoLuongTon = 0, TrangThai = ''Hết hàng'''
                        || ' WHERE MaSach = :1 AND MaCN = ''CN002''';
                    EXECUTE IMMEDIATE v_sql_stmt USING v_masach;

                    DBMS_OUTPUT.PUT_LINE('CN2 không đủ. Lấy hết từ CN2: ' || v_qty_taken_from_cn2
                        || '. Còn thiếu: ' || v_qty_still_needed);
                ELSE
                    DBMS_OUTPUT.PUT_LINE('CN2 không có hàng. Còn thiếu: ' || v_qty_still_needed);
                END IF;

                -- 4. Xử lý kho CN3 (nếu vẫn còn thiếu)
                IF v_qty_still_needed > 0 THEN
                    BEGIN
                        v_sql_stmt := 'SELECT NVL(SoLuongTon, 0) FROM GIAMDOC_CN3.KHO_BAN' || DBLINK_TO_CN3
                            || ' WHERE MaSach = :1 AND MaCN = ''CN003'' FOR UPDATE';
                        EXECUTE IMMEDIATE v_sql_stmt INTO v_remained_qty_cn3 USING v_masach;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_remained_qty_cn3 := 0;
                    END;

                    IF v_remained_qty_cn3 >= v_qty_still_needed THEN
                        -- Kho CN3 đủ cho phần còn thiếu cuối cùng
                        v_qty_taken_from_cn3 := v_qty_still_needed;
                        v_qty_still_needed   := 0;

                        v_sql_stmt := 'UPDATE GIAMDOC_CN3.KHO_BAN' || DBLINK_TO_CN3
                            || ' SET SoLuongTon = SoLuongTon - :1,'
                            || '     TrangThai  = CASE WHEN (SoLuongTon - :2) > 0 THEN ''Còn hàng'' ELSE ''Hết hàng'' END'
                            || ' WHERE MaSach = :3 AND MaCN = ''CN003''';
                        EXECUTE IMMEDIATE v_sql_stmt
                            USING v_qty_taken_from_cn3, v_qty_taken_from_cn3, v_masach;

                        DBMS_OUTPUT.PUT_LINE('Đã cập nhật kho CN3. Lấy: ' || v_qty_taken_from_cn3);

                    ELSE
                        -- Cả 3 kho cộng lại vẫn không đủ
                        RAISE_APPLICATION_ERROR(-20001,
                            'Không đủ sản phẩm ở cả 3 chi nhánh. Cần: ' || v_quantity_needed
                            || '. Có CN1=' || v_remained_qty_cn1
                            || ', CN2=' || v_remained_qty_cn2
                            || ', CN3=' || v_remained_qty_cn3
                            || '. Đã lấy CN1=' || v_qty_taken_from_cn1
                            || ', CN2=' || v_qty_taken_from_cn2);
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Sản phẩm (MaSach: ' || v_masach || ') không tồn tại trong kho chi nhánh 1.');
    WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE ('Lỗi trong trigger CapNhatSoLuongSachTrongKho:' || SQLERRM);
           RAISE;
END;
/

drop trigger CAPNHATSOLUONGSACHTRONGKHO
