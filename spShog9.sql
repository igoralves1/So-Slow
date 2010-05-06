USE [StackOverflow]
GO
/****** Object:  StoredProcedure [dbo].[spShog9]    Script Date: 05/06/2010 16:29:30 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
ALTER proc [dbo].[spShog9]   
as   
set nocount on   
  
create table #results (row varchar(max), id int)  
declare @currentCol varchar(100)   
declare @AvgLength int   
declare @MaxLength int   
declare @colNames varchar(max)   
  
set @colNames = '<h3>'  
  
select identity(int,1,1) as row__id, * into #tt from #t  
  
select name, AvgLength = 0, MaxLength = 0   
into #cols   
from tempdb.dbo.syscolumns where id = OBJECT_ID('tempdb.dbo.#t')  
order by colorder  
  
-- lazy sam   
select * into #copy from #cols  
  
while exists (select top 1 1 from #copy)  
begin  
 select top 1 @currentCol = name from #copy   
 delete from #copy where name = @currentCol   
 exec ('update #cols   
  set   
   AvgLength = (select AVG(len(cast([' + @currentCol +  '] as varchar(1000)))) from #t),   
   MaxLength = (select 1 + MAX(len(cast([' + @currentCol +  '] as varchar(1000)))) from #t) where name = ''' + @currentCol + '''  
  ')  
end  
drop table #copy  
  
insert #results  
select '', row__id from #tt   
  
if exists (select top 1 1 from #cols where name = 'PostId')  
begin  
 if exists (select top 1 1 from #cols where name = 'PostText')  
 begin  
  select @MaxLength = MaxLength from #cols where name = 'PostText'  
  if @MaxLength > 40
	set @MaxLength = 40
    
  update r set row = '<a href="http://stackoverflow.com/questions/' + cast(PostId as varchar(max)) + '">' +    
   case when len(PostText) = 0 then 'unknown' else left(PostText, 40) end  +   
   '</a> ' + REPLICATE(' ', @MaxLength - LEN(case when len(PostText) > 40 then '----- ----- ----- ----- ----- ----- ----' else PostText end))  
  from #results r   
  join #tt t on r.id = t.row__id  
   
  set @colNames = @colNames + 'Post' + REPLICATE('&nbsp;', @MaxLength - 4)   
   
  delete from #cols where name in ('PostId','PostText')  
 end   
end  

  
if exists (select top 1 1 from #cols where name = 'UserId')  
begin  
 if exists (select top 1 1 from #cols where name = 'UserName')  
 begin  
  select @MaxLength = MaxLength from #cols where name = 'UserName'  
    
  update r set row = '<a href="http://stackoverflow.com/users/' + cast(UserId as varchar(max)) + '">' +    
   case when len(UserName) = 0 then 'unknown' else UserName end  +   
   '</a>' + REPLICATE(' ', @MaxLength - LEN(case when len(UserName) = 0 then 'unknown' else UserName end))  
  from #results r   
  join #tt t on r.id = t.row__id  
   
  set @colNames = @colNames + 'User' + REPLICATE('&nbsp;', @MaxLength - 4)   
   
  delete from #cols where name in ('UserName','UserId')  
 end   
end  
  
declare @sql nvarchar(max)  
   
while exists (select top 1 1 from #cols)  
begin  
 select top 1 @currentCol = name, @MaxLength = MaxLength from #cols   
 delete from #cols where name = @currentCol   
   
   
 if (@MaxLength < LEN(@currentCol))   
  SET @MaxLength = Len(@currentCol) + 1  
   
 set @sql =   
 N'update r   
 set row = row + CAST([' + @currentCol +'] as varchar(max)) +   
  REPLICATE('' '', ' + cast(@MaxLength as varchar(max)) + ' - LEN(CAST([' + @currentCol + '] as varchar(max))))  
 from #results r   
 join #tt t on r.id = t.row__id'  
   
 exec sp_executesql @sql, N''  
 set @colNames = @colNames + @currentCol + isnull(REPLICATE('&nbsp;', @MaxLength - LEN(@currentCol)), ' ')   
end   
  
  
  
drop table #cols  
drop table #tt  
set nocount off  
  
select row = @colNames + '</h3>'
union all
select '<pre>'  
union all   
select row from #results  
union all 
select '</pre>'
  
set nocount on  
drop table #results  
  