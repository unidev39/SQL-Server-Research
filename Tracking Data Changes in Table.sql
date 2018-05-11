
-- Trigger to Track the data changes of the tables and maintaining the changed data in another table.

--First Create table Audit to store the changed data values.

CREATE TABLE [dbo].[Audit](
	[AuditID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Type] [char](1) NULL,
	[TableName] [varchar](128) NULL,
	[PrimaryKeyField] [varchar](1000) NULL,
	[PrimaryKeyValue] [varchar](1000) NULL,
	[FieldName] [varchar](128) NULL,
	[OldValue] [varchar](1000) NULL,
	[NewValue] [varchar](1000) NULL,
	[UpdateDate] [datetime] NULL,
	[UserName] [varchar](128) NULL,
	[UpdatedBy] [uniqueidentifier] NULL,
	[SpName] [varchar](200) NULL,
	[ApplicationName] [varchar](200) NULL,
	[Sql] [varchar](4000) NULL,
 CONSTRAINT [PK_Audit] PRIMARY KEY CLUSTERED 
(
	[AuditID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Audit] ADD  DEFAULT (getdate()) FOR [UpdateDate]
GO


--Trigger Tracking the data changes.

Create trigger [dbo].[Customer_ChangeTracking] on [dbo].[Customer] 
for insert, update, delete
as
declare @bit int ,
@field int ,
@maxfield int ,
@char int ,
@fieldname varchar(128) ,
@TableName varchar(128) ,
@PKCols varchar(1000) ,
@sql varchar(2000), 
@UpdateDate varchar(21) ,
@UserName varchar(128) ,
@UpdatedBy [uniqueidentifier],
@Type char(1) ,
@PKFieldSelect varchar(1000),
@PKValueSelect varchar(1000)


select @TableName = 'Customer'

set nocount on 
-- date and user
select @UserName = system_user ,
@UpdateDate = convert(varchar(8), getdate(), 112) + ' ' + convert(varchar(12), getdate(), 114)

-- Action
if exists (select  from inserted)
if exists (select  from deleted)
select @Type = 'U'
else
select @Type = 'I'
else
select @Type = 'D'

-- get list of columns
select  into #ins from inserted
select  into #del from deleted
select   from #ins;
select   from #del;

-- Get primary key columns for full outer join
select @PKCols = coalesce(@PKCols + ' and', ' on') + ' i.' + c.COLUMN_NAME + ' = d.' + c.COLUMN_NAME
from INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
where pk.TABLE_NAME = @TableName
and CONSTRAINT_TYPE = 'PRIMARY KEY'
and c.TABLE_NAME = pk.TABLE_NAME
and c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

-- Get primary key fields select for insert
select @PKFieldSelect = coalesce(@PKFieldSelect+'+','') + '''' + COLUMN_NAME + '''' 
from INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,
INFORMATION_SCHEMA.KEY_COLUMN_USAGE c
where pk.TABLE_NAME = @TableName
and CONSTRAINT_TYPE = 'PRIMARY KEY'
and c.TABLE_NAME = pk.TABLE_NAME
and c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME

select @PKValueSelect = coalesce(@PKValueSelect+'+','') + 'convert(varchar(100), coalesce(i.' + COLUMN_NAME + ',d.' + COLUMN_NAME + '))'
from INFORMATION_SCHEMA.TABLE_CONSTRAINTS pk ,    
INFORMATION_SCHEMA.KEY_COLUMN_USAGE c   
where  pk.TABLE_NAME = @TableName   
and CONSTRAINT_TYPE = 'PRIMARY KEY'   
and c.TABLE_NAME = pk.TABLE_NAME   
and c.CONSTRAINT_NAME = pk.CONSTRAINT_NAME 

if @PKCols is null
begin
raiserror('no PK on table %s', 16, -1, @TableName)
return
end

select @field = 0, @maxfield = max(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName
while @field < @maxfield
begin
select @field = min(ORDINAL_POSITION) from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION > @field
begin
select @fieldname = COLUMN_NAME from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = @TableName and ORDINAL_POSITION = @field
select @sql = 'insert into [Audit] (Type, TableName, PrimaryKeyField, PrimaryKeyValue, FieldName, OldValue, NewValue, UpdateDate,UpdatedBy, UserName)'
select @sql = @sql + ' select ''' + @Type + ''''
select @sql = @sql + ',''' + @TableName + ''''
select @sql = @sql + ',' + @PKFieldSelect
select @sql = @sql + ',' + @PKValueSelect
select @sql = @sql + ',''' + @fieldname + ''''
select @sql = @sql + ',convert(varchar(1000),d.' + @fieldname + ')'
select @sql = @sql + ',convert(varchar(1000),i.' + @fieldname + ')'
select @sql = @sql + ',''' + @UpdateDate + ''''
select @sql = @sql + ',convert(varchar(1000), i.ModifiedById )'
select @sql = @sql + ',''' + @UserName +''''
select @sql = @sql + ' from #ins i full outer join #del d'
select @sql = @sql + @PKCols
select @sql = @sql + ' where i.' + @fieldname + ' <> d.' + @fieldname 
select @sql = @sql + ' or (i.' + @fieldname + ' is null and  d.' + @fieldname + ' is not null)' 
select @sql = @sql + ' or (i.' + @fieldname + ' is not null and  d.' + @fieldname + ' is null)' 
exec (@sql);
end
end
alter table Customer enable trigger [Customer_ChangeTracking]
