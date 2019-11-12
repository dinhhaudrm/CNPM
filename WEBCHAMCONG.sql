
--Table
create database PMCC
go

use PMCC
go
create table Employee
(
	id varchar(100) primary key,
	email nvarchar(100),
	name nvarchar(100),
	sex varchar(10),
	birthdate date,
	phone varchar(10),
	address nvarchar(100),
	position nvarchar(50),	--1: nhân viên; 2: quản lý
	BasicSalary real,
	attitude nvarchar(100)		--Còn làm và Đã thôi việc
)
go

create table Account
(
	id varchar(100),
	password varbinary(max),
	NetworkIp nvarchar(100),	--kiểm tra nơi chấm công của nhân viên
	constraint FK_Account foreign key (id) references Employee(id),
	constraint PK_Account primary key (id)
)
go
create table Time_Keeper
(
	id varchar(100),
	CheckIn time,
	CheckOut time,
	dateWork date,
	totalTime real,
	notePerShift nvarchar(max), --ghi chú trong ca nếu có
	attitude varchar(100), --Tình trạng là đã duyệt hay chưa duyệt

	constraint FK_TimeKeeper foreign key (id) references Employee(id),
	constraint PK_TimeKeeper primary key (id,dateWork)
)
go


create table Shift
(
	ShiftId varchar(50),
	shiftTime nvarchar(20),
	shiftName varchar(100), --S,S1,C,C1,...

	constraint PK_Shift primary key(ShiftId,shiftName)
)
go

create table ShiftPerWeek --Lịch làm việc một tuần
(
	EmpId varchar(100),
	ShiftId varchar(50),
	ShiftName varchar(100),
	day date,
	
	constraint FK_ShiftPerWeek foreign key (EmpId) references Employee(id),
	constraint FK_ShiftPerWeek1 foreign key (ShiftId,ShiftName) references Shift(ShiftId,shiftName),
	constraint PK_ShiftPerWeek primary key(EmpId,ShiftId,ShiftName,day)
)
go

--------------------------------FUNCTION---------------------------

create function GetName(@id varchar(100))
returns nvarchar(100)
as
begin
	declare @name nvarchar(100)=
	(
		select name from Employee where id=@id
	)
	return @name
end
go
create function GetContact(@id varchar(100))
returns nvarchar(100)
as
begin
	declare @phone nvarchar(100)=
	(
		select phone from Employee where id=@id
	)
	return @phone
end
go
create function GetEmail(@id varchar(100))
returns nvarchar(100)
as
begin
	declare @mail nvarchar(100)=
	(
		select email from Employee where id=@id
	)
	return @mail
end
go

create function LoadData()
returns table
as
return select id as ID, name as Name, birthdate as Birthday,sex as Sex,phone as Contact, position as Position, address as Address,email as Email from Employee
go 
create function IsLogin(@id varchar(100),@password nvarchar(max))
returns int
as
begin
	declare @isLogin int
	declare @hashPass varbinary(max)=hashbytes('SHA2_512', '1000.'+@password)
	declare @temp nvarchar(max)=
	(
		select password from Account,Employee where @id=Employee.id and Employee.attitude=N'Còn làm' and @id=Account.id and @hashPass=password
	)

	if @temp is null
		set @isLogin=0
	else
		set @isLogin=1
	return @isLogin
end
go

create function AutoId() returns int --Dung de sinh so thu tu ID tu dong
as
begin
	declare @maxID varchar(100) =
	(
		select max(id) from Employee
	)
	declare @rs int
	if @maxID is null
		set @rs=1
	else
		set @rs=cast(substring(@maxID,4,9) as int) + 1
	return @rs
end
go
--2/ viết 1 function tìm nhân viên bằng ID hoặc tên (1 function làm được cả 2 cách tìm) 

create function checkNV(@id varchar(100),@name nvarchar(100))
returns table
as
return (select * from Employee where id like ('%'+ @id +'%')  and name like ( '%'+ @name +'%') )
go
----5/ viết function tính tổng giờ công/tháng theo mã nhân viên. Gợi ý: sử dụng lại bảng Time_Keeper với thuộc tính dateWork và totalTime
create function TotalTime(@id varchar(100),@month date)
returns decimal
as
begin
declare @tonggio real=
(
select sum(totalTime) from Time_Keeper where id=@id and month(dateWork)=month(@month)
)
return @tonggio
end
go
--6/ viết function tính lương (lương=tổng giờ công/tháng *18000 - tiền thưởng)
create function luong(@id varchar(100), @month date)
returns decimal
as
begin
declare @luong real =
(
  select sum(totalTime) from Time_Keeper where id=@id and month(dateWork)=month(@month)
)
return @luong*18000+200000
end
go

--select * from Time_Keeper where
go
create function AttitudeCheck(@EmpId varchar(100), @dayWork date)
returns int
as
begin
	declare @rs int
	declare @attitude varchar(100)=
	(
		select attitude from Time_Keeper where id=@EmpId and day(dateWork)=day(@dayWork) and YEAR(dateWork)=YEAR(@dayWork) and MONTH(dateWork)=MONTH(@dayWork)
	)
	if @attitude =N'Đã duyệt'
		set @rs=0
	else
	begin
		declare @Checkin time=
		(
			select CheckIn from Time_Keeper where id=@EmpId and day(dateWork)=day(@dayWork) and YEAR(dateWork)=YEAR(@dayWork) and MONTH(dateWork)=MONTH(@dayWork)
		)
		if @Checkin is null
			set @rs=1
		else
			set @rs=-1
	end
	return @rs
end
go
create function CreateID() returns varchar(100)
as
begin
declare @maxadded int =(select dbo.AutoId())
	declare @userid varchar(100)
	if @maxadded<10
		set @userid ='TCH000'+ (select cast(dbo.AutoId()as varchar(100)))
	else
	begin
		if @maxadded>=10 and @maxadded<100 --tch0099 tch1000
		begin
			set @userid ='TCH00'+ (select cast(dbo.AutoId()as varchar(100)))
		end
		else
		begin
			if @maxadded>=100 and @maxadded<1000
			begin
				set @userid ='TCH0'+ (select cast(dbo.AutoId()as varchar(100)))
			end
			else
				set @userid ='TCH'+ (select cast(dbo.AutoId()as varchar(100)))
		end
	end
	return @userid
end
go
-----------------------------------PROCEDURE------------------------------
create proc AddEmp @password nvarchar(max),@email nvarchar(100),@name nvarchar(100),@sex varchar(10),@birthdate date,
@phone varchar(10),@address nvarchar(100),@position nvarchar(50),@salary real,@networkIP nvarchar(100)
as
begin
	declare @userid varchar(100)=(select dbo.CreateID())
	declare @defaultPassword varbinary(max)=  hashbytes('SHA2_512', '1000.'+@password) --băm mật khẩu ra kiểu byte
	--if (@phone=Any(select phone from Emp))
	--begin
	--	print N'Lỗi vui lòng kiểm tra lại thông tin!'
	--	rollback tran
	--end
	--else
	--begin
		insert into Employee
		values (@userid,@email,@name,@sex,@birthdate,@phone,@address,@position,@salary,N'Còn làm')

		insert into Account
		values (@userid,@defaultPassword,@networkIP)
	--end
end
go
--declare @h varbinary(max)=  hashbytes('SHA2_512', '1')
----select @h
go
create proc UpdateEmpinfo_Basic @EmpId varchar(100),@name nvarchar(100), @email nvarchar(100),@phone varchar(10)
as
begin
	Update Employee
	set
	name=@name,
	email=@email,
	phone=@phone
	where id=@EmpId
end
go

create proc UpdateEmpInfo @EmpId varchar(100),@name nvarchar(100), @email nvarchar(100),@sex varchar(10),@birthdate date,@phone varchar(10),@address nvarchar (100)
,@position nvarchar(50),@BasicSalary real,@attitude nvarchar(100)	--THIEU THONG SO DU LIEU TRUYEN VAO
as
begin
	update Employee
	set Employee.email=@email,
	Employee.name=@name, 
	Employee.sex= @sex,
	Employee.birthdate=@birthdate,
	Employee.phone=@phone,
	Employee.address=@address,
	Employee.position=@position,
	Employee.BasicSalary=@BasicSalary,
	Employee.attitude=@attitude
	where id=@EmpId
end
go

create proc DeleteEmp @EmpId varchar(100)
as
begin
	update Employee
	set Employee.attitude=N'Đã thôi việc'
	where Employee.id=@EmpId
end
go
--3/ viết proc duyệt công (update thuộc tính attitude trong Time_Keeper)
create proc ConfirmShift @EmpId varchar(100),@totalTime real,@dayWork date --Duyệt công theo ngày
as
begin
	update Time_Keeper
	set attitude=N'Đã duyệt' ------------------------------Bổ sung thêm tổng giờ-----------------------------
	where id=@EmpId and day(dateWork)=day(@dayWork) and YEAR(dateWork)=YEAR(@dayWork) and MONTH(dateWork)=MONTH(@dayWork)
end
go
--4/ viết proc chấm công (lưu lại thời gian vào/ra ca)

create proc CheckShift @EmpId varchar(100), @dayWork date,@CheckTime time,@note nvarchar(max) --@CheckType la loai cham cong ra hay cham cong vao
as
begin
	declare @CheckType time =
	(
		select CheckIn from Time_Keeper where id=@EmpId and day(dateWork)=day(@dayWork) and YEAR(dateWork)=YEAR(@dayWork) and MONTH(dateWork)=MONTH(@dayWork)
	)
	if @CheckType is null --chua checkIn
	begin
		update Time_Keeper
		set id=@EmpId,
		dateWork=@dayWork,
		CheckIn=@CheckTime,
		attitude=N'Chưa duyệt',
		notePerShift=@note
	end
	else --CheckType is not null
	begin
		declare @CheckOut time=
		(
			select CheckOut from Time_Keeper where id=@EmpId and day(dateWork)=day(@dayWork) and YEAR(dateWork)=YEAR(@dayWork) and MONTH(dateWork)=MONTH(@dayWork)
		)
		if @CheckOut is null
		begin
			update Time_Keeper
			set CheckOut=@CheckTime
			where id=@EmpId				
		end
		else
		begin
			print '0' --Loi
		end
	end
end
go
create proc UpdatePassword(@id varchar(100), @password nvarchar(max))
as
begin
	update Account
	set password=hashbytes('SHA2_512', '1000.'+@password)
	where id=@id
end
go
-------------------------------------View-----------------------------------

-------------------------------------TEST CODE-------------------------------------
declare @n int=1
while @n<=500
begin
	declare @b int =rand(2)
	exec AddEmp '1','duongcokhanh17110315@gmail.com',N'Dương Cơ Khánh','Male','2/3/1999',023,sg,'Admin',10000000,'192.168.1.1'
	set @n=@n+1
end
--select dbo.GetEmail('TCH0001')
--select id,password from Account
select dbo.CreateID()
--select id,password from Account where id='TCH1001'
--select dbo.IsLogin('TCH0051','cokhanh')
--exec DeleteEmp 'TCH0050'
------------------------------------To Do Task--------------------------------
--1/ sửa lại proc UpdateEmpInfo 
--2/ viết 1 function tìm nhân viên bằng ID hoặc tên (1 function làm được cả 2 cách tìm)
--3/ viết proc duyệt công (update thuộc tính attitude trong Time_Keeper)
--4/ viết proc chấm công (lưu lại thời gian vào/ra ca)
--5/ viết function tính tổng giờ công/tháng theo mã nhân viên. Gợi ý: sử dụng lại bảng Time_Keeper với thuộc tính dateWork và totalTime
--6/ viết function tính lương (lương=tổng giờ công/tháng *18000 - tiền thưởng)
--	Cách trừ giờ công đi trễ:
--	vd: ca 7h-12h thì tổng giờ công là 5
--	trễ 5': trừ 0.5
--	trễ 10': trừ 1
--	trễ >15': tổng giờ công còn 0
--	Cách tính tiền thưởng:
--		15 < Số ngày làm < 20: thưởng = 100000
--		20 <= Số ngày làm: thưởng = 200000
