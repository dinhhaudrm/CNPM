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
--Thêm nhân viên--
create proc ThemNV
	@MaNV varchar(100),
	@HoTen nvarchar(100),
	@NgaySinh date,
	@Phai nvarchar(10),
	@SDT varchar(11),
	@DiaChi nvarchar(100),
	@MaHopDong varchar(100),
	@Pass varbinary(max),
	@ChucVu varchar(10)
as
begin
	declare @defaultPass varbinary(max)=  hashbytes('SHA2_512', '1000.'+@Pass)
		insert into NhanVien
		values (@MaNV,@HoTen,@NgaySinh,@Phai,@SDT,@DiaChi,@MaHopDong)

		insert into TaiKhoan
		values (@MaNV,@defaultPass,@ChucVu)
end
go
--Tìm nhân viên (gồm mã và tên nhân viên --
create function TimNV(@MaNV varchar(100),@HoTen nvarchar(100))
returns table
as
return (select * from NhanVien where MaNV like ('%'+ @MaNV +'%')  and HoTen like ( '%'+ @HoTen +'%') )
go
-- Lưu lại giờ vào  ca --
create proc KiemTra @MaNV varchar(100), @Ngay date, @KT time,@NgayLam date,@Tre time
as
begin
	declare @KTLoai time =
	(
		select GioVao from ChiTietChamCong where MaNV=@MaNV and day(Ngay)=day(@NgayLam) and YEAR(Ngay)=YEAR(@NgayLam) and MONTH(Ngay)=MONTH(@NgayLam)
	)
	if @KTLoai is null
	begin
		update ChiTietChamCong
		set MaNV=@MaNV,
		Ngay=@Ngay,
		GioVao=@KT,
		Tre=@Tre
	end
end
go