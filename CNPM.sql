---Test GitHub------
create database CNPM
go
use CNPM
go

--------------------------Table------------------------------
create table HopDong
(
	MaHD varchar(100),
	MaNV varchar(100),
	NgayKi date,
	ThoiHan varchar(100),
	constraint PK_HopDong primary key(MaHD,MaNV)
)
go
create table NhanVien
(
	MaNV varchar(100) primary key,
	HoTen nvarchar(100),
	NgaySinh date,
	Phai nvarchar(10),
	SDT varchar(11),
	DiaChi nvarchar(100),
	MaHopDong varchar(100)
)
go
alter table HopDong add constraint FK_HopDong foreign key (MaNV) references NhanVien(MaNV)
go
alter table NhanVien add constraint FK_NhanVien foreign key(MaHopDong,MaNV) references HopDong(MaHD,MaNV)
go
create table TaiKhoan
(
	MaNV varchar(100),
	Pass varbinary(max),
	ChucVu varchar(10),

	constraint PK_TaiKhoan primary key(MaNV),
	constraint FK_TaiKhoanNhanVien foreign key (MaNV) references NhanVien(MaNV)
)
go
create table ChamCong
(
	MaNV varchar(100),
	NgayThang date,
	Tre decimal,

	constraint PK_ChamCong primary key (MaNV,NgayThang),
	constraint FK_ChamCongNhanVien foreign key (MaNV) references NhanVien(MaNV)
)
go
create table ChiTietChamCong
(
	MaNV varchar(100),
	Ngay date,
	GioVao time,	--giờ vào ca
	Tre decimal,

	constraint PK_ChiTietChamCong primary key(MaNV,Ngay),
	constraint FK_ChiTietChamCong foreign key (MaNV) references NhanVien(MaNV)
)
go
create table DuAn
(
	MaDA varchar(100) primary key,
	TenDA nvarchar(100),
	TienDo varchar(20)
)
go
create table PhanCong
(
	MaDA varchar(100),
	MaNV varchar(100),
	HoaHong decimal,
	VaiTro nvarchar(100),

	constraint FK_PhanCong1 foreign key (MaDA) references DuAn(MaDA),
	constraint FK_PhanCong2 foreign key (MaNV) references NhanVien(MaNV),
	constraint PK_PhanCong primary key (MaDA,MaNV)
)
go
create table BangLuong
(
	MaNV varchar(100),
	Thang date,
	HoaHong decimal,
	TamUng decimal,
	TienPhat decimal,
	Tong decimal,

	constraint FK_BangLuong foreign key (MaNV) references NhanVien(MaNV),
	Check(TamUng<=Tong/2),
	constraint PK_BangLuong primary key (MaNV,Thang)
)
go
--suathongtinnhanvien
create proc SuaNhanVien
@MaNV varchar(100), @HoTen nvarchar(100), @NgaySinh date, @Phai nvarchar(10),
@SDT varchar(11), @DiaChi nvarchar(100), @MaHopDong varchar(100)
as
begin
	update NhanVien set HoTen=@HoTen, NgaySinh=@NgaySinh, Phai=@Phai, SDT=@SDT, DiaChi=@DiaChi, MaHopDong=@MaHopDong where MaNV=@MaNV
end
go
--xoanhanvien
create proc XoaNhanVien
@MaNV varchar(100), @HoTen nvarchar(100), @NgaySinh date, @Phai nvarchar(10),
@SDT varchar(11), @DiaChi nvarchar(100), @MaHopDong varchar(100)
as
begin
	delete NhanVien where HoTen=@HoTen and NgaySinh=@NgaySinh and Phai=@Phai and SDT=@SDT and DiaChi=@DiaChi and MaHopDong=@MaHopDong
end
go
--IDTD
--create function IDTD(@IDCuoi varchar(100), @TienTo varchar(20), @SL int)
--returns varchar(100)
--as
--begin
--	if (@IDCuoi='')
--	set @IDCuoi = @TienTo + REPLICATE (0, @SL - LEN(@TienTo))
--		--replicate:Lặp lại một giá trị chuỗi một số lần chỉ định.
--		--len:Trả về số lượng ký tự của biểu thức chuỗi đã chỉ định, không bao gồm dấu cách.
--	declare @SLNextID int, @NextID varchar(100)
--	set @IDCuoi =LTRIM(RTRIM(@IDCuoi))cái ID
--		--ltrim:Trả về một biểu thức ký tự sau khi nó loại bỏ khoảng trống hàng đầu.
--		--rtrim:Trả về một chuỗi ký tự sau khi cắt tất cả các dấu cách.
--	set @SLNextID = REPLACE( @IDCuoi,@TienTo,'') + 1
--	--replace:thay thế tất cả các lần xuất hiện của chuỗi con a thành chuỗi con b mới trong một chuỗi cho trước.
--	set @SL = @SL-LEN(@TienTo)
--	set @NextID = @TienTo+REPLICATE(0,@SL-LEN(@TienTo))
--	set @NextID = @TienTo+RIGHT(REPLICATE( 0, @SL) + CONVERT(varchar(MAX), @SLNextID) ,@SL)
--	return @NextID
--end
--go
--create trigger SINHID on NhanVien


